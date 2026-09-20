import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { WindowFrame } from "@/components/ui/window-frame";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Features — Engineered for Technical Documents",
  description: "Explore Lucid's features: offline KaTeX equations, mhchem chemistry, interactive Mermaid diagrams, synchronized split mode, outline sidebar, and native macOS architecture.",
};

export default function FeaturesPage() {
  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-6xl mx-auto space-y-24">
      {/* Page Header */}
      <div className="text-center max-w-3xl mx-auto">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>Complete Feature Matrix</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-6">
          Engineered for technical documents.
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          Every detail of Lucid is tuned for reading, writing, and navigating complex Markdown — from offline mathematical typesetting to native macOS window chrome.
        </p>
      </div>

      {/* Feature 1: The Reading Canvas */}
      <section className="space-y-8">
        <div className="max-w-2xl">
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            01 / Typographic Discipline
          </div>
          <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary mb-4">
            An editorial reading canvas designed for sustained focus
          </h2>
          <p className="text-text-secondary leading-relaxed">
            Most Markdown previewers stretch text across the entire window or use arbitrary padding. Lucid adheres to classic book typography: a 680px optimal reading measure, calibrated line-height (1.6), and proportional heading scales that keep long-form technical notes comfortable to read for hours.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Optimal Measure</h3>
            <p className="text-sm text-text-secondary">
              The primary prose column is capped at 680px to maintain the 65–75 character line length recommended by typographers for reading comprehension.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Breakout Layouts</h3>
            <p className="text-sm text-text-secondary">
              Wide tables and complex Mermaid diagrams dynamically expand beyond the reading column up to 1200px, avoiding cramped horizontal scrolling.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Curated Themes</h3>
            <p className="text-sm text-text-secondary">
              Switch effortlessly between Studio Dark (#171717), Editorial Light (#fafafa), Warm Book Sepia (#fbf0d9), or System Dynamic.
            </p>
          </div>
        </div>

        <WindowFrame title="Lucid — Editorial Reading Canvas" mode="reader">
          <Image
            src="/images/app/reader-dark.png"
            alt="Lucid Editorial Reading Canvas in Studio Dark"
            width={1240}
            height={780}
            className="w-full h-auto"
          />
        </WindowFrame>
      </section>

      {/* Feature 2: STEM & Technical Markdown */}
      <section className="space-y-8 pt-12 border-t border-border-subtle">
        <div className="max-w-2xl">
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            02 / STEM Notation
          </div>
          <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary mb-4">
            First-class math, chemistry, diagrams, and tables
          </h2>
          <p className="text-text-secondary leading-relaxed">
            Technical documents shouldn&apos;t require messy LaTeX toolchains just to look clean. Lucid renders KaTeX math, mhchem chemistry, and Mermaid diagrams locally without internet access.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Math & Chemistry */}
          <div className="p-6 rounded-window border border-border-subtle bg-surface space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-text-primary">KaTeX Math & mhchem Chemistry</h3>
              <span className="text-xs font-mono text-accent">100% Offline</span>
            </div>
            <p className="text-sm text-text-secondary">
              Render inline equations with <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">$...$</code> and display blocks with <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">$$...$$</code>. Write chemical equations and reaction stoichiometry using <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">\ce{"{...}"}</code>.
            </p>
            <div className="p-4 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg space-y-2">
              <div>{"$$\\nabla \\times \\mathbf{E} = -\\frac{\\partial \\mathbf{B}}{\\partial t}$$"}</div>
              <div className="text-text-tertiary"># Chemical equation via mhchem:</div>
              <div>{"\\ce{LiCoO2 <=> Li_{1-x}CoO2 + xLi+ + xe-}"}</div>
            </div>
          </div>

          {/* Tables & Code */}
          <div className="p-6 rounded-window border border-border-subtle bg-surface space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-text-primary">Technical Tables & Syntax Highlighting</h3>
              <span className="text-xs font-mono text-accent">Preserved Layout</span>
            </div>
            <p className="text-sm text-text-secondary">
              Data tables feature high-contrast headers, alternating row striping, and preserve column alignment. Fenced code blocks include syntax highlighting, language identifier badges, and one-click copy buttons.
            </p>
            <div className="p-4 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg space-y-1">
              <div>| Register | Bits | Description |</div>
              <div>| :--- | :--- | :--- |</div>
              <div>| `CR0` | 32/64 | Control Register 0 (PE, MP, EM, TS) |</div>
            </div>
          </div>
        </div>

        {/* Mermaid Diagram Highlight */}
        <div className="p-8 rounded-window border border-border-subtle bg-surface space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-xl font-semibold text-text-primary">
                Interactive Mermaid Diagrams with Pan & Zoom
              </h3>
              <p className="text-sm text-text-secondary mt-1">
                Standard previewers shrink wide diagrams into unreadable squiggles. Lucid keeps diagrams at human-readable scale with full interactive navigation.
              </p>
            </div>
            <div className="flex items-center gap-2 text-xs font-mono text-text-secondary">
              <span className="px-2 py-1 rounded bg-surface-elevated border border-border-subtle">Pan</span>
              <span className="px-2 py-1 rounded bg-surface-elevated border border-border-subtle">Zoom (+/−)</span>
              <span className="px-2 py-1 rounded bg-surface-elevated border border-border-subtle">Fit</span>
              <span className="px-2 py-1 rounded bg-surface-elevated border border-border-subtle">SVG Export</span>
            </div>
          </div>

          <WindowFrame title="Lucid — Interactive Mermaid Diagram" mode="reader">
            <Image
              src="/images/app/mermaid-diagram.png"
              alt="Mermaid architecture flowchart with interactive controls in Lucid"
              width={1240}
              height={600}
              className="w-full h-auto"
            />
          </WindowFrame>
        </div>
      </section>

      {/* Feature 3: Three View Modes & Split Sync */}
      <section className="space-y-8 pt-12 border-t border-border-subtle">
        <div className="max-w-2xl">
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            03 / View Modes
          </div>
          <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary mb-4">
            Reader, Split, and Editor modes with synchronized scroll
          </h2>
          <p className="text-text-secondary leading-relaxed">
            Seamlessly switch between consumption and authorship with standard macOS keyboard shortcuts. In Split Mode, scrolling the editor or the preview automatically synchronizes the corresponding section.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Reader Mode</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌘1</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Pure reading canvas with all non-essential controls subdued. Ideal for review, study, and presentation.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Split Mode</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌘2</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Side-by-side editing and live preview. Synchronized scrolling ensures your cursor and rendered view stay aligned.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Editor Mode</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌘3</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Distraction-free plain-text Markdown editor with full line numbers, auto-indentation, and outline integration.
            </p>
          </div>
        </div>

        <WindowFrame title="Lucid — Split Mode with Live Preview" mode="split">
          <Image
            src="/images/app/split-mode.png"
            alt="Lucid Split Mode showing Markdown source on the left and rendered preview on the right"
            width={1240}
            height={780}
            className="w-full h-auto"
          />
        </WindowFrame>
      </section>

      {/* Feature 4: Navigation, Search & Command Palette */}
      <section className="space-y-8 pt-12 border-t border-border-subtle">
        <div className="max-w-2xl">
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            04 / Navigation & Command
          </div>
          <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary mb-4">
            Navigate thousands of lines without losing your place
          </h2>
          <p className="text-text-secondary leading-relaxed">
            Technical documents can be thousands of lines long. Lucid equips you with an outline sidebar that tracks your position, an in-document find bar, and a fuzzy Command Palette.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Outline Sidebar</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌃⌘S</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Hierarchical table of contents (H1–H6) with real-time scroll-spy highlighting your active section as you read.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Find in Document</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌘F</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Floating search bar with match count, previous (⇧⌘G), and next (⌘G) navigation across rendered content.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold text-text-primary">Command Palette</h3>
              <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs text-text-secondary">⌘K</kbd>
            </div>
            <p className="text-sm text-text-secondary">
              Fuzzy search across all actions, themes, presets, view modes, and export functions without touching the mouse.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <div className="text-xs font-mono uppercase tracking-wider text-text-secondary mb-3">
              Hierarchical Outline Navigation
            </div>
            <WindowFrame title="Lucid — Outline Sidebar" mode="reader">
              <Image
                src="/images/app/outline-sidebar.png"
                alt="Lucid Outline Sidebar with scroll-spy heading tracking"
                width={600}
                height={400}
                className="w-full h-auto"
              />
            </WindowFrame>
          </div>

          <div>
            <div className="text-xs font-mono uppercase tracking-wider text-text-secondary mb-3">
              Fuzzy Command Palette
            </div>
            <WindowFrame title="Lucid — Command Palette" mode="reader">
              <Image
                src="/images/app/command-palette.png"
                alt="Lucid Command Palette with fuzzy action searching"
                width={600}
                height={400}
                className="w-full h-auto"
              />
            </WindowFrame>
          </div>
        </div>
      </section>

      {/* Feature 5: Native Architecture & Privacy */}
      <section className="space-y-8 pt-12 border-t border-border-subtle">
        <div className="max-w-2xl">
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            05 / Platform & Privacy
          </div>
          <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary mb-4">
            Native Swift performance with zero telemetry
          </h2>
          <p className="text-text-secondary leading-relaxed">
            Lucid is built with Swift and AppKit. It launches instantly, uses minimal memory, and renders documents strictly on your local Mac.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Floating Glass Toolbar</h3>
            <p className="text-sm text-text-secondary">
              Built with native NSVisualEffectView. Content scrolls underneath with authentic macOS vibrancy and subtle depth.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Zero Telemetry</h3>
            <p className="text-sm text-text-secondary">
              No analytics trackers, no account logins, no phone-home pings. All parsing and rendering engines are bundled locally.
            </p>
          </div>
          <div className="p-6 rounded-window border border-border-subtle bg-surface">
            <h3 className="font-semibold text-text-primary mb-2">Live File Watching</h3>
            <p className="text-sm text-text-secondary">
              Edit files in Neovim, VS Code, or Obsidian and watch Lucid update live without resetting your reading position.
            </p>
          </div>
        </div>
      </section>

      {/* CTA Bottom */}
      <div className="p-10 rounded-window border border-border-subtle bg-surface text-center max-w-3xl mx-auto space-y-6">
        <h2 className="text-2xl md:text-3xl font-semibold tracking-tight text-text-primary">
          Experience technical Markdown the way it should be.
        </h2>
        <p className="text-sm text-text-secondary max-w-xl mx-auto">
          Lucid is free and open-source under the MIT license. Download the DMG or clone the repository to build from source.
        </p>
        <div className="flex flex-wrap items-center justify-center gap-4">
          <Button variant="primary" size="lg" href="/download">
            Download Lucid for macOS
          </Button>
          <Button variant="secondary" size="lg" href="/docs">
            Read Documentation
          </Button>
        </div>
      </div>
    </div>
  );
}
