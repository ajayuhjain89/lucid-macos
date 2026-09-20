import type { Metadata } from "next";
import Link from "next/link";
import { docsConfig } from "@/lib/docs-config";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Documentation & Technical Reference",
  description: "Guides, syntax references, keyboard shortcuts, and workflow patterns for Lucid on macOS.",
};

const shortcuts = [
  { key: "⌘1", action: "Reader Mode", description: "Switch to distraction-free reading canvas" },
  { key: "⌘2", action: "Split Mode", description: "Side-by-side editing and synchronized preview" },
  { key: "⌘3", action: "Editor Mode", description: "Focus on raw Markdown source editing" },
  { key: "⌃⌘S", action: "Toggle Outline", description: "Open or close hierarchical heading outline sidebar" },
  { key: "⌘F", action: "Find in Document", description: "Open floating in-document search bar" },
  { key: "⌘G", action: "Find Next", description: "Jump to the next search match" },
  { key: "⇧⌘G", action: "Find Previous", description: "Jump to the previous search match" },
  { key: "⌘K", action: "Command Palette", description: "Open fuzzy command palette for actions and themes" },
  { key: "⌘⇧D", action: "Focus Mode", description: "Dim inactive paragraphs while writing" },
  { key: "⌘+", action: "Zoom In", description: "Increase canvas typography scale" },
  { key: "⌘-", action: "Zoom Out", description: "Decrease canvas typography scale" },
  { key: "⌘0", action: "Actual Size", description: "Reset typography scale to 100%" },
  { key: "⌘,", action: "Settings", description: "Open application preferences" },
];

const syntaxExamples = [
  {
    title: "Inline & Block Math (KaTeX)",
    description: "Render AMS mathematical equations using standard TeX syntax.",
    code: "$E = mc^2$\n\n$$\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}$$",
  },
  {
    title: "Chemical Equations (mhchem)",
    description: "Typeset chemical formulas, charges, and reaction equilibria.",
    code: "\\ce{2H2 + O2 -> 2H2O}\n\n\\ce{LiCoO2 <=> Li_{1-x}CoO2 + xLi+ + xe-}",
  },
  {
    title: "Callout Alerts",
    description: "Highlight notes, tips, and warnings using GitHub & Obsidian syntax.",
    code: "> [!NOTE]\n> Useful context or non-blocking information.\n\n> [!WARNING]\n> Critical notices requiring attention.",
  },
  {
    title: "Mermaid Diagrams",
    description: "Write flowcharts and diagrams with full pan, zoom, and SVG export.",
    code: "```mermaid\ngraph TD\n  Client[AppKit Frontend] --> Bridge[WKScriptMessageHandler]\n  Bridge --> Engine[Local WebEngine]\n```",
  },
];

export default function DocsPage() {
  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-5xl mx-auto space-y-20">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>Documentation</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Lucid Documentation
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          Technical references, keyboard shortcuts, and guides for getting the most out of Lucid.
        </p>
      </div>

      {/* Guide Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {docsConfig.sections.map((section) => (
          <div
            key={section.id}
            className="p-6 rounded-window border border-border-subtle bg-surface flex flex-col justify-between"
          >
            <div>
              <h2 className="text-lg font-semibold text-text-primary mb-2">
                {section.title}
              </h2>
              <p className="text-sm text-text-secondary mb-6">
                {section.description}
              </p>
              <ul className="space-y-2.5 mb-6">
                {section.items.map((item) => (
                  <li key={item.title}>
                    <Link
                      href={item.href}
                      className="text-xs text-text-primary hover:text-accent flex items-center gap-1.5 transition-colors"
                    >
                      <span className="text-text-tertiary">›</span>
                      <span>{item.title}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
            {section.id === "getting-started" && (
              <Button variant="secondary" size="sm" href="/docs/getting-started">
                Read Guide →
              </Button>
            )}
          </div>
        ))}
      </div>

      {/* Keyboard Shortcuts Reference */}
      <section id="shortcuts" className="space-y-6 pt-12 border-t border-border-subtle scroll-mt-20">
        <div>
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            Reference
          </div>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary mb-2">
            Keyboard Shortcuts
          </h2>
          <p className="text-sm text-text-secondary">
            Canonical shortcuts verified against Lucid&apos;s native macOS command menu.
          </p>
        </div>

        <div className="rounded-window border border-border-subtle bg-surface overflow-hidden">
          <table className="w-full text-left text-sm">
            <thead className="bg-surface-elevated border-b border-border-subtle text-xs font-mono uppercase tracking-wider text-text-secondary">
              <tr>
                <th className="py-3 px-4 font-semibold">Shortcut</th>
                <th className="py-3 px-4 font-semibold">Action</th>
                <th className="py-3 px-4 font-semibold">Description</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {shortcuts.map((sc) => (
                <tr key={sc.key} className="hover:bg-surface-hover transition-colors">
                  <td className="py-3 px-4 font-mono font-semibold text-accent">
                    <kbd className="px-2 py-0.5 rounded bg-surface-elevated border border-border-subtle text-xs">
                      {sc.key}
                    </kbd>
                  </td>
                  <td className="py-3 px-4 font-medium text-text-primary">
                    {sc.action}
                  </td>
                  <td className="py-3 px-4 text-text-secondary">
                    {sc.description}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* Markdown Syntax Reference */}
      <section id="syntax" className="space-y-6 pt-12 border-t border-border-subtle scroll-mt-20">
        <div>
          <div className="text-xs font-mono uppercase tracking-wider text-accent mb-2">
            Syntax Cheat Sheet
          </div>
          <h2 className="text-2xl font-semibold tracking-tight text-text-primary mb-2">
            Technical Markdown Syntax
          </h2>
          <p className="text-sm text-text-secondary">
            Supported extensions for mathematics, chemistry, callouts, and diagrams.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {syntaxExamples.map((ex) => (
            <div key={ex.title} className="p-6 rounded-window border border-border-subtle bg-surface space-y-3">
              <h3 className="font-semibold text-text-primary">{ex.title}</h3>
              <p className="text-xs text-text-secondary">{ex.description}</p>
              <pre className="p-3 rounded bg-code-bg border border-code-border font-mono text-xs text-code-fg overflow-x-auto whitespace-pre">
                {ex.code}
              </pre>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
