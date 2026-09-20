export interface NavItem {
  label: string;
  href: string;
  external?: boolean;
}

export const siteConfig = {
  name: "Lucid",
  tagline: "Markdown, made lucid.",
  subheading: "A quiet, native macOS Markdown reader & editor built for technical documents — with beautiful code, math, Mermaid diagrams, chemistry, tables, and more.",
  description: "Lucid is a native macOS Markdown reader and editor designed for technical documents with offline KaTeX equations, mhchem chemistry, Mermaid diagrams, wide tables, syntax highlighting, and an editorial reading canvas.",
  siteUrl: process.env.NEXT_PUBLIC_SITE_URL || "https://lucid.app",
  githubUrl: "https://github.com/ajayuhjain89/lucid-macos",
  author: {
    name: "Ayush Jain",
    url: "https://github.com/ajayuhjain89",
  },
  license: {
    name: "MIT License",
    url: "https://github.com/ajayuhjain89/lucid-macos/blob/main/LICENSE",
  },
  nav: [
    { label: "Features", href: "/features" },
    { label: "Docs", href: "/docs" },
    { label: "Changelog", href: "/changelog" },
    { label: "Download", href: "/download" },
  ] as NavItem[],
  footerLinks: {
    product: [
      { label: "Features", href: "/features" },
      { label: "Download", href: "/download" },
      { label: "Changelog", href: "/changelog" },
    ],
    resources: [
      { label: "Documentation", href: "/docs" },
      { label: "Getting Started", href: "/docs/getting-started" },
      { label: "Support & Help", href: "/support" },
    ],
    legal: [
      { label: "Privacy Policy", href: "/privacy" },
    ],
  },
};
