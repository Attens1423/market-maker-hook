import type { NextPage } from "next";
import GitHubButton from "react-github-btn";
import { TimelineDemo } from "~~/components/timeline";
import { TextHoverEffect } from "~~/components/ui/text-hover-effect";

const Home: NextPage = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex flex-col items-center justify-center mt-24">
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
        <button className="btn btn-primary mt-8 w-40 font-mono italic">Swap</button>
      </div>
      <TimelineDemo />

      <div className="font-mono italic text-neutral-200 flex flex-col items-center justify-center mt-8 mb-16">
        <p className="text-neutral-200">San Francisco, CA // ETHGlobal Hackathon 2024/10/19</p>
        <div className="flex justify-center space-x-4 text-sm">
          <a
            href="https://github.com/Attens1423"
            target="_blank"
            rel="noopener noreferrer"
            className="text-neutral-400 hover:text-white transition-colors"
          >
            @Attens
          </a>
          <a
            href="https://github.com/0xashu"
            target="_blank"
            rel="noopener noreferrer"
            className="text-neutral-400 hover:text-white transition-colors"
          >
            @Ashu
          </a>
          <a
            href="https://github.com/ShiranZH"
            target="_blank"
            rel="noopener noreferrer"
            className="text-neutral-400 hover:text-white transition-colors"
          >
            @Shiran
          </a>
          <a
            href="https://github.com/katherine84522"
            target="_blank"
            rel="noopener noreferrer"
            className="text-neutral-400 hover:text-white transition-colors"
          >
            @Katherine
          </a>
        </div>
      </div>
    </div>
  );
};

export default Home;
