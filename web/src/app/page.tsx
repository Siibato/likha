"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Wifi, BookOpen, FileText, Zap } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col bg-[#fafafa]">
      <Navbar />

      {/* Hero Section */}
      <section className="flex-1 px-4 py-20 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h1 className="text-5xl font-bold text-[#2b2b2b] sm:text-6xl">
            Offline Learning,<br />Reimagined
          </h1>
          <p className="mt-6 text-lg text-[#666666]">
            A free, open-source LMS for schools with limited connectivity. No accounts. No subscriptions. Just education.
          </p>
          <div className="mt-10 flex flex-col gap-4 sm:flex-row justify-center">
            <button className="rounded-lg bg-[#34a853] px-8 py-3 font-semibold text-white transition-colors hover:bg-[#2d9249]">
              Download App
            </button>
            <button className="rounded-lg border-2 border-[#2b2b2b] px-8 py-3 font-semibold text-[#2b2b2b] transition-colors hover:bg-[#fafafa]">
              Learn More
            </button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="px-4 py-20 sm:px-6 lg:px-8 bg-white">
        <div className="mx-auto max-w-6xl">
          <h2 className="mb-4 text-center text-4xl font-bold text-[#2b2b2b]">
            Built for Real Classrooms
          </h2>
          <p className="mb-16 text-center text-[#666666]">
            Features designed by educators, for educators.
          </p>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
            {/* Feature 1: Offline-First */}
            <div className="rounded-2xl border border-[#e0e0e0] bg-white p-6 shadow-sm">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#f8f9fa]">
                <Wifi className="h-6 w-6 text-[#404040]" />
              </div>
              <h3 className="mb-2 text-lg font-bold text-[#2b2b2b]">Offline-First</h3>
              <p className="text-sm text-[#666666]">
                Works without internet. Syncs automatically when connection returns.
              </p>
            </div>

            {/* Feature 2: Assessment & Grading */}
            <div className="rounded-2xl border border-[#e0e0e0] bg-white p-6 shadow-sm">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#f8f9fa]">
                <BookOpen className="h-6 w-6 text-[#404040]" />
              </div>
              <h3 className="mb-2 text-lg font-bold text-[#2b2b2b]">Assessments</h3>
              <p className="text-sm text-[#666666]">
                Create, assign, and auto-grade. Support for multiple question types.
              </p>
            </div>

            {/* Feature 3: File Submissions */}
            <div className="rounded-2xl border border-[#e0e0e0] bg-white p-6 shadow-sm">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#f8f9fa]">
                <FileText className="h-6 w-6 text-[#404040]" />
              </div>
              <h3 className="mb-2 text-lg font-bold text-[#2b2b2b]">Assignments</h3>
              <p className="text-sm text-[#666666]">
                Students upload work. Teachers provide feedback and grades.
              </p>
            </div>

            {/* Feature 4: Simple Setup */}
            <div className="rounded-2xl border border-[#e0e0e0] bg-white p-6 shadow-sm">
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-[#f8f9fa]">
                <Zap className="h-6 w-6 text-[#404040]" />
              </div>
              <h3 className="mb-2 text-lg font-bold text-[#2b2b2b]">Simple Setup</h3>
              <p className="text-sm text-[#666666]">
                No complex configuration. Start teaching in minutes.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Why Educators Choose Likha */}
      <section className="px-4 py-20 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl">
          <h2 className="mb-12 text-center text-4xl font-bold text-[#2b2b2b]">
            Why Educators Choose Likha
          </h2>

          <div className="space-y-6">
            <div className="flex gap-4">
              <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-[#34a853]">
                <span className="text-sm font-bold text-white">✓</span>
              </div>
              <div>
                <h3 className="font-semibold text-[#2b2b2b]">Works Without Internet</h3>
                <p className="mt-1 text-[#666666]">
                  No need for constant connectivity. Data syncs when you reconnect.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-[#34a853]">
                <span className="text-sm font-bold text-white">✓</span>
              </div>
              <div>
                <h3 className="font-semibold text-[#2b2b2b]">No Vendor Lock-in</h3>
                <p className="mt-1 text-[#666666]">
                  Open source. Your data stays yours. Deploy on your own infrastructure.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-[#34a853]">
                <span className="text-sm font-bold text-white">✓</span>
              </div>
              <div>
                <h3 className="font-semibold text-[#2b2b2b]">Lightweight on Networks</h3>
                <p className="mt-1 text-[#666666]">
                  Built for schools with limited bandwidth. Works on older devices.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="px-4 py-20 sm:px-6 lg:px-8 bg-white">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="mb-4 text-4xl font-bold text-[#2b2b2b]">Get Started Today</h2>
          <p className="mb-10 text-[#666666]">Download Likha for your platform</p>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div className="rounded-lg border-2 border-[#2b2b2b] p-6">
              <h3 className="mb-2 font-semibold text-[#2b2b2b]">Android</h3>
              <p className="mb-4 text-sm text-[#666666]">APK Download</p>
              <button className="w-full rounded-lg bg-[#2b2b2b] px-4 py-2 text-white transition-colors hover:bg-[#404040]">
                Download
              </button>
            </div>

            <div className="rounded-lg border-2 border-[#2b2b2b] p-6">
              <h3 className="mb-2 font-semibold text-[#2b2b2b]">iOS</h3>
              <p className="mb-4 text-sm text-[#666666]">App Store</p>
              <button className="w-full rounded-lg bg-[#2b2b2b] px-4 py-2 text-white transition-colors hover:bg-[#404040]">
                Download
              </button>
            </div>

            <div className="rounded-lg border-2 border-[#2b2b2b] p-6">
              <h3 className="mb-2 font-semibold text-[#2b2b2b]">Web</h3>
              <p className="mb-4 text-sm text-[#666666]">Browser Access</p>
              <button className="w-full rounded-lg bg-[#2b2b2b] px-4 py-2 text-white transition-colors hover:bg-[#404040]">
                Open Web App
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Contact Form Section */}
      <section className="px-4 py-20 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl">
          <h2 className="mb-4 text-center text-4xl font-bold text-[#2b2b2b]">
            Request a Demo
          </h2>
          <p className="mb-12 text-center text-[#666666]">
            For schools wanting a full walk-through or custom deployment
          </p>

          <form className="space-y-4">
            <input
              type="text"
              placeholder="Your Name"
              className="w-full rounded-lg border border-[#e0e0e0] bg-white px-4 py-3 text-[#2b2b2b] placeholder-[#999999] focus:border-[#34a853] focus:outline-none"
            />
            <input
              type="text"
              placeholder="School Name"
              className="w-full rounded-lg border border-[#e0e0e0] bg-white px-4 py-3 text-[#2b2b2b] placeholder-[#999999] focus:border-[#34a853] focus:outline-none"
            />
            <input
              type="email"
              placeholder="Email"
              className="w-full rounded-lg border border-[#e0e0e0] bg-white px-4 py-3 text-[#2b2b2b] placeholder-[#999999] focus:border-[#34a853] focus:outline-none"
            />
            <textarea
              placeholder="Message"
              rows={4}
              className="w-full rounded-lg border border-[#e0e0e0] bg-white px-4 py-3 text-[#2b2b2b] placeholder-[#999999] focus:border-[#34a853] focus:outline-none"
            />
            <button
              type="submit"
              className="w-full rounded-lg bg-[#34a853] px-6 py-3 font-semibold text-white transition-colors hover:bg-[#2d9249]"
            >
              Send Request
            </button>
          </form>
        </div>
      </section>

      {/* Newsletter Section */}
      <section className="px-4 py-20 sm:px-6 lg:px-8 bg-white">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="mb-4 text-2xl font-bold text-[#2b2b2b]">
            Stay Updated
          </h2>
          <p className="mb-6 text-[#666666]">
            Get news about updates, features, and tips for your classroom
          </p>

          <div className="flex flex-col gap-2 sm:flex-row">
            <input
              type="email"
              placeholder="Enter your email"
              className="flex-1 rounded-lg border border-[#e0e0e0] bg-white px-4 py-3 text-[#2b2b2b] placeholder-[#999999] focus:border-[#34a853] focus:outline-none"
            />
            <button className="rounded-lg bg-[#34a853] px-6 py-3 font-semibold text-white transition-colors hover:bg-[#2d9249]">
              Subscribe
            </button>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
