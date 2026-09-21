import type { Metadata } from "next";
import Link from "next/link";
import { CopyButton } from "@/components/ui/copy-button";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Getting Started Guide — Lucid",
  description: "Learn how to install Lucid, navigate documents, use split mode, and export technical Markdown on macOS.",
};

export default function GettingStartedPage() {
  const quarantineCommand = `xattr -d com.apple.quarantine /Applications/Lucid.app`;
  const cliOpenCommand = `open -a Lucid path/to/document.md`;

  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-4xl mx-auto space-y-16">
      {/* Header */}
      <div>
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <Link href="/docs" className="hover:text-accent">Docs</Link>
          <span>/</span>
          <span>Getting Started</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Getting Started with Lucid
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          A step-by-step guide to installing, configuring, and working productively with Lucid on macOS Sonoma and Sequoia.
        </p>
      </div>

      {/* Step 1: Installation */}
      <section id="installation" className="space-y-6">
        <div className="flex items-center gap-3">
          <span className="w-8 h-8 rounded-full bg-accent-soft text-accent font-mono text-sm font-bold flex items-center justify-center shrink-0">
            1
          </span>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary">
            Installation & First Launch
          </h2>
        </div>

        <div className="pl-11 space-y-4 text-sm text-text-secondary leading-relaxed">
          <p>
            Download the latest disk image from our <Link href="/download" className="text-accent hover:underline">Download page</Link>. Open <strong className="text-text-primary">Lucid-1.0.1.dmg</strong> and drag <strong className="text-text-primary">Lucid.app</strong> into your Applications folder.
          </p>

          <div className="p-4 rounded-window border border-border-subtle bg-surface space-y-3">
            <h3 className="font-semibold text-text-primary text-sm">
              Handling the macOS Gatekeeper Beta Prompt
            </h3>
            <p className="text-xs text-text-secondary">
              Because Lucid is in public beta and ad-hoc signed, macOS may display a notice stating that the developer cannot be verified. To open:
            </p>
            <ol className="list-decimal list-inside text-xs space-y-1.5 text-text-secondary">
              <li>Open your <strong className="text-text-primary">Applications</strong> folder in Finder.</li>
              <li>Right-click (or Control-click) <strong className="text-text-primary">Lucid.app</strong> and select <strong className="text-text-primary">Open</strong>.</li>
              <li>Click <strong className="text-text-primary">Open</strong> in the confirmation dialog.</li>
            </ol>
            <div className="pt-2 border-t border-border-subtle flex items-center justify-between">
              <span className="text-xs font-mono text-text-tertiary">Or remove quarantine via Terminal:</span>
              <CopyButton text={quarantineCommand} label="Copy Command" />
            </div>
            <pre className="p-2.5 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg overflow-x-auto">
              {quarantineCommand}
            </pre>
          </div>
        </div>
      </section>

      {/* Step 2: Opening Documents */}
      <section id="opening" className="space-y-6">
        <div className="flex items-center gap-3">
          <span className="w-8 h-8 rounded-full bg-accent-soft text-accent font-mono text-sm font-bold flex items-center justify-center shrink-0">
            2
          </span>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary">
            Opening Documents
          </h2>
        </div>

        <div className="pl-11 space-y-4 text-sm text-text-secondary leading-relaxed">
          <p>
            Lucid opens any standard Markdown (<code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">.md</code>, <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">.markdown</code>, <code className="font-mono text-xs px-1.5 py-0.5 rounded bg-surface-elevated text-accent">.mdown</code>) or plain text file.
          </p>
          <ul className="list-disc list-inside space-y-2 text-sm text-text-secondary">
            <li><strong className="text-text-primary">File Menu:</strong> Press <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs">⌘O</kbd> to choose any file from Finder.</li>
            <li><strong className="text-text-primary">Drag & Drop:</strong> Drag any Markdown file directly onto the Lucid Dock icon or an open window.</li>
            <li><strong className="text-text-primary">Terminal / CLI:</strong> Open documents from your terminal or shell scripts:</li>
          </ul>
          <div className="flex items-center justify-between">
            <span className="text-xs font-mono text-text-tertiary">Terminal invocation:</span>
            <CopyButton text={cliOpenCommand} label="Copy Command" />
          </div>
          <pre className="p-3 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg overflow-x-auto">
            {cliOpenCommand}
          </pre>
        </div>
      </section>

      {/* Step 3: View Modes */}
      <section id="modes" className="space-y-6">
        <div className="flex items-center gap-3">
          <span className="w-8 h-8 rounded-full bg-accent-soft text-accent font-mono text-sm font-bold flex items-center justify-center shrink-0">
            3
          </span>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary">
            Mastering the View Modes
          </h2>
        </div>

        <div className="pl-11 space-y-4 text-sm text-text-secondary leading-relaxed">
          <p>
            Lucid features three dedicated viewing modes tailored for different stages of document work:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-text-primary">Reader Mode</span>
                <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs">⌘1</kbd>
              </div>
              <p className="text-xs text-text-secondary">
                Distraction-free typographic view for deep reading, proofreading, and reviewing.
              </p>
            </div>
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-text-primary">Split Mode</span>
                <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs">⌘2</kbd>
              </div>
              <p className="text-xs text-text-secondary">
                Side-by-side editing with synchronized scrolling between raw source and rendered output.
              </p>
            </div>
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-text-primary">Editor Mode</span>
                <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs">⌘3</kbd>
              </div>
              <p className="text-xs text-text-secondary">
                Full-width plain-text editor with line numbers and focus mode support.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Step 4: Navigation */}
      <section id="navigation" className="space-y-6">
        <div className="flex items-center gap-3">
          <span className="w-8 h-8 rounded-full bg-accent-soft text-accent font-mono text-sm font-bold flex items-center justify-center shrink-0">
            4
          </span>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary">
            Navigation & Command
          </h2>
        </div>

        <div className="pl-11 space-y-4 text-sm text-text-secondary leading-relaxed">
          <ul className="space-y-3">
            <li className="p-4 rounded-window border border-border-subtle bg-surface flex items-start gap-4">
              <kbd className="px-2.5 py-1 rounded bg-surface-elevated border border-border-subtle font-mono text-xs shrink-0">
                ⌃⌘S
              </kbd>
              <div>
                <strong className="text-text-primary block mb-1">Outline Sidebar</strong>
                <span className="text-xs text-text-secondary">
                  Toggle the hierarchical heading tree. As you scroll through the document, scroll-spy automatically highlights the current heading in the sidebar.
                </span>
              </div>
            </li>
            <li className="p-4 rounded-window border border-border-subtle bg-surface flex items-start gap-4">
              <kbd className="px-2.5 py-1 rounded bg-surface-elevated border border-border-subtle font-mono text-xs shrink-0">
                ⌘F
              </kbd>
              <div>
                <strong className="text-text-primary block mb-1">In-Document Find</strong>
                <span className="text-xs text-text-secondary">
                  Opens the floating search bar. Navigate matches using <kbd className="font-mono text-xs">⌘G</kbd> (next) and <kbd className="font-mono text-xs">⇧⌘G</kbd> (previous).
                </span>
              </div>
            </li>
            <li className="p-4 rounded-window border border-border-subtle bg-surface flex items-start gap-4">
              <kbd className="px-2.5 py-1 rounded bg-surface-elevated border border-border-subtle font-mono text-xs shrink-0">
                ⌘K
              </kbd>
              <div>
                <strong className="text-text-primary block mb-1">Command Palette</strong>
                <span className="text-xs text-text-secondary">
                  Fuzzy search across all application actions: switch themes, toggle focus mode, jump between view modes, or trigger exports.
                </span>
              </div>
            </li>
          </ul>
        </div>
      </section>

      {/* Step 5: Export */}
      <section id="export" className="space-y-6">
        <div className="flex items-center gap-3">
          <span className="w-8 h-8 rounded-full bg-accent-soft text-accent font-mono text-sm font-bold flex items-center justify-center shrink-0">
            5
          </span>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary">
            Exporting & Sharing
          </h2>
        </div>

        <div className="pl-11 space-y-4 text-sm text-text-secondary leading-relaxed">
          <p>
            When your document is ready for distribution or presentation, use Lucid&apos;s export options from the <strong className="text-text-primary">File</strong> menu or the Command Palette (<kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle font-mono text-xs">⌘K</kbd>):
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <h3 className="font-semibold text-text-primary text-sm mb-1">Vector PDF</h3>
              <p className="text-xs text-text-secondary">
                Generates a clean vector PDF using WebKit&apos;s native print layout with headers, footers, and preserved vector typography.
              </p>
            </div>
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <h3 className="font-semibold text-text-primary text-sm mb-1">Standalone HTML</h3>
              <p className="text-xs text-text-secondary">
                Exports a self-contained HTML file with embedded CSS, math styling, and diagram assets.
              </p>
            </div>
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <h3 className="font-semibold text-text-primary text-sm mb-1">Formatted Rich Text</h3>
              <p className="text-xs text-text-secondary">
                Copies fully rendered HTML/RTF directly to your clipboard for pasting into Pages, Apple Mail, or Keynote.
              </p>
            </div>
            <div className="p-4 rounded-window border border-border-subtle bg-surface">
              <h3 className="font-semibold text-text-primary text-sm mb-1">Mermaid SVG Export</h3>
              <p className="text-xs text-text-secondary">
                Hover over any Mermaid diagram card and click the SVG button to export crisp vector diagrams.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Navigation Footer */}
      <div className="pt-12 border-t border-border-subtle flex flex-col md:flex-row items-center justify-between gap-4">
        <Link href="/docs" className="text-sm text-text-secondary hover:text-accent font-medium">
          ← Back to Documentation
        </Link>
        <Button variant="primary" size="md" href="/api/download">
          Download Lucid for macOS
        </Button>
      </div>
    </div>
  );
}
