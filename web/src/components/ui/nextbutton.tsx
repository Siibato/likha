'use client';
import React from "react";
import { useRouter } from "next/navigation";

interface NextButtonProps {
  children: React.ReactNode;
  disabled?: boolean;
  href: string; // new prop to specify the target route
}

export default function NextButton({ children, disabled, href }: NextButtonProps) {
  const router = useRouter();

  const handleClick = () => {
    if (!disabled) {
      router.push(href);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={disabled}
      className="bg-[#642224] hover:cursor-pointer hover:bg-[#642224]/80 text-white font-bold py-2 px-6 rounded transition disabled:opacity-50"
    >
      {children}
    </button>
  );
}
