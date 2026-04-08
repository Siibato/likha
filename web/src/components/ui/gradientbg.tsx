'use client';
import React from "react";

export default function GradientBackground() {
  return (
    <>
      <div className="absolute w-[800px] h-[500px] rounded-full bg-gradient-to-br from-[#642224]/30 via-[#262835]/40 to-[#0d0b0b]/20 blur-[180px] top-[15%] right-[-10%]" />
      <div className="absolute w-[700px] h-[500px] rounded-full bg-gradient-to-br from-[#642224]/25 via-[#262835]/35 to-[#0d0b0b]/20 blur-[200px] bottom-[-10%] right-[-10%]" />
      <div className="absolute w-[800px] h-[800px] rounded-full bg-gradient-to-r from-amber-900/25 via-[#642224]/35 to-[#0d0b0b]/40 blur-[180px] bottom-[30%] left-[10%] transform -translate-x-1/2" />
    </>
  );
}
