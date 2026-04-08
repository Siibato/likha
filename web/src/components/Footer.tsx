"use client";

import Link from "next/link";

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="border-t border-[#e0e0e0] bg-white">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
          {/* Left: Brand */}
          <div>
            <h3 className="mb-2 text-xl font-bold text-[#2b2b2b]">Likha</h3>
            <p className="text-sm text-[#666666]">
              Free offline Learning Management System for schools with limited connectivity.
            </p>
          </div>

          {/* Middle: Navigation */}
          <div>
            <h4 className="mb-4 font-semibold text-[#2b2b2b]">Navigate</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/" className="text-[#666666] hover:text-[#2b2b2b]">
                  Home
                </Link>
              </li>
              <li>
                <Link href="/privacy-policy" className="text-[#666666] hover:text-[#2b2b2b]">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms-and-conditions" className="text-[#666666] hover:text-[#2b2b2b]">
                  Terms & Conditions
                </Link>
              </li>
            </ul>
          </div>

          {/* Right: Contact */}
          <div>
            <h4 className="mb-4 font-semibold text-[#2b2b2b]">Contact</h4>
            <p className="text-sm text-[#666666]">
              <a href="mailto:hello@likha.app" className="hover:text-[#2b2b2b]">
                hello@likha.app
              </a>
            </p>
          </div>
        </div>

        {/* Bottom: Copyright */}
        <div className="mt-8 border-t border-[#e0e0e0] pt-8 text-center text-sm text-[#999999]">
          <p>&copy; {currentYear} Likha. Open source LMS for education.</p>
        </div>
      </div>
    </footer>
  );
}
