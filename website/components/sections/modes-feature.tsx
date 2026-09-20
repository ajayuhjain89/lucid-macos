import React from "react";
import { WindowFrame } from "@/components/ui/window-frame";

export function ModesFeatureSection() {
  const modes = [
    {
      shortcut: "⌘1",
      name: "Reader Mode",
      summary: "Clean, distraction-free reading canvas.",
      detail: "Hides source code completely to present an editorial reading experience with floating glass chrome.",
    },
    {
      shortcut: "⌘2",
      name: "Split Mode",
      summary: "Synchronized editing and live preview.",
      detail: "Edit Markdown source on the left while observing the rendered document on the right, perfectly in sync.",
    },
    {
      shortcut: "⌘3",
      name: "Editor Mode",
      summary: "Focused raw Markdown source writing.",
      detail: "Full-width native NSTextView editor with line numbers, monospaced typography, and zero distractions.",
    },
  ];

  return (
    <section id="modes" className="py-20 sm:py-28 border-t border-border-subtle">
      <div className="max-w-page mx-auto px-4 sm:px-6 space-y-12">
        <div className="max-w-3xl space-y-3">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            Workflow Flexibility
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Three modes. One coherent workflow.
          </h2>
          <p className="text-base text-text-secondary leading-relaxed">
            Switch effortlessly between pure reading, side-by-side editing, and focused Markdown source with standard macOS shortcuts (⌘1, ⌘2, ⌘3).
          </p>
        </div>

        {/* Real Screenshot of Split Mode */}
        <div className="max-w-5xl mx-auto">
          <WindowFrame
            src="/images/app/split-mode.png"
            alt="Lucid in Split Mode with Markdown source editor on left and rendered preview on right"
            title="Engineering_Showcase.md — Lucid Split Mode"
            allowExpand={true}
            caption="Split Mode (⌘2) showing live Markdown source with line numbers on the left and rendered preview on the right."
          />
        </div>

        {/* Modes explanation row */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pt-4 border-t border-border-subtle">
          {modes.map((mode) => (
            <div key={mode.name} className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="px-1.5 py-0.5 rounded text-xs font-mono font-semibold bg-surface-elevated border border-border-strong text-text-primary">
                  {mode.shortcut}
                </span>
                <h3 className="text-sm font-semibold text-text-primary">
                  {mode.name}
                </h3>
              </div>
              <p className="text-xs font-medium text-text-primary">
                {mode.summary}
              </p>
              <p className="text-xs text-text-secondary leading-relaxed">
                {mode.detail}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
