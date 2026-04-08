"use client";
import { useRouter } from "next/navigation";
import React from "react";

interface ForwardButtonProps {
  next: string;
}

export default function ForwardButton({ next }: ForwardButtonProps) {
  const router = useRouter();

  return (
    <button
      onClick={() => router.push(next)}
      className="absolute hover:cursor-pointer right-2 top-2 m-4 flex items-center gap-2 text-white hover:text-[#b8b4b1] transition"
    >
      <span>Next</span>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        strokeWidth={2}
        stroke="currentColor"
        className="w-5 h-5"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M9 5l7 7-7 7"
        />
      </svg>
    </button>
  );
}
