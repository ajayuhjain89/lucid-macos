"use client";

import React, { useState } from "react";
import Link from "next/link";
import { currentRelease } from "@/lib/release";

interface FAQItem {
  question: string;
  answer: React.ReactNode;
}

export function FAQSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const faqs: FAQItem[] = [
    {
      question: "What is Lucid?",
      answer: (
        <p>
          Lucid is a native macOS Markdown reader and editor built for technical documents. It pairs a distraction-free editorial reading surface with a native AppKit windowing shell, offline KaTeX math rendering, mhchem chemistry, and interactive Mermaid diagrams.
        </p>
      ),
    },
    {
      question: "Which Markdown syntax does Lucid support?",
      answer: (
        <p>
          Lucid supports CommonMark, GitHub Flavored Markdown (GFM), tables, task lists, strikethrough, subscript, superscript, footnotes, definition lists, abbreviations, and GitHub/Obsidian style callout alerts (<code className="text-xs font-mono bg-code-bg px-1 rounded">[!NOTE]</code>, <code className="text-xs font-mono bg-code-bg px-1 rounded">[!TIP]</code>, <code className="text-xs font-mono bg-code-bg px-1 rounded">[!IMPORTANT]</code>, <code className="text-xs font-mono bg-code-bg px-1 rounded">[!WARNING]</code>, <code className="text-xs font-mono bg-code-bg px-1 rounded">[!CAUTION]</code>).
        </p>
      ),
    },
    {
      question: "Does Lucid support Mermaid diagrams?",
      answer: (
        <p>
          Yes. Lucid natively renders Mermaid flowcharts, sequence diagrams, class diagrams, state diagrams, and entity-relationship diagrams. Lucid prioritizes readability by maintaining legible graph scaling, and provides pan, zoom, fit to viewport, reset, and SVG export controls.
        </p>
      ),
    },
    {
      question: "Does Lucid support LaTeX mathematics and chemistry?",
      answer: (
        <p>
          Yes. Lucid embeds a bundled KaTeX engine for inline (<code className="text-xs font-mono bg-code-bg px-1 rounded">$...$</code>) and display (<code className="text-xs font-mono bg-code-bg px-1 rounded">$$...$$</code>) mathematical notation. It also includes the <code className="text-xs font-mono bg-code-bg px-1 rounded">mhchem</code> extension for chemical equations, reaction stoichiometry, and isotopic notation (<code className="text-xs font-mono bg-code-bg px-1 rounded">\ce{`{...}`}</code>).
        </p>
      ),
    },
    {
      question: "Can I edit Markdown files inside Lucid?",
      answer: (
        <p>
          Yes. Lucid includes three view modes accessible via ⌘1 (Reader), ⌘2 (Split), and ⌘3 (Editor). In Split Mode, you can edit the Markdown source in a native NSTextView editor while observing live rendered updates in synchronized real time.
        </p>
      ),
    },
    {
      question: "What macOS versions and hardware are supported?",
      answer: (
        <p>
          Lucid requires macOS 14.0 (Sonoma) or newer and an Apple Silicon Mac (M1, M2, M3, M4 or later). Intel (x86_64) Macs are not currently supported by the public binary release.
        </p>
      ),
    },
    {
      question: "Where are my documents stored? Does Lucid upload anything?",
      answer: (
        <p>
          Lucid is strictly a local document-based macOS application. Your files remain on your Mac and are never uploaded to any remote server or cloud service. The app contains zero network telemetry or tracking.
        </p>
      ),
    },
    {
      question: "How do I verify the integrity of my download?",
      answer: (
        <p>
          You can verify the official SHA-256 checksum in your terminal by running:
          <br />
          <code className="block mt-2 p-2 rounded text-xs font-mono bg-code-bg border border-border-subtle text-text-primary overflow-x-auto">
            shasum -a 256 ~/Downloads/{currentRelease.fileName}
          </code>
          <span className="block mt-1 text-xs text-text-secondary">
            Compare the result against the published checksum on our{" "}
            <Link href="/download#verify" className="underline underline-offset-2 text-accent">
              Download Page
            </Link>.
          </span>
        </p>
      ),
    },
    {
      question: "Is Lucid open source?",
      answer: (
        <p>
          Yes. Lucid is released under the MIT License on{" "}
          <a
            href="https://github.com/ajayuhjain89/lucid-macos"
            target="_blank"
            rel="noopener noreferrer"
            className="underline underline-offset-2 text-accent"
          >
            GitHub
          </a>. You can inspect the source code, report issues, and build the app directly using Xcode Command Line Tools.
        </p>
      ),
    },
  ];

  return (
    <section id="faq" className="py-20 sm:py-28 border-t border-border-subtle bg-surface/20">
      <div className="max-w-reading mx-auto px-4 sm:px-6 space-y-12">
        <div className="space-y-3 text-center">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            Questions &amp; Answers
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Frequently Asked Questions
          </h2>
          <p className="text-base text-text-secondary">
            Clear, honest answers about Lucid&apos;s capabilities, platform support, and security.
          </p>
        </div>

        <div className="space-y-3">
          {faqs.map((faq, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div
                key={faq.question}
                className="rounded-[8px] border border-border-subtle bg-surface overflow-hidden transition-colors"
              >
                <button
                  onClick={() => setOpenIndex(isOpen ? null : idx)}
                  className="w-full flex items-center justify-between p-4 sm:p-5 text-left text-sm font-semibold text-text-primary hover:text-accent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
                  aria-expanded={isOpen}
                >
                  <span>{faq.question}</span>
                  <svg
                    className={`w-4 h-4 text-text-tertiary transition-transform duration-200 shrink-0 ml-4 ${
                      isOpen ? "rotate-180 text-accent" : ""
                    }`}
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </button>

                {isOpen && (
                  <div className="px-4 pb-4 sm:px-5 sm:pb-5 pt-1 text-xs sm:text-sm text-text-secondary leading-relaxed border-t border-border-subtle/50">
                    {faq.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
