export interface ChangelogItem {
  type: "new" | "improved" | "fixed";
  text: string;
}

export interface ReleaseEntry {
  version: string;
  date: string;
  channel: "Stable" | "Beta" | "Preview";
  summary: string;
  highlights: string[];
  sections: {
    title: string;
    items: ChangelogItem[];
  }[];
}

export const changelogData: ReleaseEntry[] = [
  {
    version: "1.0.8",
    date: "October 3, 2026",
    channel: "Beta",
    summary: "Lucid 1.0.8 Public Beta delivers enhanced document safety, improved session recovery across tabs and windows, reliable relative image refreshing, and smoother sidebar interactions.",
    highlights: [
      "Editing and Undo/Redo stay strictly isolated to the displayed tab, even during rapid tab switching.",
      "Multi-tab and window session recovery retains unsaved edits in named files and separate windows, including drafts whose original file disappeared.",
      "Cancelling close or quit keeps every tab available; failed saves preserve unsaved text.",
      "Save follows same-volume file moves instead of recreating an abandoned filename, and prompts for a destination when the file cannot be identified.",
      "Local relative images refresh when switching documents, returning to replaced assets, or revealing the preview pane.",
      "Smoother sidebar toggles and resizing preserve filter text, editor focus, reading position, and find matches.",
    ],
    sections: [
      {
        title: "Session Recovery & Document Safety",
        items: [
          {
            type: "improved",
            text: "Recovery retains unsaved edits in named files and separate windows, including drafts whose original file disappeared.",
          },
          {
            type: "fixed",
            text: "Opening another file at launch preserves pending recovery windows and documents without data loss.",
          },
          {
            type: "fixed",
            text: "Cancelling close or quit keeps every tab available; failed saves preserve unsaved text without losing edits.",
          },
          {
            type: "improved",
            text: "Save follows same-volume file moves instead of recreating an abandoned filename, asking you to choose a destination when unresolved.",
          },
          {
            type: "fixed",
            text: "Saving and immediately continuing to type no longer triggers a false external-change alert.",
          },
        ],
      },
      {
        title: "Editing & Preview Fidelity",
        items: [
          {
            type: "improved",
            text: "Editing and Undo/Redo remain strictly isolated to the displayed tab, including during rapid tab switching.",
          },
          {
            type: "fixed",
            text: "Local relative images refresh accurately when switching tabs, returning to replaced assets, or revealing the preview pane.",
          },
          {
            type: "improved",
            text: "Smoother sidebar toggles and resizing preserve filter text, editor focus, reading position, and find matches.",
          },
          {
            type: "improved",
            text: "Multiple open windows resize their sidebars independently.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.1",
    date: "September 21, 2026",
    channel: "Beta",
    summary: "Patch release delivering smart adaptive Mermaid diagram fitting, smooth 1:1 diagram panning with visible grab/grabbing feedback, and stable Reader outline sidebar toggling without blank flashes.",
    highlights: [
      "Smart adaptive initial Mermaid layout: normal and medium diagrams display completely on first render when readable",
      "Mermaid Hand/Pan interaction: visible grab/grabbing cursor feedback, Pointer Events, and smooth 1:1 panning",
      "Sidebar stability: opening/closing the left outline sidebar preserves WKWebView identity with zero blank flash",
      "Huge diagrams retain readable typography with pan navigation, while Fit provides full-diagram overview and Reset restores smart initial view",
    ],
    sections: [
      {
        title: "Mermaid Improvements",
        items: [
          {
            type: "improved",
            text: "Smart adaptive initial diagram fitting: normal and medium diagrams now fit completely within the available viewing area on first render when doing so preserves readable typography (targeting ≥ 13.5px effective size).",
          },
          {
            type: "improved",
            text: "Dynamic bounded viewport height: diagram viewing area dynamically adapts up to min(840px, 80vh), eliminating vertical cropping of tall/normal diagrams while keeping huge diagrams comfortably bounded.",
          },
          {
            type: "improved",
            text: "Smooth Hand/Pan tool: visible grab cursor on hover, grabbing cursor during drag, Pointer Events with pointer capture, stable drag origin, and requestAnimationFrame transform coalescing.",
          },
          {
            type: "improved",
            text: "Small diagrams remain at natural 1.0x scale without blurry upscaling, while Reset reliably restores the exact smart initial view.",
          },
        ],
      },
      {
        title: "Reader Fixes",
        items: [
          {
            type: "fixed",
            text: "Fixed brief Reader content flash when opening/closing the outline sidebar by preserving the permanent AppKit HSplitView and WKWebView lifecycle.",
          },
          {
            type: "fixed",
            text: "Document scroll position, active heading spy, and Mermaid diagram transform states remain completely intact across sidebar toggles.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.0",
    date: "September 20, 2026",
    channel: "Beta",
    summary: "Initial public beta of Lucid for macOS — a quiet, native Markdown reader and editor built specifically for technical documents.",
    highlights: [
      "Native Swift & AppKit/WebKit architecture with floating glass toolbar",
      "Reader, Split, and Editor modes with synchronized document scrolling",
      "Offline KaTeX math, mhchem chemistry, and interactive Mermaid diagrams",
      "Heading outline sidebar with scroll-spy, in-document find, and Command Palette",
      "Export to vector PDF, standalone HTML, formatted rich text, and Mermaid SVG",
    ],
    sections: [
      {
        title: "New Features",
        items: [
          {
            type: "new",
            text: "Reader / Split / Editor modes (⌘1 / ⌘2 / ⌘3) providing focused consumption, live side-by-side editing, or distraction-free source writing.",
          },
          {
            type: "new",
            text: "Floating glass toolbar (NSVisualEffectView) that content scrolls beneath, with scroll-responsive depth and subtle translucency.",
          },
          {
            type: "new",
            text: "Offline KaTeX engine supporting both inline ($...$) and block ($$...$$) mathematical expressions.",
          },
          {
            type: "new",
            text: "Embedded mhchem engine for complex chemical reactions, battery electrochemistry, and stoichiometry (\\ce{...}).",
          },
          {
            type: "new",
            text: "Interactive Mermaid diagrams with Pan, Zoom (+ / −), Fit to viewport, Reset view, and Fullscreen Expand.",
          },
          {
            type: "new",
            text: "Mermaid SVG export and one-click SVG clipboard copy.",
          },
          {
            type: "new",
            text: "Fenced code blocks with syntax highlighting, language identifier badges, and one-click copy buttons.",
          },
          {
            type: "new",
            text: "Technical table rendering with alternating row contrast, readable headers, and horizontal scroll preservation.",
          },
          {
            type: "new",
            text: "GitHub and Obsidian style callout alerts: [!NOTE], [!TIP], [!IMPORTANT], [!WARNING], and [!CAUTION].",
          },
          {
            type: "new",
            text: "Live heading outline sidebar (⌃⌘S) with hierarchical indentation, active section scroll-spy, and real-time heading filter.",
          },
          {
            type: "new",
            text: "Floating Find in Document bar (⌘F) with next (⌘G) and previous (⇧⌘G) match navigation.",
          },
          {
            type: "new",
            text: "Command Palette (⌘K) for rapid fuzzy search across actions, themes, presets, and export options.",
          },
          {
            type: "new",
            text: "Focus Mode (⌘⇧D) to dim inactive paragraphs and concentrate on the active block.",
          },
          {
            type: "new",
            text: "Typewriter Mode to keep the active editing line vertically centered on the screen.",
          },
          {
            type: "new",
            text: "Curated themes: Lucid Studio Dark, Editorial Light, Warm Book Sepia, and System Dynamic.",
          },
          {
            type: "new",
            text: "Document export: vector PDF generation via native WebKit, standalone HTML export, and formatted rich-text clipboard copy.",
          },
        ],
      },
      {
        title: "Improvements & Polish",
        items: [
          {
            type: "improved",
            text: "Refined content top inset so the document's first heading clears the toolbar at rest and passes beneath it smoothly on scroll.",
          },
          {
            type: "improved",
            text: "Unified motion vocabulary across the application with disciplined transition durations and spring curves.",
          },
          {
            type: "improved",
            text: "Full accessibility awareness honoring system Reduce Motion, Reduce Transparency, and Increased Contrast preferences.",
          },
          {
            type: "improved",
            text: "Local-first security model: all rendering parsers, fonts, and engines are bundled locally with zero external network tracking.",
          },
        ],
      },
    ],
  },
];
