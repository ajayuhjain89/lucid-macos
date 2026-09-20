import React from "react";
import { WindowFrame } from "@/components/ui/window-frame";

export function NavigationPaletteSection() {
  return (
    <section id="navigation" className="py-20 sm:py-28 border-t border-border-subtle bg-surface/30">
      <div className="max-w-page mx-auto px-4 sm:px-6 space-y-16">
        {/* Outline & Heading Navigation */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
          <div className="lg:col-span-5 space-y-6">
            <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
              Document Architecture
            </span>

            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
              Know where you are.
            </h2>

            <p className="text-base text-text-secondary leading-relaxed">
              When working with multi-thousand-line technical specifications, losing your place slows down thinking. Lucid features a live heading outline sidebar with scroll-spy and instant filtering.
            </p>

            <ul className="space-y-3 pt-2 text-sm text-text-secondary">
              <li className="flex items-start gap-2.5">
                <span className="px-1.5 py-0.5 rounded text-xs font-mono bg-surface border border-border-strong text-text-primary">
                  ⌃⌘S
                </span>
                <span><strong>Toggle Sidebar:</strong> Instantly reveal or collapse the hierarchical document map.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <span className="px-1.5 py-0.5 rounded text-xs font-mono bg-surface border border-border-strong text-text-primary">
                  ⌘F
                </span>
                <span><strong>In-Document Find:</strong> Floating find bar with Next (⌘G) and Previous (⇧⌘G) match navigation.</span>
              </li>
              <li className="flex items-start gap-2.5">
                <span className="px-1.5 py-0.5 rounded text-xs font-mono bg-surface border border-border-strong text-text-primary">
                  Live Spy
                </span>
                <span><strong>Scroll-Spy Tracking:</strong> The active section highlights smoothly as you navigate through long documents.</span>
              </li>
            </ul>
          </div>

          <div className="lg:col-span-7">
            <WindowFrame
              src="/images/app/outline-sidebar.png"
              alt="Lucid with Heading Outline sidebar open showing document hierarchy and scroll-spy active section"
              title="Engineering_Showcase.md — Heading Outline"
              allowExpand={true}
              caption="Live outline sidebar (⌃⌘S) with hierarchical indentation, heading levels (H1, H2, H3), and real-time scroll tracking."
            />
          </div>
        </div>

        {/* Command Palette */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center pt-12 border-t border-border-subtle">
          <div className="lg:col-span-7 order-2 lg:order-1">
            <WindowFrame
              src="/images/app/command-palette.png"
              alt="Lucid Command Palette open over document, showing quick actions for view modes, focus mode, and sidebar"
              title="Lucid Command Palette (⌘K)"
              allowExpand={true}
              caption="Fuzzy Command Palette (⌘K) providing instant keyboard access to modes, themes, presets, and export."
            />
          </div>

          <div className="lg:col-span-5 order-1 lg:order-2 space-y-6">
            <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
              Keyboard-First Control
            </span>

            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
              Anything important is close.
            </h2>

            <p className="text-base text-text-secondary leading-relaxed">
              Never hunt through multi-level menus. The native Command Palette brings every document mode, curated theme, reading preset, and export action to your fingertips with fuzzy search.
            </p>

            <div className="p-4 rounded-[8px] border border-border-subtle bg-surface space-y-2">
              <div className="flex items-center justify-between text-xs font-mono">
                <span className="text-text-primary font-semibold">Open Command Palette</span>
                <span className="px-1.5 py-0.5 rounded bg-surface-elevated border border-border-strong text-accent font-semibold">
                  ⌘K
                </span>
              </div>
              <p className="text-xs text-text-secondary">
                Switch themes, jump between modes, insert templates, or export to PDF without touching the trackpad.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
