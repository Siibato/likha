"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Link from "next/link";

export default function TermsAndConditions() {
  const lastUpdated = "April 2026";

  return (
    <div className="min-h-screen flex flex-col bg-[#fafafa]">
      <Navbar />

      <main className="flex-1 px-4 py-12 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-3xl">
          <Link
            href="/"
            className="mb-6 inline-flex items-center gap-2 text-[#34a853] hover:text-[#2d9249]"
          >
            ← Back to Home
          </Link>

          <h1 className="mb-2 text-4xl font-bold text-[#2b2b2b]">Terms & Conditions</h1>
          <p className="mb-8 text-sm text-[#999999]">Last Updated: {lastUpdated}</p>

          <div className="space-y-8">
            {/* Acceptance */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">1. Acceptance of Terms</h2>
              <p className="text-[#666666]">
                By accessing and using Likha, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.
              </p>
            </section>

            {/* License */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">2. License to Use</h2>
              <p className="text-[#666666]">
                Subject to your compliance with this agreement, Likha grants you a limited, non-exclusive, non-transferable license to use the service. This license does not include the right to: (a) sublicense, sell, rent, lease, transfer, assign, or otherwise dispose of the service; (b) modify or alter any part of the service or its content; or (c) use the service for any unlawful purpose or in violation of any laws or regulations.
              </p>
            </section>

            {/* Prohibited Uses */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">3. Prohibited Uses</h2>
              <p className="mb-4 text-[#666666]">You agree not to use Likha to:</p>
              <ul className="ml-6 list-disc space-y-2 text-[#666666]">
                <li>Harass, abuse, or threaten other users</li>
                <li>Post obscene, offensive, or inappropriate content</li>
                <li>Interfere with the proper functioning of the service</li>
                <li>Attempt to gain unauthorized access to any accounts</li>
                <li>Violate any applicable laws or regulations</li>
              </ul>
            </section>

            {/* Disclaimer */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">4. Disclaimer</h2>
              <p className="text-[#666666]">
                Likha is provided as-is without any warranty of any kind, either express or implied. We do not warrant that the service will be uninterrupted or error-free. Your use of the service is entirely at your own risk.
              </p>
            </section>

            {/* Limitations of Liability */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">5. Limitations of Liability</h2>
              <p className="text-[#666666]">
                To the fullest extent permitted by law, Likha shall not be liable for any indirect, incidental, special, or consequential damages arising out of or related to your use of the service, even if we have been advised of the possibility of such damages.
              </p>
            </section>

            {/* Modifications */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">6. Modifications to Service</h2>
              <p className="text-[#666666]">
                Likha reserves the right to modify or discontinue the service at any time, with or without notice. We will make reasonable efforts to provide advance notice of major changes, but cannot guarantee notification in all circumstances.
              </p>
            </section>

            {/* User Accounts */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">7. User Accounts</h2>
              <p className="text-[#666666]">
                If you create an account on Likha, you are responsible for maintaining the confidentiality of your password and account information. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.
              </p>
            </section>

            {/* Governing Law */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">8. Governing Law</h2>
              <p className="text-[#666666]">
                These Terms and Conditions shall be governed by and construed in accordance with the laws applicable in the Philippines, and you irrevocably submit to the exclusive jurisdiction of the courts in that location.
              </p>
            </section>

            {/* Contact */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">9. Contact Us</h2>
              <p className="text-[#666666]">
                If you have questions about these Terms and Conditions, please contact us at:
              </p>
              <p className="mt-2 text-[#666666]">
                <a href="mailto:legal@likha.app" className="text-[#34a853] hover:text-[#2d9249]">
                  legal@likha.app
                </a>
              </p>
            </section>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
