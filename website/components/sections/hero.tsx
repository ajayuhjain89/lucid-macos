import React from "react";
import Link from "next/link";
import Image from "next/image";
import { currentRelease } from "@/lib/release";
import { siteConfig } from "@/lib/site-config";
import { WindowFrame } from "@/components/ui/window-frame";

export function HeroSection() {
  return (
    <section className="relative pt-12 pb-20 sm:pt-20 sm:pb-28 overflow-hidden">
      <div className="max-w-page mx-auto px-4 sm:px-6">
        {/* Editorial Eyebrow & Title */}
        <div className="max-w-3xl mx-auto text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full border border-border-subtle bg-surface text-[11px] font-mono text-text-secondary tracking-tight">
            <span>macOS {currentRelease.minimumMacOS}+</span>
            <span className="text-text-tertiary">•</span>
            <span>Apple Silicon Native</span>
            <span className="text-text-tertiary">•</span>
            <span className="text-accent font-medium">v{currentRelease.version} Beta</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-bold tracking-tight text-text-primary leading-[1.12]">
            Markdown, made lucid.
          </h1>

          <p className="text-base sm:text-lg text-text-secondary leading-relaxed max-w-2xl mx-auto">
            A native macOS Markdown reader and editor built for technical documents — equations, chemistry, Mermaid diagrams, code, and tables rendered as one coherent reading experience.
          </p>

          {/* Primary & Secondary Actions */}
          <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-3">
            <Link
              href="/download"
              className="inline-flex items-center justify-center gap-2 w-full sm:w-auto px-5 py-2.5 text-sm font-medium rounded-[8px] bg-text-primary text-background hover:opacity-90 transition-all shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent active:scale-[0.98]"
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
              <span>Download for macOS</span>
            </Link>

            <Link
              href="/features"
              className="inline-flex items-center justify-center gap-2 w-full sm:w-auto px-4 py-2.5 text-sm font-medium rounded-[8px] border border-border-strong bg-surface hover:bg-surface-hover hover:border-text-secondary text-text-primary transition-all shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
            >
              <span>Explore features</span>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="5" y1="12" x2="19" y2="12" />
                <polyline points="12 5 19 12 12 19" />
              </svg>
            </Link>
          </div>

          {/* Quiet release metadata below CTA */}
          <div className="pt-2 flex items-center justify-center gap-3 text-xs text-text-tertiary">
            <span>Requires macOS 14.0 or newer</span>
            <span>•</span>
            <span>Apple Silicon (M1+)</span>
            <span>•</span>
            <Link href="/download#verify" className="hover:text-text-secondary underline underline-offset-2">
              Verify SHA-256
            </Link>
          </div>
        </div>

        {/* Real Product Hero Screenshot in macOS Window Presentation */}
        <div className="mt-12 sm:mt-16 max-w-5xl mx-auto">
          <WindowFrame
            src="/images/app/reader-dark.png"
            alt="Lucid Reader displaying a STEM technical Markdown document with KaTeX battery electrochemistry equations"
            title="Engineering_Showcase.md — Lucid Reader"
            priority={true}
            allowExpand={true}
            caption="Real screenshot of Lucid Reader in Studio Dark. The floating glass toolbar allows content to scroll naturally beneath it."
          />
        </div>
      </div>
    </section>
  );
}
