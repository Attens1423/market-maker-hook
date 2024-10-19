"use client";

import React from "react";
import { cn } from "@/utils/tailwind";
import { motion } from "framer-motion";

export const Card: React.FC<{
  children: React.ReactNode;
  className?: string;
  draggable?: boolean;
}> = ({ children, className, draggable = true }) => {
  return (
    <motion.div
      drag={draggable}
      dragSnapToOrigin
      dragConstraints={{
        top: -50,
        left: -50,
        right: 50,
        bottom: 50,
      }}
      whileHover={{ scale: 1.05, translateY: -2, rotate: 1 }}
      className={cn(
        "relative flex flex-col h-fit bg-white rounded-lg shadow-md ring-1 ring-black/5 overflow-hidden",
        "md:hover:shadow-lg",
        className,
      )}
    >
      {children}
    </motion.div>
  );
};
