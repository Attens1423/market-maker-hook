// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MatchEngine {
    using SafeERC20 for IERC20;

    address public hookContract;

    struct MakerInfo {
        mapping(address => uint256) balances; // Balance for each token
        mapping(address => uint256) priceSlots; // Price slot for each token
    }

    struct PriceLevel {
        uint256 price;
        uint256 totalAmount;
        address[] makers;
    }

    struct OrderBook {
        mapping(uint256 => PriceLevel) levels;
        uint256[] prices;
    }

    // Mapping to store information for each maker
    mapping(address => MakerInfo) private makerInfos;

    // Mapping to store orderbooks for each token
    mapping(address => OrderBook) private sellOrderBooks;
    mapping(address => OrderBook) private buyOrderBooks;

    // Events
    event Deposit(address indexed maker, address token, uint256 amount);
    event Withdraw(address indexed maker, address token, uint256 amount);
    event SetPrice(address indexed maker, address token, uint256 priceSlot);
    event FillPrice(PoolId poolId, address indexed maker, address token, uint256 fromAmount, uint256 toAmount, bool isBuy);

    constructor(address _hookContract) {
        require(_hookContract != address(0), "Hook contract address cannot be zero");
        hookContract = _hookContract;
    }

    modifier onlyHook() {
        require(msg.sender == hookContract, "Caller is not the hook contract");
        _;
    }

    // Deposit function
    function deposit(address token, uint256 amount) public payable {
        uint256 depositAmount;

        if (token == address(0)) {
            // ETH deposit
            require(msg.value > 0, "ETH deposit amount must be greater than 0");
            depositAmount = msg.value;
        } else {
            // ERC20 token deposit
            require(amount > 0, "Token deposit amount must be greater than 0");
            require(msg.value == 0, "Should not send ETH when depositing ERC20");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            depositAmount = amount;
        }

        // Update maker's token balance
        makerInfos[msg.sender].balances[token] += depositAmount;
        
        // Emit Deposit event
        emit Deposit(msg.sender, token, depositAmount);
    }

    // Withdraw function
    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(makerInfos[msg.sender].balances[token] >= amount, "Insufficient balance");

        // Update maker's token balance
        makerInfos[msg.sender].balances[token] -= amount;

        if (token == address(0)) {
            // ETH withdrawal
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 token withdrawal
            IERC20(token).safeTransfer(msg.sender, amount);
        }

        // Emit Withdraw event
        emit Withdraw(msg.sender, token, amount);
    }

    // Set price function
    function setPrice(address token, uint256 priceSlot) external {
        uint256 oldPriceSlot = makerInfos[msg.sender].priceSlots[token];
        makerInfos[msg.sender].priceSlots[token] = priceSlot;

        // Update sell orderbook
        updateOrderBook(token, oldPriceSlot, priceSlot, true);

        // Update buy orderbook
        updateOrderBook(token, oldPriceSlot, priceSlot, false);

        emit SetPrice(msg.sender, token, priceSlot);
    }

    function updateOrderBook(address token, uint256 oldPriceSlot, uint256 newPriceSlot, bool isSell) private {
        OrderBook storage orderBook = isSell ? sellOrderBooks[token] : buyOrderBooks[token];
        
        uint256 oldPrice = isSell ? uint32(oldPriceSlot >> 32) : uint32(oldPriceSlot);
        uint256 newPrice = isSell ? uint32(newPriceSlot >> 32) : uint32(newPriceSlot);
        uint256 oldAmount = isSell ? uint64(oldPriceSlot >> 96) : uint64(newPriceSlot >> 128);
        uint256 newAmount = isSell ? uint64(newPriceSlot >> 96) : uint64(newPriceSlot >> 128);

        // Remove from old price level
        if (oldAmount > 0) {
            PriceLevel storage oldLevel = orderBook.levels[oldPrice];
            oldLevel.totalAmount -= oldAmount;
            if (oldLevel.totalAmount == 0) {
                // Remove price level if empty
                removePrice(orderBook.prices, oldPrice);
            }
        }

        // Add to new price level
        if (newAmount > 0) {
            PriceLevel storage newLevel = orderBook.levels[newPrice];
            if (newLevel.totalAmount == 0) {
                // Add new price level
                orderBook.prices.push(newPrice);
                sortPrices(orderBook.prices, isSell);
            }
            newLevel.totalAmount += newAmount;
            newLevel.makers.push(msg.sender);
        }
    }

    function removePrice(uint256[] storage prices, uint256 price) private {
        for (uint i = 0; i < prices.length; i++) {
            if (prices[i] == price) {
                prices[i] = prices[prices.length - 1];
                prices.pop();
                break;
            }
        }
    }

    function sortPrices(uint256[] storage prices, bool ascending) private {
        for (uint i = 0; i < prices.length; i++) {
            for (uint j = i + 1; j < prices.length; j++) {
                if ((ascending && prices[i] > prices[j]) || (!ascending && prices[i] < prices[j])) {
                    (prices[i], prices[j]) = (prices[j], prices[i]);
                }
            }
        }
    }

    struct PoolId {
        address fromToken;
        address toToken;
    }

    // Fill order function
    function fillOrder(PoolId calldata poolId, address fromToken, address toToken, uint256 fromAmount) external onlyHook {
        require(fromAmount > 0, "From amount must be greater than 0");

        bool isBuy = true;
        OrderBook storage orderBook = buyOrderBooks[toToken];

        uint256 remainingAmount = fromAmount;
        uint256 totalToAmount = 0;

        for (uint i = 0; i < orderBook.prices.length && remainingAmount > 0; i++) {
            uint256 price = orderBook.prices[i];
            PriceLevel storage level = orderBook.levels[price];

            for (uint j = 0; j < level.makers.length && remainingAmount > 0; j++) {
                address maker = level.makers[j];
                uint256 makerPriceSlot = makerInfos[maker].priceSlots[toToken];
                uint256 makerAmount = uint64(makerPriceSlot >> 128);
                uint256 makerPrice = uint32(makerPriceSlot);

                uint256 fillAmount = remainingAmount > makerAmount ? makerAmount : remainingAmount;
                uint256 toAmount = (fillAmount * makerPrice) / 1e18; // Assuming 18 decimal places for price

                // Update maker's balance
                makerInfos[maker].balances[fromToken] += fillAmount;
                makerInfos[maker].balances[toToken] -= toAmount;

                // Update remaining amount and total to amount
                remainingAmount -= fillAmount;
                totalToAmount += toAmount;

                // Emit FillPrice event
                emit FillPrice(poolId, maker, toToken, fillAmount, toAmount, isBuy);

                // Update orderbook
                level.totalAmount -= fillAmount;
                if (level.totalAmount == 0) {
                    removePrice(orderBook.prices, price);
                }
            }
        }

        require(remainingAmount == 0, "Insufficient liquidity to fill order");

        // Transfer tokens
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);
        IERC20(toToken).safeTransfer(msg.sender, totalToAmount);
    }

    // Example of a function that can only be called by the hook contract
    function exampleHookFunction() public onlyHook {
        // Function logic here
    }
}
