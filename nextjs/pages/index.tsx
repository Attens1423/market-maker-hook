import type { NextPage } from "next";
import { TimelineDemo } from "~~/components/timeline";
import { TextHoverEffect } from "~~/components/ui/text-hover-effect";

const Home: NextPage = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex flex-col items-center justify-center my-40">
        <TextHoverEffect text="UNIHOOK" />
        <p className="text-center text-neutral-200 max-w-2xl">
          Aggregator Hook 旨在充当 “桥梁”，使得市场上的流动性能直接链接到 Uniswap V4 的池子；同时利用 “及时原则”
          动态管理流动性资金，在交易前注入流动性，在交易后撤出流动性，将流动性迁移对原池子的影响最小化。这种集成使 LPs
          能夜以前所未有的便捷方式管理资金，利用 Uniswap 的坚固架构，同时利用更广泛的 DEX 生态系统中的流动性。
        </p>
      </div>
      <TimelineDemo />
    </div>
  );
};

export default Home;
