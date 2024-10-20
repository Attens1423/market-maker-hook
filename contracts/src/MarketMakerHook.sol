// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseTestHooks} from "@uniswap/v4-core/src/test/BaseTestHooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IERC20Minimal} from "@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol";
import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {BaseHook} from "@uniswap/v4-periphery/src/base/hooks/BaseHook.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/Test.sol";

contract PriceTool {
    uint256 public mockPrice = 0;

    function setNewPrice(uint256 newPrice) public {
        mockPrice = newPrice;
    }

    function getMockPrice() public view returns(uint256 p) {
        p = mockPrice;
    }
}


contract MarketMakerHook is BaseHook, Test, PriceTool {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    //using FeeLibrary for uint24;

    error SenderMustBeHook();
    error SenderMustBePoolManager();
    error PriceDiffTooLarge();
    // used for single token deposit
    error TickCoverSlot0();
    error TradeDirectionError();

    bytes internal constant ZERO_BYTES = bytes("");
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    int24 public tickLower;
    int24 public tickUpper;
    
    int256 public targetAmount;

    // record deposited into uni
    // todo maybe not necessary
    mapping(address => uint256) public depositedInPoolManager; 

    struct CallbackData {
        address sender;
        PoolKey key;
        IPoolManager.ModifyLiquidityParams params;
    }

    //IPoolManager public immutable poolManager;

    modifier poolManagerOnly() {
        if (msg.sender != address(poolManager)) revert SenderMustBePoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) BaseHook(_poolManager){
        poolManager = _poolManager;
        Hooks.validateHookPermissions(IHooks(address(this)), getHookPermissions());
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Only for mocking
    function getMockAmountOut(
        uint256 fromAmount, 
        bool zeroForOne
    ) public returns(uint256 toAmount, int24 tickUp, int24 tickLow) {
        uint256 zeroForOneMockPrice = getMockPrice();
        toAmount = zeroForOne ? 
            fromAmount * zeroForOneMockPrice / 1e18 :
            fromAmount * 1e18 / zeroForOneMockPrice;
        
        targetAmount = int256(toAmount);
        // calculate accrute tick
        uint160 midPriceSqrtQ = uint160(FullMath.mulDiv(Math.sqrt(zeroForOneMockPrice), Q96, 10 ** 9));
        tickLow = TickMath.getTickAtSqrtPrice(midPriceSqrtQ);
        tickUp = tickLow + 1;
    }

    function removeRemainingLiquidity(PoolKey calldata key) public returns(bool){
        console.log("\n========= removeRemainingLiquidity ==========");
        PoolId poolId = key.toId();
        uint128 liquidity = StateLibrary.getLiquidity(poolManager, poolId);
        if(liquidity == 0) return true;

        _modifyPosition(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper, 
                liquidityDelta: -int128(liquidity),
                salt: bytes32(0)
            })
        );

        liquidity = StateLibrary.getLiquidity(poolManager, poolId);
        console.log();
        console.log("after remove liq:", liquidity);

        (, int24 tick,,) = StateLibrary.getSlot0(poolManager, poolId);
        console2.log("after remove tick:", tick);
        return true;
    }

    // ------------ IHook ----------------

    // prevent user fill liquidity
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external view override returns (bytes4) {
        if (sender != address(this)) revert SenderMustBeHook();

        return MarketMakerHook.beforeAddLiquidity.selector;
    }

    // Add liquidity into pool before swap
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        //address token0 = Currency.unwrap(key.currency0);
        //address token1 = Currency.unwrap(key.currency1);

        // before start, remove liquidity last time left
        removeRemainingLiquidity(key);
        console.log("\n========= beginSwap ==========");

        // begin new swap
        uint256 fromAmount = uint256(swapData.amountSpecified);// decode swapParam
        //bool zeroForOne = swapData.zeroForOne;
        uint256 toAmount;

        // query getAmountOut to generate fixed price
        (toAmount, tickUpper, tickLower) = getMockAmountOut(fromAmount, swapData.zeroForOne);

        (, int24 tick0,,) = StateLibrary.getSlot0(poolManager, poolId);
        if(!swapData.zeroForOne && tickLower <= tick0) revert TradeDirectionError();
        if(swapData.zeroForOne && tickUpper >= tick0) revert TradeDirectionError();
        
        {
        

        console.log();
        console.log("round tick by tickSpacing:");
        console2.log("tickLower", tickLower);
        console2.log("tickUpper", tickUpper);
        console2.log("slot0 tick:", tick0);
        }
        

        // if zeroForOne, tick go up, from tickUpper to tickLower
        // if not, tick go down, from tickLower to tickUpper
           
        uint128 liquidity;

        {
        int24 calTick = swapData.zeroForOne ? tickUpper : tickLower;   
        liquidity = _calJITLiquidity(calTick, fromAmount, toAmount, swapData.zeroForOne);
        // tick correct
        if(swapData.zeroForOne == false) {
            int24 limitTick = tickUpper;
            uint256 priceNext = fromAmount * Q96 / liquidity + TickMath.getSqrtPriceAtTick(calTick);
            uint256 priceLimit = uint256(TickMath.getSqrtPriceAtTick(limitTick));
            if(priceNext > priceLimit) {
                tickUpper = tickLower + 2;
            }       
        } else {
            int24 limitTick = tickLower ;
            uint256 sqrtPCal = uint256(TickMath.getSqrtPriceAtTick(calTick));
            uint256 priceNext = (liquidity * sqrtPCal) / (liquidity + sqrtPCal / Q96 * fromAmount);
            uint256 priceLimit = uint256(TickMath.getSqrtPriceAtTick(limitTick));
            if(priceNext > priceLimit) {
                tickLower --;
            }
        }
        }

        BalanceDelta delta = _modifyPosition(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int128(liquidity),
                salt: bytes32(0)
            })
        );

        depositedInPoolManager[Currency.unwrap(key.currency0)] = uint128(delta.amount0());
        depositedInPoolManager[Currency.unwrap(key.currency1)] = uint128(delta.amount1());

        return (MarketMakerHook.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    /// @notice since user transfer in after the whole swap in PoolSwapTest.sol, 
    /// actually it could not remove liquidty in afterSwap handle if filling liquidity
    /// accurately. So maybe it's no need to add afterSwap.
    /// In current condition, it only use to check price diff.
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4, int128) {
        PoolId poolId = key.toId();
        uint128 liquidity = StateLibrary.getLiquidity(poolManager, poolId);

        (, int24 tick,,) = StateLibrary.getSlot0(poolManager, poolId);

        //uint24 fee = key.fee.getStaticFee();
        console.log("\nafterSwap");
        console2.log("target amount:", targetAmount);
        console2.log("delta amount1:", delta.amount1());
        console2.log("delta amount0:", delta.amount0());
        console2.log("current tick:", tick);

        int256 priceDiff;

        if (delta.amount0() > 0 && delta.amount1() < 0) {
            priceDiff = int256(targetAmount + delta.amount1()) * 1e18 / targetAmount;
        }

        if (delta.amount0() < 0 && delta.amount1() > 0) {
            priceDiff = int256(targetAmount + delta.amount0()) * 1e18 / targetAmount;
        }   
        console2.log("price diff:", priceDiff);
        if(uint256(priceDiff >= 0 ? priceDiff : -priceDiff) > 1e12) revert PriceDiffTooLarge();

        
        uint128 tickliquidity = StateLibrary.getLiquidity(poolManager, poolId);
        console.log("all liquidity:", tickliquidity);
        
        return (MarketMakerHook.afterSwap.selector, 0);
    }

    // -------------- ILockCallback ----------------

    function lockAcquired(bytes calldata rawData)
        external
        selfOnly
        returns (bytes memory)
    {
        CallbackData memory data = abi.decode(rawData, (CallbackData));
        BalanceDelta delta;

        if (data.params.liquidityDelta <= 0) { //must contain 0
            (delta, ) = poolManager.modifyLiquidity(data.key, data.params, ZERO_BYTES);
            console.log("\ntake deltas");
            console2.log("delta amount0", delta.amount0());
            console2.log("delta amount1", delta.amount1());
            _takeDeltas(data.key, delta);
        } else {
            (delta, ) = poolManager.modifyLiquidity(data.key, data.params, ZERO_BYTES);
            console.log("\nsettle deltas");
            console2.log("delta amount0", delta.amount0());
            console2.log("delta amount1", delta.amount1());
            _settleDeltas(data.key, delta);
        }
        return abi.encode(delta);
    }

    // -------------- Internal Functions --------------

    function _calJITLiquidity(int24 curTick, uint256 fromAmount, uint256 toAmount, bool zeroForOne) internal view returns(uint128 liquidity) {
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(curTick);
        if(zeroForOne) {
            uint256 tmp1 = fromAmount * uint256(sqrtPriceX96) / Q96 *uint256(sqrtPriceX96) / Q96- toAmount;
            uint256 tmp2 = fromAmount * uint256(sqrtPriceX96) * toAmount / Q96;
            liquidity = uint128(tmp2 / tmp1);
        } else {
            uint256 tmp1 = fromAmount - toAmount * uint256(sqrtPriceX96) / Q96 * uint256(sqrtPriceX96) / Q96;
            uint256 tmp2 = fromAmount * uint256(sqrtPriceX96) * toAmount / Q96;
            liquidity = uint128(tmp2 / tmp1);
        }
    }

    function _modifyPosition(PoolKey memory key, IPoolManager.ModifyLiquidityParams memory params)
        internal
        returns (BalanceDelta delta)
    {
        delta = abi.decode(poolManager.unlock(abi.encode(CallbackData(msg.sender, key, params))), (BalanceDelta));
    }

    function _settleDeltas(PoolKey memory key, BalanceDelta delta) internal {
        _settleDelta(key.currency0, uint128(delta.amount0()));
        _settleDelta(key.currency1, uint128(delta.amount1()));
    }

    function _settleDelta(Currency currency, uint128 amount) internal {
        if (currency.isAddressZero()) {
            poolManager.sync(currency);
            poolManager.settle{value: amount}();
        } else {
            currency.transfer(address(poolManager), amount);
            poolManager.sync(currency);
            poolManager.settle();
        }
    }

    function _takeDeltas(PoolKey memory key, BalanceDelta delta) internal {
        uint256 amount0 = uint256(uint128(-delta.amount0()));
        uint256 amount1 = uint256(uint128(-delta.amount1()));
        poolManager.take(key.currency0, address(this), amount0);
        poolManager.take(key.currency1, address(this), amount1);
    }
}
