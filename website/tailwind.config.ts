import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./lib/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        surface: "var(--surface)",
        "surface-elevated": "var(--surface-elevated)",
        "surface-hover": "var(--surface-hover)",
        "text-primary": "var(--text-primary)",
        "text-secondary": "var(--text-secondary)",
        "text-tertiary": "var(--text-tertiary)",
        "border-subtle": "var(--border-subtle)",
        "border-strong": "var(--border-strong)",
        accent: "var(--accent)",
        "accent-soft": "var(--accent-soft)",
        "code-bg": "var(--code-bg)",
        "code-fg": "var(--code-fg)",
        "code-border": "var(--code-border)",
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          '"SF Pro Text"',
          '"Inter"',
          "system-ui",
          "sans-serif",
        ],
        mono: [
          "ui-monospace",
          '"SFMono-Regular"',
          '"SF Mono"',
          "Menlo",
          "Monaco",
          "monospace",
        ],
        serif: ['"New York"', "Charter", '"Times New Roman"', "serif"],
      },
      maxWidth: {
        reading: "680px",
        prose: "760px",
        page: "1240px",
        breakout: "1400px",
      },
      borderRadius: {
        mac: "10px",
        window: "12px",
      },
      boxShadow: {
        subtle: "0 1px 2px rgba(0, 0, 0, 0.05)",
        window: "0 20px 40px -15px rgba(0, 0, 0, 0.25), 0 0 0 1px var(--border-subtle)",
        floating: "0 10px 30px -5px rgba(0, 0, 0, 0.2)",
      },
      transitionTimingFunction: {
        mac: "cubic-bezier(0.16, 1, 0.3, 1)",
      },
    },
  },
  plugins: [],
};

export default config;
