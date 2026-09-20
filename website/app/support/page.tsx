import type { Metadata } from "next";
import Link from "next/link";
import { siteConfig } from "@/lib/site-config";
import { Button } from "@/components/ui/button";

export const metadata: Metadata = {
  title: "Support & Troubleshooting — Lucid",
  description: "Get help with installing Lucid, resolving Gatekeeper prompts, reporting bugs, and troubleshooting Markdown rendering.",
};

const commonIssues = [
  {
    id: "gatekeeper",
    question: "How do I open Lucid if macOS Gatekeeper blocks it?",
    answer: "Because Lucid is in public beta and ad-hoc signed, macOS Gatekeeper may warn that the developer cannot be verified.",
    solution: (
      <div className="space-y-2 text-xs">
        <p><strong>Option 1 (Finder):</strong> Right-click (or Control-click) <code className="font-mono bg-surface-elevated px-1 py-0.5 rounded text-accent">Lucid.app</code> in Applications, select <strong>Open</strong>, and click <strong>Open</strong> in the dialog.</p>
        <p><strong>Option 2 (System Settings):</strong> If macOS still blocks the app, open <strong>System Settings → Privacy &amp; Security</strong>, scroll to the Security section, and click <strong>Open Anyway</strong> next to the message about Lucid.</p>
      </div>
    ),
  },
  {
    id: "intel-macs",
    question: "Does Lucid run on Intel (x86_64) Macs?",
    answer: "Lucid is currently compiled natively for Apple Silicon (arm64: M1, M2, M3, M4). Native Intel (x86_64) builds are planned for an upcoming release. In the meantime, you can compile Lucid from source on Intel Macs if Xcode is installed.",
    solution: (
      <div className="text-xs">
        <p>To compile from source on Intel: clone the repository and run <code className="font-mono bg-surface-elevated px-1 py-0.5 rounded text-accent">./build.sh</code>.</p>
      </div>
    ),
  },
  {
    id: "math-rendering",
    question: "Why isn't my KaTeX math or mhchem equation rendering?",
    answer: "Make sure you are using standard LaTeX delimiters without trailing spaces:",
    solution: (
      <div className="space-y-1.5 text-xs">
        <p>• <strong>Inline math:</strong> Use single dollar signs: <code className="font-mono bg-surface-elevated px-1 py-0.5 rounded text-accent">$E = mc^2$</code> (avoid space between <code className="font-mono">$</code> and content).</p>
        <p>• <strong>Block math:</strong> Use double dollar signs on separate lines:</p>
        <pre className="p-2 rounded bg-code-bg border border-code-border font-mono text-[11px] text-code-fg">
          {"$$\n\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}\n$$"}
        </pre>
        <p>• <strong>Chemistry:</strong> Use <code className="font-mono bg-surface-elevated px-1 py-0.5 rounded text-accent">\ce&#123;2H2 + O2 -&gt; 2H2O&#125;</code> inside math delimiters or as a standalone block.</p>
      </div>
    ),
  },
  {
    id: "file-watching",
    question: "Does Lucid update automatically when I edit files in Neovim or VS Code?",
    answer: "Yes. Lucid monitors open documents on disk via native macOS file-system events. When an external editor writes changes to the file, Lucid automatically re-renders the document while preserving your current scroll position.",
  },
];

export default function SupportPage() {
  return (
    <div className="py-16 md:py-24 px-6 md:px-12 max-w-4xl mx-auto space-y-16">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border-subtle bg-surface text-xs font-mono text-text-secondary mb-6">
          <span>Help & Support</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-semibold tracking-tight text-text-primary mb-4">
          Support & Troubleshooting
        </h1>
        <p className="text-lg text-text-secondary leading-relaxed">
          Find answers to common questions or reach out to the open-source community.
        </p>
      </div>

      {/* Common Issues */}
      <div className="space-y-6">
        <h2 className="text-xl font-semibold tracking-tight text-text-primary">
          Frequently Answered Questions
        </h2>
        <div className="space-y-4">
          {commonIssues.map((issue) => (
            <div
              key={issue.id}
              id={issue.id}
              className="p-6 rounded-window border border-border-subtle bg-surface space-y-3 scroll-mt-24"
            >
              <h3 className="font-semibold text-text-primary text-base">
                {issue.question}
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed">
                {issue.answer}
              </p>
              {issue.solution && (
                <div className="pt-2">
                  {issue.solution}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* GitHub Community Channels */}
      <div className="p-8 rounded-window border border-border-subtle bg-surface space-y-6">
        <div>
          <h2 className="text-xl font-semibold tracking-tight text-text-primary mb-2">
            Need Further Assistance?
          </h2>
          <p className="text-sm text-text-secondary leading-relaxed">
            Lucid is developed openly on GitHub. You can report bugs, submit feature requests, or participate in architectural discussions.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 rounded bg-surface-elevated border border-border-subtle space-y-2">
            <h3 className="font-semibold text-text-primary text-sm">Report a Bug</h3>
            <p className="text-xs text-text-secondary">
              Encountered unexpected behavior or a rendering glitch? Open an issue with a sample Markdown snippet.
            </p>
            <Button
              variant="secondary"
              size="sm"
              href={`${siteConfig.githubUrl}/issues`}
              external
              className="mt-2"
            >
              Open GitHub Issue
            </Button>
          </div>

          <div className="p-4 rounded bg-surface-elevated border border-border-subtle space-y-2">
            <h3 className="font-semibold text-text-primary text-sm">Documentation</h3>
            <p className="text-xs text-text-secondary">
              Review full guides on keyboard shortcuts, Mermaid diagrams, view modes, and export settings.
            </p>
            <Button
              variant="secondary"
              size="sm"
              href="/docs"
              className="mt-2"
            >
              Browse Documentation
            </Button>
          </div>
        </div>
      </div>

      {/* Navigation Footer */}
      <div className="text-center pt-8 border-t border-border-subtle">
        <Link href="/" className="text-sm text-text-secondary hover:text-accent font-medium">
          ← Back to Lucid Home
        </Link>
      </div>
    </div>
  );
}
