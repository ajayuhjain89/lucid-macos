import React from "react";
import { currentRelease } from "@/lib/release";

export function NativeMacSection() {
  const shortcuts = [
    { key: "⌘1", label: "Reader Mode" },
    { key: "⌘2", label: "Split Mode" },
    { key: "⌘3", label: "Editor Mode" },
    { key: "⌃⌘S", label: "Toggle Sidebar" },
    { key: "⌘F", label: "Find in Document" },
    { key: "⌘G", label: "Find Next" },
    { key: "⇧⌘G", label: "Find Previous" },
    { key: "⌘⇧D", label: "Focus Mode" },
    { key: "⌘K", label: "Command Palette" },
    { key: "⌘,", label: "Settings" },
  ];

  const specs = [
    { label: "Target Platform", value: `macOS ${currentRelease.minimumMacOS}+ (${currentRelease.minimumMacOSCodeName})` },
    { label: "CPU Architecture", value: currentRelease.architectures.join(", ") },
    { label: "Binary Footprint", value: `${currentRelease.fileSize} (no Electron/Chromium)` },
    { label: "Window Subsystem", value: "Native AppKit + NSVisualEffectView" },
    { label: "Canvas Engine", value: "Bundled WebKit (offline local bridge)" },
    { label: "File Watching", value: "macOS FSEvents kernel integration" },
    { label: "Network Access", value: "Zero outgoing telemetry pings" },
  ];

  return (
    <section className="py-20 sm:py-28 border-t border-border-subtle bg-surface/20">
      <div className="max-w-page mx-auto px-4 sm:px-6 space-y-16">
        <div className="max-w-3xl space-y-3">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            Platform Architecture
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Native where it matters.
          </h2>
          <p className="text-base text-text-secondary leading-relaxed">
            Lucid pairs native macOS AppKit windowing, file management, and keyboard handling with an offline WebKit rendering pipeline designed for rich technical Markdown.
          </p>
        </div>

        {/* Two-Column Architecture: Narrative + System Specs */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-start">
          {/* Left: Architectural Pillars */}
          <div className="lg:col-span-7 space-y-8">
            <div className="space-y-2">
              <h3 className="text-lg font-semibold text-text-primary">
                AppKit Windowing &amp; Vibrant Chrome
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                Lucid&apos;s floating toolbar is a native <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface border border-border-subtle text-accent">NSVisualEffectView</code>. Content scrolls naturally beneath translucent glass with scroll-responsive depth, optically aligned with macOS traffic lights.
              </p>
            </div>

            <div className="space-y-2">
              <h3 className="text-lg font-semibold text-text-primary">
                FSEvents Live File Watching
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                Edit your documents in Neovim, VS Code, or Obsidian. Lucid listens to macOS kernel file-system events, refreshing the rendered view instantly upon save without resetting your reading position or expanding collapsibles.
              </p>
            </div>

            <div className="space-y-2">
              <h3 className="text-lg font-semibold text-text-primary">
                Local-First Sandboxed Execution
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                Your notes, equations, and diagrams remain strictly on your Mac. All parsing, KaTeX math symbols, mhchem reactions, and Mermaid graph engines run offline from local bundled assets.
              </p>
            </div>
          </div>

          {/* Right: Technical Spec Sheet Card */}
          <div className="lg:col-span-5 rounded-window border border-border-strong bg-surface p-6 shadow-subtle space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
              <span className="text-xs font-mono uppercase tracking-wider text-text-tertiary">
                System Profile
              </span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle text-accent font-semibold">
                Universal arm64
              </span>
            </div>

            <dl className="divide-y divide-border-subtle/60 text-xs">
              {specs.map((s) => (
                <div key={s.label} className="py-2.5 flex items-center justify-between gap-4">
                  <dt className="text-text-secondary font-medium shrink-0">{s.label}</dt>
                  <dd className="text-text-primary font-mono text-right truncate">{s.value}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>

        {/* Keyboard Shortcuts Row */}
        <div className="space-y-4 pt-6 border-t border-border-subtle">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-text-tertiary font-mono">
              Canonical Keyboard Shortcuts
            </span>
            <span className="text-xs text-text-tertiary hidden sm:inline font-mono">
              Verified against AppKit Menu Commands
            </span>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
            {shortcuts.map((sc) => (
              <div
                key={sc.key}
                className="flex items-center justify-between px-3 py-2 rounded-[7px] border border-border-subtle bg-surface text-xs hover:border-border-strong transition-colors"
              >
                <span className="text-text-secondary font-medium">{sc.label}</span>
                <kbd className="px-1.5 py-0.5 rounded bg-surface-elevated border border-border-strong text-text-primary font-mono text-[11px] font-semibold">
                  {sc.key}
                </kbd>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
