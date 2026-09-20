import React from "react";
import { WindowFrame } from "@/components/ui/window-frame";

export function MermaidFeatureSection() {
  const controls = [
    { name: "Pan Tool", description: "Drag and inspect large architecture diagrams without selecting text." },
    { name: "Zoom In / Out", description: "Continuous precision zoom (+15% / −13%) for deep node inspection." },
    { name: "Fit Viewport", description: "Quickly scale complex multi-layer graphs to the document frame." },
    { name: "Reset View", description: "Instantly return to the calibrated, 1:1 readable baseline view." },
    { name: "Copy & Export SVG", description: "Export crisp vector SVGs for presentations, documentation, and Keynote." },
  ];

  return (
    <section id="mermaid" className="py-20 sm:py-28 border-t border-border-subtle bg-surface/20">
      <div className="max-w-page mx-auto px-4 sm:px-6 space-y-12">
        {/* Section Header */}
        <div className="max-w-3xl space-y-3">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            Architecture &amp; Flowcharts
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Diagrams you can actually read.
          </h2>
          <p className="text-base text-text-secondary leading-relaxed">
            Standard Markdown tools shrink wide diagrams until labels become unreadable micro-text. Lucid prioritizes human readability: diagrams render at full typographic scale, with dedicated pan, zoom, fit, and SVG export controls.
          </p>
        </div>

        {/* Real Screenshot showing the readable Mermaid rendering */}
        <div className="max-w-5xl mx-auto">
          <WindowFrame
            src="/images/app/mermaid-diagram.png"
            alt="Lucid Reader rendering a wide, readable Mermaid aerospace telemetry and control architecture flowchart"
            title="Telemetry_Architecture.md — Lucid Reader"
            width={2200}
            height={1700}
            allowExpand={true}
            caption="Real screenshot of Lucid rendering a complex multi-node architecture diagram at full readable scale with interactive navigation toolbar."
          />
        </div>

        {/* Feature controls grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-6 pt-4 border-t border-border-subtle">
          {controls.map((ctrl) => (
            <div key={ctrl.name} className="space-y-1">
              <h4 className="text-xs font-semibold text-text-primary font-mono">
                {ctrl.name}
              </h4>
              <p className="text-xs text-text-secondary leading-relaxed">
                {ctrl.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
