import type { Metadata } from "next";
import Link from "next/link";
import { siteConfig } from "@/lib/site-config";

export const metadata: Metadata = {
  title: "Privacy Policy — Local-First & Zero Telemetry",
  description: "Lucid's privacy policy: zero telemetry, 100% offline rendering, local-first document handling, and open-source transparency.",
};

export default function PrivacyPage() {
  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-3xl mx-auto space-y-12">
      {/* Header */}
      <div>
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>Privacy & Security</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Privacy Policy
        </h1>
        <p className="text-sm font-mono text-text-tertiary">
          Last updated: September 20, 2026
        </p>
      </div>

      {/* Content */}
      <div className="space-y-8 text-sm text-text-secondary leading-relaxed">
        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            Our Privacy Philosophy
          </h2>
          <p>
            We believe that software designed for technical reading, research, and note-taking must respect your confidentiality unconditionally. Your documents, notes, equations, and diagrams belong entirely to you.
          </p>
          <p>
            Lucid is engineered from the ground up as a <strong className="text-text-primary">local-first, offline application</strong>. It does not collect personal data, track your usage, or transmit your documents to external servers.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            1. No Telemetry or Analytics
          </h2>
          <p>
            Lucid contains <strong className="text-text-primary">zero tracking code</strong>. We do not use Google Analytics, Mixpanel, Amplitude, Sentry, TelemetryDeck, or any other third-party analytics or crash reporting SDKs in the Lucid macOS application.
          </p>
          <ul className="list-disc list-inside space-y-1.5 pl-2 text-xs">
            <li>No tracking of which documents you open or read</li>
            <li>No logging of your IP address, device identifier, or location</li>
            <li>No recording of keyboard input or editing habits</li>
            <li>No heartbeat or phone-home telemetry pings</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            2. Local-First Document Processing
          </h2>
          <p>
            When you open a Markdown file in Lucid, the file is read directly from your local filesystem into memory. All parsing and rendering — including KaTeX mathematics, mhchem chemistry, Mermaid diagrams, and code syntax highlighting — occurs locally within a sandboxed WebKit instance.
          </p>
          <p>
            All rendering engines, JavaScript libraries, and typography assets are bundled locally within the application bundle at <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">Contents/Resources/WebEngine/</code>. The application does not download external scripts, fonts, or stylesheets at runtime.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            3. Network Access & Isolation
          </h2>
          <p>
            The Lucid macOS application does not initiate outgoing network connections for document rendering. Standard documents render completely offline, even with Wi-Fi disabled or in airplane mode.
          </p>
          <p className="text-xs text-text-tertiary">
            Note: If your Markdown document explicitly contains remote images (e.g. <code className="font-mono text-[11px]">![Image](https://example.com/photo.png)</code>), your system may load that specific image resource as requested by your document markup.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            4. Website Privacy
          </h2>
          <p>
            This website (<code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">{siteConfig.siteUrl}</code>) is a static resource. We do not use tracking cookies, tracking pixels, or cross-site advertising trackers. Standard web server logs (which may record your IP address, user agent, and requested URL) are maintained only for operational security and debugging by the hosting provider.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            5. Open Source Verification
          </h2>
          <p>
            Lucid is open source under the MIT License. You do not need to take our word for any of these commitments — you can inspect the full source code, build scripts, and WebKit bridge implementations on GitHub at{" "}
            <a
              href={siteConfig.githubUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-accent hover:underline font-medium"
            >
              {siteConfig.githubUrl}
            </a>.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-text-primary">
            6. Contact & Inquiries
          </h2>
          <p>
            If you have questions regarding this Privacy Policy or Lucid&apos;s security architecture, please open an issue or inquiry on our{" "}
            <a
              href={`${siteConfig.githubUrl}/issues`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-accent hover:underline font-medium"
            >
              GitHub repository
            </a>.
          </p>
        </section>
      </div>

      {/* Back Link */}
      <div className="pt-8 border-t border-border-subtle">
        <Link href="/" className="text-sm text-text-secondary hover:text-accent font-medium">
          ← Back to Lucid Home
        </Link>
      </div>
    </div>
  );
}
