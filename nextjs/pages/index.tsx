import type { NextPage } from "next";
import { TimelineDemo } from "~~/components/timeline";

const Home: NextPage = () => {
  return (
    <div className="max-w-4xl mx-auto">
      <TimelineDemo />
    </div>
  );
};

export default Home;
