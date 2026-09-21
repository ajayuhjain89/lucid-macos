import React from "react";
import Link from "next/link";
import { currentRelease } from "@/lib/release";
import { siteConfig } from "@/lib/site-config";

export function DownloadCTASection() {
  return (
    <section className="py-24 sm:py-32 border-t border-border-subtle bg-surface/10">
      <div className="max-w-reading mx-auto px-4 sm:px-6 text-center space-y-8">
        <div className="space-y-3">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Markdown, made lucid.
          </h2>
          <p className="text-base sm:text-lg text-text-secondary leading-relaxed max-w-prose mx-auto">
            Experience equations, chemistry, Mermaid diagrams, and technical tables in a quiet, native macOS environment.
          </p>
        </div>

        {/* Artifact Capsule */}
        <div className="inline-flex flex-wrap items-center justify-center gap-2 px-3 py-1.5 rounded-full border border-border-strong bg-surface text-xs font-mono text-text-secondary">
          <span>{currentRelease.fileName}</span>
          <span className="text-text-tertiary">•</span>
          <span>{currentRelease.fileSize}</span>
          <span className="text-text-tertiary">•</span>
          <span>Apple Silicon (arm64)</span>
          <span className="text-text-tertiary">•</span>
          <span>macOS {currentRelease.minimumMacOS}+</span>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          <a
            href="/api/download"
            className="inline-flex items-center justify-center gap-2 w-full sm:w-auto px-6 py-3 text-sm font-medium rounded-mac bg-text-primary text-background hover:opacity-90 transition-all shadow-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent active:scale-[0.98]"
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            <span>Download Lucid {currentRelease.version} Beta</span>
          </a>

          <Link
            href="/docs/getting-started"
            className="inline-flex items-center justify-center gap-2 w-full sm:w-auto px-5 py-3 text-sm font-medium rounded-mac border border-border-strong bg-surface hover:bg-surface-hover hover:border-text-secondary text-text-primary transition-all shadow-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
          >
            <span>Getting Started Guide</span>
          </Link>
        </div>

        <div className="pt-2 text-xs text-text-tertiary">
          <span>Free and open-source under the </span>
          <a
            href={siteConfig.license.url}
            target="_blank"
            rel="noopener noreferrer"
            className="text-text-secondary hover:text-text-primary underline underline-offset-2"
          >
            {siteConfig.license.name}
          </a>
          <span>. No telemetry. Documents stay local on your Mac.</span>
        </div>
      </div>
    </section>
  );
}
