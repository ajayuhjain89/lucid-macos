import React from "react";
import { WindowFrame } from "@/components/ui/window-frame";

export function ReaderExperienceSection() {
  return (
    <section id="reader" className="py-20 sm:py-28 border-t border-border-subtle bg-surface/30">
      <div className="max-w-page mx-auto px-4 sm:px-6">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
          {/* Left Column: Editorial explanation */}
          <div className="lg:col-span-5 space-y-6">
            <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
              Reading Experience
            </span>

            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
              Built to read, not just render.
            </h2>

            <p className="text-base text-text-secondary leading-relaxed">
              Lucid Reader treats Markdown as a publication rather than styled HTML. Typographic rhythm, vertical flow, heading hierarchy, and margin clearances are tuned to eliminate visual fatigue during multi-hour technical reading sessions.
            </p>

            <div className="space-y-5 pt-2 text-sm text-text-secondary">
              <div className="border-l-2 border-border-strong pl-4 space-y-1">
                <div className="font-semibold text-text-primary">Floating Glass Chrome</div>
                <p className="text-xs text-text-secondary leading-relaxed">
                  Translucent NSVisualEffectView toolbar that content scrolls beneath, optically aligned with native macOS traffic lights.
                </p>
              </div>
              <div className="border-l-2 border-border-strong pl-4 space-y-1">
                <div className="font-semibold text-text-primary">Disciplined Hierarchy</div>
                <p className="text-xs text-text-secondary leading-relaxed">
                  Proportional headings with subtle hover anchor links for deep-document navigation.
                </p>
              </div>
              <div className="border-l-2 border-border-strong pl-4 space-y-1">
                <div className="font-semibold text-text-primary">Technical Tables &amp; Breakouts</div>
                <p className="text-xs text-text-secondary leading-relaxed">
                  Structured data tables with alternating row contrast, readable headers, and horizontal overflow preservation.
                </p>
              </div>
            </div>
          </div>

          {/* Right Column: Real Screenshot */}
          <div className="lg:col-span-7">
            <WindowFrame
              src="/images/app/technical-table.png"
              alt="Lucid Reader displaying a Hardware Architecture Guide with technical specifications table and blockquotes"
              title="Hardware_Architecture.md — Lucid Reader"
              allowExpand={true}
              caption="Hardware specifications table and blockquotes in Lucid Reader, showing proportional column widths and clear typography."
            />
          </div>
        </div>
      </div>
    </section>
  );
}
