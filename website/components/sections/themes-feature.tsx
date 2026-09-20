"use client";

import React, { useState } from "react";
import Image from "next/image";

export function ThemesFeatureSection() {
  const [activeTheme, setActiveTheme] = useState<"dark" | "light" | "sepia">("dark");

  const themes = [
    {
      id: "dark" as const,
      name: "Lucid Studio Dark",
      eyebrow: "Default Theme",
      bgHex: "#171717",
      image: "/images/app/reader-dark.png",
      description: "Calibrated graphite surfaces (#171717) with balanced contrast to prevent eye strain during nocturnal engineering sessions.",
    },
    {
      id: "light" as const,
      name: "Lucid Editorial Light",
      eyebrow: "Daylight Reading",
      bgHex: "#fafafa",
      image: "/images/app/reader-light.png",
      description: "Crisp daylight paper tone (#fafafa) paired with deep neutral typography and subtle warm-cool depth.",
    },
    {
      id: "sepia" as const,
      name: "Warm Book Sepia",
      eyebrow: "Long-form Reading",
      bgHex: "#fcf8f2",
      image: "/images/app/reader-sepia.png",
      description: "Relaxing book paper tone (#fcf8f2) with warm ink contrast, designed for deep reading of long-form papers and specifications.",
    },
  ];

  const currentTheme = themes.find((t) => t.id === activeTheme) || themes[0];

  return (
    <section id="themes" className="py-20 sm:py-28 border-t border-border-subtle">
      <div className="max-w-page mx-auto px-4 sm:px-6 space-y-12">
        <div className="max-w-3xl space-y-3">
          <span className="text-[11px] font-semibold uppercase tracking-widest text-text-tertiary font-mono">
            Curated Typography &amp; Surfaces
          </span>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary leading-tight">
            Curated for focus. Configurable when needed.
          </h2>
          <p className="text-base text-text-secondary leading-relaxed">
            Lucid provides meticulously calibrated themes — not just inverted colors. Each theme balances contrast, syntax colors, table rules, and math rendering for its ambient environment.
          </p>
        </div>

        {/* Theme Switcher Tabs */}
        <div className="flex flex-wrap items-center gap-2 p-1.5 rounded-[10px] bg-surface border border-border-subtle max-w-fit">
          {themes.map((t) => (
            <button
              key={t.id}
              onClick={() => setActiveTheme(t.id)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-[7px] text-xs font-medium transition-all ${
                activeTheme === t.id
                  ? "bg-surface-elevated text-text-primary shadow-sm border border-border-strong"
                  : "text-text-secondary hover:text-text-primary"
              }`}
            >
              <span
                className="w-3 h-3 rounded-full border border-black/10 dark:border-white/10"
                style={{ backgroundColor: t.bgHex }}
              />
              <span>{t.name}</span>
            </button>
          ))}
        </div>

        {/* Screenshot of current theme */}
        <div className="rounded-window overflow-hidden border border-border-strong bg-surface shadow-window transition-all duration-300">
          <div className="flex items-center justify-between px-3.5 py-2.5 bg-surface border-b border-border-subtle">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-[#ff5f56]/80" />
              <span className="w-3 h-3 rounded-full bg-[#ffbd2e]/80" />
              <span className="w-3 h-3 rounded-full bg-[#27c93f]/80" />
            </div>
            <div className="text-[11px] font-medium text-text-tertiary font-mono">
              Theme: {currentTheme.name}
            </div>
            <div className="w-12" />
          </div>

          <div className="relative w-full aspect-[4/3] bg-surface">
            <Image
              src={currentTheme.image}
              alt={`Lucid Reader in ${currentTheme.name}`}
              width={2080}
              height={1560}
              className="w-full h-full object-cover object-top"
              sizes="(max-width: 1280px) 100vw, 1200px"
            />
          </div>
        </div>

        {/* Customization callout */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pt-4 border-t border-border-subtle">
          <div className="space-y-1.5">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-text-primary font-mono">
              Typography &amp; Scale
            </h4>
            <p className="text-xs text-text-secondary leading-relaxed">
              Adjust base font size (⌘+, ⌘-, ⌘0), line height, reading column width, and monospaced code sizing from Settings (⌘,).
            </p>
          </div>
          <div className="space-y-1.5">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-text-primary font-mono">
              Focus &amp; Typewriter Modes
            </h4>
            <p className="text-xs text-text-secondary leading-relaxed">
              Dim inactive blocks with Focus Mode (⌘⇧D) or keep your active cursor vertically centered with Typewriter Mode.
            </p>
          </div>
          <div className="space-y-1.5">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-text-primary font-mono">
              Accents &amp; Presets
            </h4>
            <p className="text-xs text-text-secondary leading-relaxed">
              Personalize your interactive accent color and apply curated density presets (Compact, Default, Comfortable) instantly.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
