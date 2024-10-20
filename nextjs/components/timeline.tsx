import React, { useState } from "react";
import Image from "next/image";
import { Card } from "@/components/ui/card";
import { Timeline } from "@/components/ui/timeline";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { TypeAnimation } from "react-type-animation";

const quote_code_snippet = `uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(curTick);

if(zeroForOne) {
  uint256 tmp1 = fromAmount * uint256(sqrtPriceX96) / Q96 *uint256(sqrtPriceX96) / Q96- toAmount;
  uint256 tmp2 = fromAmount * uint256(sqrtPriceX96) * toAmount / Q96;
  liquidity = uint128(tmp2 / tmp1);
} else {
  uint256 tmp1 = fromAmount - toAmount * uint256(sqrtPriceX96) / Q96 * uint256(sqrtPriceX96) / Q96;
  uint256 tmp2 = fromAmount * uint256(sqrtPriceX96) * toAmount / Q96;
  liquidity = uint128(tmp2 / tmp1);
}
`;

const after_swap_code_snippet = `if (delta.amount0() > 0 && delta.amount1() < 0) {
  priceDiff = int256(targetAmount + delta.amount1()) * 1e18 / targetAmount;
}

if (delta.amount0() < 0 && delta.amount1() > 0) {
  priceDiff = int256(targetAmount + delta.amount0()) * 1e18 / targetAmount;
}   
`;

export function TimelineDemo() {
  const [bestLiquidity, setBestLiquidity] = useState("");
  const [bestPrice, setBestPrice] = useState("");

  const data = [
    {
      title: "Quote",
      content: (
        <div>
          <div className="rounded-lg mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Query the best price for a swap...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> {`Searching liqudity: `}
              <TypeAnimation
                sequence={[
                  "Uniswap, Curve, SushiSwap, etc.",
                  200,
                  "GSR, Wintermute, Amber Group, etc.",
                  () => {
                    setBestLiquidity("GSR");
                  },
                ]}
                wrapper="span"
                cursor={false}
              />
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span>
              {`Comparing prices: `}
              {bestLiquidity === "GSR" && (
                <TypeAnimation
                  sequence={[
                    "2424.50",
                    200,
                    "2424.50, 2425.75",
                    200,
                    "2424.50, 2425.75, 2423.80 USDC/ETH",
                    200,
                    () => setBestPrice("2423.80 USDC/ETH"),
                  ]}
                  wrapper="span"
                  cursor={false}
                />
              )}
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> {`Best price found: `}
              {bestPrice === "2423.80 USDC/ETH" && (
                <TypeAnimation sequence={["2423.80 USDC/ETH", 500]} wrapper="span" cursor={false} />
              )}
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span>
              {` How to fill liquidity in `}
              <span className="text-pink-400">Uniswap Tick</span>
              {` from third party quote?`} <br />
            </p>
            <blockquote className="pt-2 text-gray-300 max-w-xl border-l-4 border-pink-400 pl-4 italic">
              Mapping LP positions from various DEXs to Uniswap V4 ticks, ensuring precise alignment and optimal pricing
              for seamless cross-platform liquidity provision.
            </blockquote>
            <div className="relative max-w-2xl rounded-lg mt-16">
              <Card className="z-10 translate-y-12">
                <SyntaxHighlighter
                  language="solidity"
                  customStyle={{ fontSize: "12px", borderRadius: "10px", margin: 0 }}
                >
                  {quote_code_snippet}
                </SyntaxHighlighter>
              </Card>
              <div className="z-0 absolute top-0 left-6 rotate-6">
                <Image src="/assets/liquidity.png" alt="Liquidity" width={600} height={300} className="rounded-lg" />
              </div>
            </div>
          </div>
        </div>
      ),
    },
    {
      title: "Before Swap",
      content: (
        <div>
          <div className="rounded-lg p-4 mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Add liquidity to the pool...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Before swap,{" "}
              <span className="text-pink-400">remove liquidity</span> last left...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Calc a new{" "}
              <span className="text-pink-400">tickLower, tickUpper and slot0 tick</span> from quote
            </p>
            <blockquote className="pt-2 text-gray-300 max-w-xl border-l-4 border-pink-400 pl-4 italic">
              Optimizing liquidity provision by adjusting tick ranges to ensure 50% of the price range meets
              single-sided trading needs, with dynamic corrections to maintain target prices within the optimal zone.
            </blockquote>
            <Image src="/assets/delta.png" alt="Liquidity" width={600} height={480} className="rounded-lg mt-8" />
          </div>
        </div>
      ),
    },
    {
      title: "Swap",
      content: (
        <div>
          <div className="rounded-lg p-4 mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Execute swap...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Swap 2423.80 USDC to 1 ETH
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> 👏 Swap successful!
            </p>
          </div>
        </div>
      ),
    },
    {
      title: "After Swap",
      content: (
        <div>
          <div className="rounded-lg p-4 mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Check the price diff...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Pool stats updated:{" "}
            </p>
            <blockquote className="pt-2 text-gray-300 max-w-xl border-l-4 border-pink-400 pl-4 italic mt-4">
              Liquidity is now <span className="text-pink-400">`poolManager.getLiquidity(poolId)`</span>, current Tick
              is <span className="text-pink-400">`poolManager.getTick(poolId)`</span>, and Delta amounts are{" "}
              <span className="text-pink-400">`delta.amount0()`</span> and{" "}
              <span className="text-pink-400">`delta.amount1()`</span>
            </blockquote>
          </div>
          <Card className="z-10 max-w-2xl mt-2">
            <SyntaxHighlighter language="solidity" customStyle={{ fontSize: "12px", borderRadius: "10px", margin: 0 }}>
              {after_swap_code_snippet}
            </SyntaxHighlighter>
          </Card>
        </div>
      ),
    },
    {
      title: "Before Remove Liquidity",
      content: (
        <div>
          <div className="rounded-lg p-4 mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Verify new balance...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Updating wallet...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Fetching new balance...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> New balance: 100 USDC
            </p>
          </div>
          <blockquote className="pt-2 text-gray-300 max-w-xl border-l-4 border-pink-400 pl-4 italic">
            Optimizing liquidity provision by adjusting tick ranges to ensure 50% of the price range meets single-sided
            trading needs, with dynamic corrections to maintain target prices within the optimal zone.
          </blockquote>
          <Image src="/assets/delta.png" alt="Liquidity" width={600} height={480} className="rounded-lg mt-8" />
        </div>
      ),
    },
  ];
  return (
    <div className="w-[72rem]">
      <Timeline data={data} />
    </div>
  );
}
