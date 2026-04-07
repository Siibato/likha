"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Link from "next/link";

export default function PrivacyPolicy() {
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

          <h1 className="mb-2 text-4xl font-bold text-[#2b2b2b]">Privacy Policy</h1>
          <p className="mb-8 text-sm text-[#999999]">Last Updated: {lastUpdated}</p>

          <div className="space-y-8">
            {/* Introduction */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">1. Introduction</h2>
              <p className="text-[#666666]">
                Likha (we, us, our) operates the Likha Learning Management System (LMS). This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our service and the choices you have associated with that data.
              </p>
            </section>

            {/* Data Collection */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">2. Information We Collect</h2>
              <p className="mb-4 text-[#666666]">We collect several different types of information for various purposes:</p>
              <ul className="ml-6 list-disc space-y-2 text-[#666666]">
                <li><strong>Account Information:</strong> name, email, school affiliation, and role (teacher, admin, student)</li>
                <li><strong>Educational Data:</strong> class information, assignments, assessments, grades, and student work</li>
                <li><strong>Device Information:</strong> IP address, device type, operating system, and browser type</li>
                <li><strong>Usage Data:</strong> pages visited, time spent, and interactions within the application</li>
              </ul>
            </section>

            {/* Data Usage */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">3. How We Use Your Data</h2>
              <p className="mb-4 text-[#666666]">We use the collected data for purposes including:</p>
              <ul className="ml-6 list-disc space-y-2 text-[#666666]">
                <li>Providing and maintaining the LMS service</li>
                <li>Processing educational activities and grading</li>
                <li>Improving user experience and service functionality</li>
                <li>Communicating important updates or changes to the service</li>
                <li>Complying with legal obligations</li>
              </ul>
            </section>

            {/* Data Retention */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">4. Data Retention</h2>
              <p className="text-[#666666]">
                We retain your data as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time, except where data must be retained for legal compliance or educational record purposes.
              </p>
            </section>

            {/* Data Sharing */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">5. Sharing Your Information</h2>
              <p className="mb-4 text-[#666666]">
                We do not sell your personal information. We may share data only in the following circumstances:
              </p>
              <ul className="ml-6 list-disc space-y-2 text-[#666666]">
                <li>With school administrators who manage your account</li>
                <li>With service providers who help us operate the platform</li>
                <li>When required by law or legal process</li>
              </ul>
            </section>

            {/* Your Rights */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">6. Your Rights</h2>
              <p className="mb-4 text-[#666666]">
                You have the right to:
              </p>
              <ul className="ml-6 list-disc space-y-2 text-[#666666]">
                <li>Access your personal data</li>
                <li>Correct inaccurate data</li>
                <li>Request deletion of your data (subject to legal holds)</li>
                <li>Opt out of non-essential communications</li>
              </ul>
              <p className="mt-4 text-[#666666]">
                To exercise these rights, contact us at privacy@likha.app.
              </p>
            </section>

            {/* Children's Privacy */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">7. Children&apos;s Privacy</h2>
              <p className="text-[#666666]">
                Likha is designed for educational use by students under teacher and parent supervision. We comply with COPPA and similar regulations. Parents/guardians can contact us to review, update, or delete children&apos;s information.
              </p>
            </section>

            {/* Contact */}
            <section>
              <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">8. Contact Us</h2>
              <p className="text-[#666666]">
                If you have questions about this Privacy Policy, please contact us at:
              </p>
              <p className="mt-2 text-[#666666]">
                <a href="mailto:privacy@likha.app" className="text-[#34a853] hover:text-[#2d9249]">
                  privacy@likha.app
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
