import type { NextPage } from "next";
import GitHubButton from "react-github-btn";
import { TimelineDemo } from "~~/components/timeline";
import { TextHoverEffect } from "~~/components/ui/text-hover-effect";

const Home: NextPage = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex flex-col items-center justify-center mt-36">
        <GitHubButton
          href="https://github.com/Attens1423/market-maker-hook"
          data-color-scheme="no-preference: light; light: light; dark: dark;"
          data-icon="octicon-star"
          data-size="large"
          aria-label="Star Attens1423/market-maker-hook on GitHub"
        >
          Star
        </GitHubButton>

        <TextHoverEffect text="UNIHOOK" />

        <p className="text-center text-neutral-200 max-w-2xl">
          <a href="https://github.com/Attens1423/market-maker-hook" className="text-pink-400">
            Market Maker Hook
          </a>{" "}
          旨在在{" "}
          <a href="https://github.com/Attens1423/Aggregator-Hook" className="text-pink-400">
            Aggregator Hook
          </a>{" "}
          的基础上拓展一个实用案例：使用一个 MatchEngine 维护做市商们提供的 orderbook，当用户发起交易时，使用 Aggregator
          Hook 的技术填充流动性，使得用户能直接使用 orderbook 的报价。这种设计也使得做市商无缝接入 Uniswap V4
          生态成为可能。
        </p>
        <p className="font-mono text-center text-pink-400 max-w-2xl">Aggregator // Order Limit // Tick Mapping</p>
      </div>
      <TimelineDemo />
    </div>
  );
};

export default Home;
