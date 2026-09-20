import React from "react";

export function PlatformStrip() {
  const points = [
    {
      title: "Swift & WebKit",
      description: "Native macOS binary without Electron or bundled Chromium.",
    },
    {
      title: "Local-First Privacy",
      description: "Documents stay on your Mac. Zero telemetry or network tracking.",
    },
    {
      title: "Offline STEM Engine",
      description: "KaTeX, mhchem, and Mermaid bundled directly into the app.",
    },
    {
      title: "Apple Silicon Native",
      description: "Engineered specifically for arm64 performance and battery life.",
    },
  ];

  return (
    <div className="w-full border-y border-border-subtle bg-surface/40 py-8">
      <div className="max-w-page mx-auto px-4 sm:px-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 sm:gap-8">
          {points.map((point) => (
            <div key={point.title} className="space-y-1">
              <h3 className="text-sm font-semibold text-text-primary">
                {point.title}
              </h3>
              <p className="text-xs text-text-secondary leading-relaxed">
                {point.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
