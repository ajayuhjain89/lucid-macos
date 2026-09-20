import React from "react";
import { CopyButton } from "@/components/ui/copy-button";

export function TechnicalShowcaseSection() {
  const pythonCode = `import numpy as np
from scipy import signal

# State-Space System Matrices
A = np.array([[0, 1], [-2, -3]])
B = np.array([[0], [1]])
C = np.array([[1, 0]])
D = np.array([[0]])

# Desired Closed-Loop Pole Locations
desired_poles = np.array([-2.0 + 2.0j, -2.0 - 2.0j])
K = signal.place_poles(A, B, desired_poles).gain_matrix

print(f"Computed State-Feedback Gain K: {K}")`;

  return (
    <section id="technical-markdown" className="py-20 sm:py-28">
      <div className="max-w-page mx-auto px-4 sm:px-6">
        {/* Section Header */}
        <div className="max-w-3xl mb-12 space-y-3">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            STEM & Technical Markdown
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            One document. Coherent reading.
          </h2>
          <p className="text-base text-text-secondary leading-relaxed">
            Equations, chemical formulas, wide tables, code blocks, and callout alerts belong in the same document. Lucid renders them with publication-level typographic harmony.
          </p>
        </div>

        {/* Live Document Canvas Preview */}
        <div className="rounded-window border border-border-strong bg-surface p-6 sm:p-10 shadow-sm space-y-8 font-sans">
          {/* Document Heading & Prose */}
          <div className="space-y-3 border-b border-border-subtle pb-6">
            <h3 className="text-2xl font-bold tracking-tight text-text-primary">
              1. Control Systems &amp; Lithium-Ion Electrochemistry
            </h3>
            <p className="text-sm sm:text-base text-text-secondary leading-relaxed max-w-prose">
              During rapid charging and discharging cycles, lithium ions intercalate between the cathode and anode. In Lucid, chemical equations written with <code className="px-1.5 py-0.5 rounded text-xs font-mono bg-code-bg border border-border-subtle text-accent">\ce{`{...}`}</code> and mathematical notations are rendered cleanly in-line:
            </p>
          </div>

          {/* Rendered Math & Chemistry Block */}
          <div className="p-6 rounded-[8px] bg-background/60 border border-border-subtle text-center space-y-4 overflow-x-auto">
            <div className="text-xs font-mono text-text-tertiary uppercase tracking-wider mb-2">
              mhchem &amp; KaTeX Output
            </div>
            <div className="text-base sm:text-xl font-serif text-text-primary tracking-wide">
              <span>LiCoO₂ + 6C</span>
              <span className="mx-3 text-text-secondary">⇄</span>
              <span>Li₁₋ₓCoO₂ + LiₓC₆</span>
              <span className="ml-4 text-xs font-mono text-text-tertiary">(E° ≈ 3.9 V vs. Li/Li⁺)</span>
            </div>
            <div className="text-sm font-serif text-text-secondary flex items-center justify-center gap-4 flex-wrap">
              <span>
                <strong className="font-bold font-serif">G</strong>(<em>s</em>) = <strong className="font-bold font-serif">C</strong>(<em>s</em><strong className="font-bold font-serif">I</strong> − <strong className="font-bold font-serif">A</strong>)⁻¹<strong className="font-bold font-serif">B</strong> + <strong className="font-bold font-serif">D</strong>
              </span>
              <span className="text-text-tertiary hidden sm:inline">•</span>
              <span>
                ∇ × <strong className="font-bold font-serif">E</strong> = −∂<strong className="font-bold font-serif">B</strong> / ∂<em>t</em>
              </span>
            </div>
          </div>

          {/* Code Block with Header & Copy */}
          <div className="rounded-[8px] border border-code-border bg-code-bg overflow-hidden">
            <div className="flex items-center justify-between px-4 py-2 border-b border-code-border bg-black/10 dark:bg-black/20 text-xs font-mono">
              <span className="text-text-tertiary font-semibold uppercase">PYTHON</span>
              <CopyButton text={pythonCode} label="Copy" />
            </div>
            <pre className="p-4 text-xs sm:text-sm font-mono text-code-fg overflow-x-auto leading-relaxed">
              <code>{pythonCode}</code>
            </pre>
          </div>

          {/* Technical Data Table */}
          <div className="space-y-2">
            <div className="text-xs font-mono text-text-tertiary uppercase tracking-wider">
              Differential &amp; Integral Formulations
            </div>
            <div className="overflow-x-auto border border-border-subtle rounded-[8px]">
              <table className="w-full text-left text-xs sm:text-sm">
                <thead className="bg-surface-elevated border-b border-border-subtle text-text-primary font-semibold">
                  <tr>
                    <th className="px-4 py-2.5">Differential Form</th>
                    <th className="px-4 py-2.5">Integral Form</th>
                    <th className="px-4 py-2.5">Physical Law</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-subtle text-text-secondary font-mono">
                  <tr className="hover:bg-surface-hover">
                    <td className="px-4 py-2">∇ · E = ρ / ε₀</td>
                    <td className="px-4 py-2">∮ E · dA = Q_enc / ε₀</td>
                    <td className="px-4 py-2 font-sans text-text-primary">Gauss&apos;s Law</td>
                  </tr>
                  <tr className="hover:bg-surface-hover">
                    <td className="px-4 py-2">∇ · B = 0</td>
                    <td className="px-4 py-2">∮ B · dA = 0</td>
                    <td className="px-4 py-2 font-sans text-text-primary">Gauss&apos;s Law for Magnetism</td>
                  </tr>
                  <tr className="hover:bg-surface-hover">
                    <td className="px-4 py-2">∇ × E = -∂B / ∂t</td>
                    <td className="px-4 py-2">∮ E · dl = -dΦ_B / dt</td>
                    <td className="px-4 py-2 font-sans text-text-primary">Faraday&apos;s Law of Induction</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Callout Alert */}
          <div className="p-4 rounded-[8px] border-l-4 border-accent bg-accent-soft/40 space-y-1 text-xs sm:text-sm">
            <div className="flex items-center gap-2 font-semibold text-text-primary">
              <svg className="w-4 h-4 text-accent" viewBox="0 0 16 16" fill="currentColor">
                <path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8Zm8-6.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13ZM6.5 7.75A.75.75 0 0 1 7.25 7h1a.75.75 0 0 1 .75.75v2.75h.25a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5h.25v-2h-.25a.75.75 0 0 1-.75-.75ZM8 6a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z" />
              </svg>
              <span>[!NOTE] Offline Native Execution</span>
            </div>
            <p className="text-text-secondary leading-relaxed pl-6">
              All equation and formula rendering runs locally via bundled KaTeX and mhchem WebEngine modules. No external network requests are made.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
