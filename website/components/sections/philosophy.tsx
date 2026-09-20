import React from "react";

export function PhilosophySection() {
  return (
    <section className="py-20 sm:py-28">
      <div className="max-w-reading mx-auto px-4 sm:px-6 space-y-6">
        <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
          Product Philosophy
        </span>

        <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-text-primary leading-snug">
          Markdown is simple. Technical Markdown is&nbsp;not.
        </h2>

        <div className="space-y-4 text-base sm:text-lg text-text-secondary leading-relaxed">
          <p>
            The moment a technical document contains mathematical equations, state diagrams, wide data tables, syntax-highlighted code blocks, and callout alerts, most Markdown tools begin to feel like a generic browser with a stylesheet.
          </p>
          <p>
            Equations clip against narrow margins. Diagrams shrink until labels become unreadable. Wide tables overflow awkwardly. And editing requires constantly jumping between disparate windows.
          </p>
          <p className="text-text-primary font-medium">
            Lucid is built so that complexity stays in the document — not in the reading experience.
          </p>
        </div>
      </div>
    </section>
  );
}
