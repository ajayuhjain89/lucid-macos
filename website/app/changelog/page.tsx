import type { Metadata } from "next";
import Link from "next/link";
import { changelogData } from "@/lib/changelog";
import { currentRelease } from "@/lib/release";
import { CopyButton } from "@/components/ui/copy-button";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Changelog & Release Notes",
  description: "Release history, changelog notes, and verified updates for Lucid for macOS.",
};

export default function ChangelogPage() {
  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-4xl mx-auto">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>Release History</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Changelog
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          Detailed notes on features, refinements, and bug fixes in every Lucid release.
        </p>
      </div>

      {/* Changelog Entries */}
      <div className="space-y-16">
        {changelogData.map((entry) => {
          const anchorId = entry.version.replace(/\./g, "-");
          return (
            <article
              key={entry.version}
              id={anchorId}
              className="p-8 md:p-10 rounded-window border border-border-subtle bg-surface shadow-subtle space-y-8 scroll-mt-24"
            >
              {/* Release Header */}
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-border-subtle">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-2xl font-bold tracking-tight text-text-primary">
                      v{entry.version}
                    </h2>
                    <span className="px-2.5 py-0.5 rounded-full border border-border-subtle bg-surface-elevated font-mono text-xs text-text-secondary">
                      {entry.channel}
                    </span>
                  </div>
                  <time className="text-sm font-mono text-text-tertiary">
                    Released {entry.date}
                  </time>
                </div>

                <div className="flex items-center gap-3">
                  <Button variant="secondary" size="sm" href="/download">
                    Download v{entry.version}
                  </Button>
                </div>
              </div>

              {/* Summary */}
              <div>
                <p className="text-base text-text-primary leading-relaxed">
                  {entry.summary}
                </p>
              </div>

              {/* Highlights */}
              {entry.highlights && entry.highlights.length > 0 && (
                <div className="p-4 rounded bg-surface-elevated border border-border-subtle space-y-2">
                  <div className="text-xs font-mono uppercase tracking-wider text-accent font-medium">
                    Key Highlights
                  </div>
                  <ul className="space-y-1.5 text-sm text-text-secondary list-disc list-inside">
                    {entry.highlights.map((highlight, i) => (
                      <li key={i}>{highlight}</li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Categorized Sections */}
              <div className="space-y-6">
                {entry.sections.map((sec) => (
                  <div key={sec.title} className="space-y-3">
                    <h3 className="text-sm font-mono uppercase tracking-wider text-text-secondary font-semibold">
                      {sec.title}
                    </h3>
                    <ul className="space-y-2.5">
                      {sec.items.map((item, idx) => (
                        <li key={idx} className="flex items-start gap-3 text-sm text-text-secondary leading-relaxed">
                          <span
                            className={`mt-0.5 px-2 py-0.5 rounded text-[10px] font-mono uppercase tracking-wider font-medium shrink-0 ${
                              item.type === "new"
                                ? "bg-accent-soft text-accent"
                                : item.type === "improved"
                                ? "bg-surface-elevated text-text-primary border border-border-subtle"
                                : "bg-surface-elevated text-text-tertiary border border-border-subtle"
                            }`}
                          >
                            {item.type}
                          </span>
                          <span>{item.text}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>

              {/* Checksum for current version */}
              {entry.version === currentRelease.version && (
                <div className="pt-6 border-t border-border-subtle">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-mono text-text-tertiary">
                      SHA-256 for {currentRelease.fileName}:
                    </span>
                    <CopyButton text={currentRelease.sha256} label="Copy SHA-256" />
                  </div>
                  <div className="p-2.5 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg break-all select-all">
                    {currentRelease.sha256}
                  </div>
                </div>
              )}
            </article>
          );
        })}
      </div>

      {/* Footer link to docs */}
      <div className="text-center pt-16 mt-8 border-t border-border-subtle">
        <p className="text-sm text-text-secondary">
          Need help setting up Lucid or learning Markdown syntax?{" "}
          <Link href="/docs/getting-started" className="text-accent hover:underline font-medium">
            Read the Getting Started Guide →
          </Link>
        </p>
      </div>
    </div>
  );
}
