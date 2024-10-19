import type { NextPage } from "next";
import { TimelineDemo } from "~~/components/timeline";
import { TextHoverEffect } from "~~/components/ui/text-hover-effect";

const Home: NextPage = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex flex-col items-center justify-center my-40">
        <TextHoverEffect text="UNIHOOK" />
        <p className="text-center text-neutral-200 max-w-2xl">
          Unihook: Revolutionizing DeFi with seamless cross-chain liquidity and enhanced user experience. Empowering
          traders and liquidity providers across multiple blockchains.
        </p>
      </div>
      <TimelineDemo />
    </div>
  );
};

export default Home;
