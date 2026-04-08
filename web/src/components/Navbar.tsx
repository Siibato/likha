"use client";

import Link from "next/link";

export default function Navbar() {
  return (
    <nav className="sticky top-0 z-50 w-full border-b border-[#e0e0e0] bg-white">
      <div className="mx-auto max-w-6xl px-4 py-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <span className="text-2xl font-bold text-[#2b2b2b]">Likha</span>
          </Link>

          {/* Right side: Download CTA */}
          <a
            href="#download"
            className="inline-block rounded-lg bg-[#34a853] px-6 py-2 font-semibold text-white transition-colors hover:bg-[#2d9249]"
          >
            Download
          </a>
        </div>
      </div>
    </nav>
  );
}
