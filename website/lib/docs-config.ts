export interface DocSection {
  id: string;
  title: string;
  description: string;
  items: {
    title: string;
    href: string;
    summary: string;
  }[];
}

export const docsConfig = {
  title: "Lucid Documentation",
  description: "Guides, technical references, and workflow patterns for Lucid on macOS.",
  sections: [
    {
      id: "getting-started",
      title: "Getting Started",
      description: "Everything you need to begin using Lucid as your primary technical Markdown reader and editor.",
      items: [
        {
          title: "First Run & Overview",
          href: "/docs/getting-started#overview",
          summary: "Opening documents, navigating window chrome, and understanding document modes.",
        },
        {
          title: "The Three View Modes",
          href: "/docs/getting-started#modes",
          summary: "Reader (⌘1), Split (⌘2), and Editor (⌘3) mode workflows.",
        },
        {
          title: "Outline & Document Search",
          href: "/docs/getting-started#navigation",
          summary: "Navigating large files using the outline sidebar (⌃⌘S) and Find bar (⌘F).",
        },
        {
          title: "Command Palette & Shortcuts",
          href: "/docs/getting-started#shortcuts",
          summary: "Fuzzy action searching with ⌘K and canonical keyboard shortcuts.",
        },
      ],
    },
    {
      id: "technical-markdown",
      title: "Technical Markdown Guide",
      description: "How Lucid parses and renders complex STEM elements, diagrams, equations, and tables.",
      items: [
        {
          title: "Mathematical Notation (KaTeX)",
          href: "/docs#math",
          summary: "Inline ($...$) and block ($$...$$) math rendering with AMS symbols.",
        },
        {
          title: "Chemical Equations (mhchem)",
          href: "/docs#chemistry",
          summary: "Writing stoichiometry, electrochemistry, and reaction arrows with \\ce{...}.",
        },
        {
          title: "Mermaid Diagrams & Controls",
          href: "/docs#mermaid",
          summary: "Flowcharts, sequence diagrams, pan/zoom interaction, and SVG export.",
        },
        {
          title: "Code Blocks & Highlighting",
          href: "/docs#code",
          summary: "Syntax highlighting, ASCII diagram detection, and language tags.",
        },
        {
          title: "Tables & Data Layout",
          href: "/docs#tables",
          summary: "Header formatting, alignment, wide tables, and horizontal scrolling.",
        },
        {
          title: "Callout Alerts",
          href: "/docs#alerts",
          summary: "GitHub & Obsidian alerts: [!NOTE], [!TIP], [!IMPORTANT], [!WARNING], [!CAUTION].",
        },
      ],
    },
    {
      id: "export-workflow",
      title: "Export & Workflows",
      description: "Integrating Lucid with external editors and exporting publication-ready documents.",
      items: [
        {
          title: "Exporting to Vector PDF",
          href: "/docs#export-pdf",
          summary: "Generating clean vector PDFs via native WebKit printing.",
        },
        {
          title: "Standalone HTML Export",
          href: "/docs#export-html",
          summary: "Exporting self-contained HTML documents.",
        },
        {
          title: "Formatted Rich Text Copy",
          href: "/docs#export-richtext",
          summary: "Copying rendered HTML directly into Keynote, Mail, or Pages.",
        },
        {
          title: "Live File Watching",
          href: "/docs#file-watching",
          summary: "Using Lucid alongside external editors like Neovim, VS Code, or Obsidian.",
        },
      ],
    },
  ] as DocSection[],
};
