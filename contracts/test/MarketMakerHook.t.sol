// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {MarketMakerHook} from "../src/AggregatorHook.sol";
import {MarketMakerHookImplementation} from "./shared/implementation/MarketMakerImplementation.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {MockERC20} from "@uniswap/v4-core/test/foundry-tests/utils/MockERC20.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {UniswapV4ERC20} from "../contracts/libraries/UniswapV4ERC20.sol";
import {FullMath} from "@uniswap/v4-core/contracts/libraries/FullMath.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {SafeCast} from "@uniswap/v4-core/contracts/libraries/SafeCast.sol";

contract TestMarketMakerHook is Test, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using SafeCast for uint256;
    using CurrencyLibrary for Currency;

    event Initialize(
        PoolId indexed poolId,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        IHooks hooks
    );
    event ModifyPosition(
        PoolId indexed poolId, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta
    );
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    /// @dev Min tick for full range with tick spacing of 60
    int24 internal constant MIN_TICK = -887220;
    /// @dev Max tick for full range with tick spacing of 60
    int24 internal constant MAX_TICK = -MIN_TICK;

    int24 constant TICK_SPACING = 1; 
    uint16 constant LOCKED_LIQUIDITY = 1000;
    uint256 constant MAX_DEADLINE = 12329839823;
    uint256 constant MAX_TICK_LIQUIDITY = 11505069308564788430434325881101412;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint8 constant DUST = 30;

    uint160 public constant SQRT_RATIO_2_1 = 112045541949572279837463876454;

    MockERC20 token0;
    MockERC20 token1;
    MockERC20 token2;

    Currency currency0;
    Currency currency1;

    PoolManager manager;

    MarketMakerHookImplementation marketMakerHook = MarketMakerHookImplementation(
        address(uint160(Hooks.BEFORE_MODIFY_POSITION_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG))
    );

    PoolKey key;
    PoolId id;

    PoolKey key2;
    PoolId id2;

    PoolModifyPositionTest modifyPositionRouter;
    PoolSwapTest swapRouter;

    function setUp() public {
        token0 = new MockERC20("TestA", "A", 18, 2 ** 128);
        token1 = new MockERC20("TestB", "B", 18, 2 ** 128);
        token2 = new MockERC20("TestC", "C", 18, 2 ** 128);

        manager = new PoolManager(500000);

        MarketMakerHookImplementation impl = new MarketMakerHookImplementation(manager, aggregatorHook);
        vm.etch(address(marketMakerHook), address(impl).code);

        key = createPoolKey(token0, token1);
        id = key.toId();

        key2 = createPoolKey(token1, token2);
        id2 = key.toId();

        modifyPositionRouter = new PoolModifyPositionTest(manager);
        swapRouter = new PoolSwapTest(manager);

        token0.approve(address(aggregatorHook), type(uint256).max);
        token1.approve(address(aggregatorHook), type(uint256).max);
        token2.approve(address(aggregatorHook), type(uint256).max);
        token0.approve(address(swapRouter), type(uint256).max);
        token1.approve(address(swapRouter), type(uint256).max);
        token2.approve(address(swapRouter), type(uint256).max);
    }


    function createPoolKey(MockERC20 tokenA, MockERC20 tokenB) internal view returns (PoolKey memory) {
        if (address(tokenA) > address(tokenB)) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey(Currency.wrap(address(tokenA)), Currency.wrap(address(tokenB)), 0 , TICK_SPACING, aggregatorHook); // todo if change fee?
    }

    function testHook_BeforeModifyPositionFailsWithWrongMsgSender() public {
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        vm.expectRevert(AggregatorHook.SenderMustBeHook.selector);
        modifyPositionRouter.modifyPosition(
            key, IPoolManager.ModifyPositionParams({tickLower: MIN_TICK, tickUpper: MAX_TICK, liquidityDelta: 100}), ZERO_BYTES
        );
    }

    function testHook_SwapFirstTime() public {
        PoolKey memory testKey = key;
        token0.mint(address(aggregatorHook), 1 ether);
        token1.mint(address(aggregatorHook), 1 ether);
        // price 1200

        bytes memory initData = abi.encode(address(token0), address(token1));
        manager.initialize(testKey, TickMath.getSqrtRatioAtTick(-46855+ 100), initData); // todo: 初始化价格如何确定

        token0.mint(address(aggregatorHook), 1000 ether);
        token1.mint(address(aggregatorHook), 1000 ether);

        // question state hook change is keep, however global variable, even setting constant is zero
        // but if call a write function, it will work
        aggregatorHook.setNewPrice(9213376791555881);
        (uint256 toAmount,,) = aggregatorHook.getMockAmountOut(1 ether, true);
        console.log(toAmount);

        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 1 ether, sqrtPriceLimitX96: MIN_SQRT_RATIO + 1});
        PoolSwapTest.TestSettings memory settings =
            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        snapStart("HookFirstSwap");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);
        snapEnd();

    }

    function testHook_SwapSecondTime() public {
        testHook_SwapFirstTime();
        PoolKey memory testKey = key;

        // sell token0 to token1, the second time
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 1 ether, sqrtPriceLimitX96: MIN_SQRT_RATIO + 1});
        PoolSwapTest.TestSettings memory settings =
            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        // notice could not use the same price, not single token deposit cause amount lack 
        // making price diff is too big.
        /*
        aggregatorHook.setNewPrice(9215376791555881); // price become higher , it didn't work, follow market rule

        snapStart("HookSecondSwap");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);
        snapEnd();
        // after this, the current tick is min_tick, you must trade another direction to make it balance
        // reflecting the situation that liquidity of token1 is used out. The pool can't sell token1 anymore
        // But after user sell token1 to this pool, it will rebalance to market price.
        */
        
        aggregatorHook.setNewPrice(92123767915559); // price become lower ,pass

        snapStart("HookFrom0to1Swap_second");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);
        snapEnd();      
    }

    function testHook_SwapFrom1to0() public {
        testHook_SwapFirstTime();
        PoolKey memory testKey = key;

        // sell token0 to token1, the second time
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: false, amountSpecified: 9214376791555881, sqrtPriceLimitX96: MAX_SQRT_RATIO - 1});
        PoolSwapTest.TestSettings memory settings =
            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        // notice could not use the same price, not single token deposit cause amount lack 
        // making price diff is too big.
        /*
        aggregatorHook.setNewPrice(9215376791555881); // price become higher , it didn't work, follow market rule

        snapStart("HookSecondSwap");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);
        snapEnd();
        // after this, the current tick is min_tick, you must trade another direction to make it balance
        // reflecting the situation that liquidity of token1 is used out. The pool can't sell token1 anymore
        // But after user sell token1 to this pool, it will rebalance to market price.
        */
        
        aggregatorHook.setNewPrice(9214376791555881); // price become lower ,pass

        snapStart("HookFrom1to0Swap_first");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);
        snapEnd();      

        console.log("\n======= next swap 1 to 0========");
        aggregatorHook.setNewPrice(9215676791555881); 
        // 9215376791555881, price in tick -46872,slot0 = -46872,so deposit both tokens, price difference is large 
        // price is 9215676791555881, tick from -46871, single side token deposit，success
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);


        // add more 0 - 1
         // sell token0 to token1, the second time
        params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 1 ether, sqrtPriceLimitX96: MIN_SQRT_RATIO + 1});
        settings =
            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        aggregatorHook.setNewPrice(9213076791555881); 
        // price become lower ,pass
        // 9213076791555881, the price fluctuation exceeds 50%, need tick adapt;
        // price is less than 50%, > 921322.
        // 9213376791555881, the price fluctuation in 50%，needn't tick adapt

        snapStart("HookFrom1to0Swap_second");
        swapRouter.swap(testKey, params, settings, ZERO_BYTES);  
        snapEnd(); 
    }
}
