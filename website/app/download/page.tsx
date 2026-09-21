import type { Metadata } from "next";
import Link from "next/link";
import { currentRelease, systemRequirements } from "@/lib/release";
import { siteConfig } from "@/lib/site-config";
import { Button } from "@/components/ui/button";
import { CopyButton } from "@/components/ui/copy-button";

export const metadata: Metadata = {
  title: "Download Lucid for macOS",
  description: `Download Lucid v${currentRelease.version} for macOS Sonoma and Sequoia. Apple Silicon native, offline STEM Markdown reader and editor.`,
};

export default function DownloadPage() {
  const verifyCommand = `shasum -a 256 ~/Downloads/${currentRelease.fileName}`;
  const buildCommand = `git clone ${siteConfig.githubUrl}.git\ncd lucid-macos\n./build.sh`;

  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-5xl mx-auto">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>v{currentRelease.version}</span>
          <span>•</span>
          <span className="capitalize">{currentRelease.releaseChannel}</span>
          <span>•</span>
          <span>Apple Silicon (arm64)</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Download Lucid for macOS
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          Native, offline Markdown reader & editor for technical notes, research papers, diagrams, and equations.
        </p>
      </div>

      {/* Main Download Card */}
      <div className="p-8 md:p-10 rounded-window border border-border-subtle bg-surface shadow-subtle mb-16">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8 pb-8 border-b border-border-subtle">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <span className="text-xl font-semibold text-text-primary">
                {currentRelease.fileName}
              </span>
              <span className="text-xs font-mono px-2 py-0.5 rounded border border-border-subtle bg-surface-elevated text-text-secondary">
                {currentRelease.fileSize}
              </span>
            </div>
            <p className="text-sm text-text-secondary">
              Requires macOS {currentRelease.minimumMacOS} ({currentRelease.minimumMacOSCodeName}) or later • Released {currentRelease.releaseDate}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
            {currentRelease.hasPublicDownloadUrl ? (
              <Button
                variant="primary"
                size="lg"
                href="/api/download"
                className="w-full md:w-auto justify-center"
              >
                <svg className="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download Lucid ({currentRelease.fileSize})
              </Button>
            ) : (
              <div className="flex flex-col gap-2 w-full md:w-auto">
                <Button
                  variant="primary"
                  size="lg"
                  href={currentRelease.githubReleaseUrl || siteConfig.githubUrl}
                  external
                  className="w-full md:w-auto justify-center"
                >
                  <svg className="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
                    <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
                  </svg>
                  Get on GitHub Releases
                </Button>
                <span className="text-xs text-text-tertiary text-center">
                  Direct download fallback • View on GitHub Releases
                </span>
              </div>
            )}
            <Button
              variant="secondary"
              size="lg"
              href={currentRelease.githubReleaseUrl || siteConfig.githubUrl}
              external
              className="w-full md:w-auto justify-center"
            >
              View release on GitHub
            </Button>
            <Button
              variant="subtle"
              size="lg"
              href={siteConfig.githubUrl}
              external
              className="w-full md:w-auto justify-center"
            >
              View source on GitHub
            </Button>
          </div>
        </div>

        {/* SHA-256 Checksum Verification */}
        <div className="pt-8">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-xs font-mono uppercase tracking-wider text-text-secondary">
              SHA-256 Checksum Verification
            </h2>
            <CopyButton text={currentRelease.sha256} label="Copy Hash" />
          </div>
          <div className="p-3 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg break-all select-all">
            {currentRelease.sha256}
          </div>

          <div className="mt-4 pt-4 border-t border-border-subtle">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-mono text-text-secondary">Verify in Terminal:</span>
              <CopyButton text={verifyCommand} label="Copy Command" />
            </div>
            <pre className="p-3 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg overflow-x-auto">
              {verifyCommand}
            </pre>
          </div>
        </div>
      </div>

      {/* System Requirements & Gatekeeper Note */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-16">
        {/* Requirements */}
        <div className="p-6 rounded-window border border-border-subtle bg-surface">
          <h2 className="text-lg font-semibold text-text-primary mb-4 flex items-center gap-2">
            <svg className="w-5 h-5 text-accent" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            System Requirements
          </h2>
          <div className="space-y-4">
            {systemRequirements.map((req) => (
              <div key={req.label} className="pb-3 border-b border-border-subtle last:border-0 last:pb-0">
                <div className="text-xs font-mono uppercase tracking-wider text-text-secondary mb-1">
                  {req.label}
                </div>
                <div className="text-sm font-medium text-text-primary">
                  {req.value}
                </div>
                {req.note && (
                  <div className="text-xs text-text-tertiary mt-0.5">
                    {req.note}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Gatekeeper Beta Guidance */}
        <div className="p-6 rounded-window border border-border-subtle bg-surface">
          <h2 className="text-lg font-semibold text-text-primary mb-4 flex items-center gap-2">
            <svg className="w-5 h-5 text-accent" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            macOS Gatekeeper Note (Beta)
          </h2>
          <div className="text-sm text-text-secondary space-y-3">
            <p>
              Lucid is currently in public beta and is ad-hoc signed. When opening Lucid for the first time, macOS Gatekeeper may prompt that the developer cannot be verified.
            </p>
            <div className="p-3 rounded bg-surface-elevated border border-border-subtle text-xs space-y-2">
              <div className="font-semibold text-text-primary">Option 1: Finder (Recommended)</div>
              <div>
                Right-click (or Control-click) <strong className="text-text-primary">Lucid.app</strong> in your Applications folder, choose <strong className="text-text-primary">Open</strong>, and click <strong className="text-text-primary">Open</strong> in the prompt.
              </div>
            </div>
            <div className="p-3 rounded bg-surface-elevated border border-border-subtle text-xs space-y-2">
              <div className="font-semibold text-text-primary">Option 2: System Settings</div>
              <div>
                If macOS still blocks the app, open <strong className="text-text-primary">System Settings → Privacy &amp; Security</strong>, scroll to the Security section, and click <strong className="text-text-primary">Open Anyway</strong> next to the message about Lucid.
              </div>
            </div>
            <p className="text-xs text-text-tertiary">
              Official Apple Developer ID signing and notarization will be configured for the stable release.
            </p>
          </div>
        </div>
      </div>

      {/* Alternative: Build from Source */}
      <div className="p-6 rounded-window border border-border-subtle bg-surface mb-16">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
          <div>
            <h2 className="text-lg font-semibold text-text-primary">
              Alternative: Build from Source
            </h2>
            <p className="text-sm text-text-secondary">
              Compile Lucid locally using Swift Package Manager and Xcode on macOS Sonoma/Sequoia.
            </p>
          </div>
          <CopyButton text={buildCommand} label="Copy Commands" />
        </div>
        <pre className="p-4 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg overflow-x-auto">
          {buildCommand}
        </pre>
      </div>

      {/* Release Notes Link */}
      <div className="text-center pt-8 border-t border-border-subtle">
        <p className="text-sm text-text-secondary">
          Looking for past changes, bug fixes, or release notes?{" "}
          <Link href="/changelog" className="text-accent hover:underline font-medium">
            Read the v{currentRelease.version} Changelog →
          </Link>
        </p>
      </div>
    </div>
  );
}
