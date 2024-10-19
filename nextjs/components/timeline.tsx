import React from "react";
import { Timeline } from "@/components/ui/timeline";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { atomDark } from "react-syntax-highlighter/dist/cjs/styles/prism";

const code_snippet = `uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(curTick);

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

export function TimelineDemo() {
  const data = [
    {
      title: "Quote",
      content: (
        <div>
          <div className="rounded-lg mb-8">
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Query the best price for a swap...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Searching DEX platforms...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Comparing prices...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> Best price found!
            </p>
            <div className="max-w-full overflow-x-auto">
              <SyntaxHighlighter language="solidity" style={atomDark}>
                {code_snippet}
              </SyntaxHighlighter>
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
            <p className="font-mono text-pink-400 text-xs md:text-sm">$ Check wallet balance...</p>
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Connecting to wallet...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Fetching balance...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> Balance: 1.5 ETH
            </p>
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
            <p className="font-mono text-white text-xs md:text-sm mt-2">
              <span className="text-pink-400">{">"} </span> Initiating transaction...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"} </span> Confirming on blockchain...
            </p>
            <p className="font-mono text-white text-xs md:text-sm mt-1">
              <span className="text-pink-400">{">"}</span> Swap successful!
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
        </div>
      ),
    },
  ];
  return (
    <div className="w-[56rem]">
      <Timeline data={data} />
    </div>
  );
}
