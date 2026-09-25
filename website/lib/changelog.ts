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
    version: "1.0.5",
    date: "September 25, 2026",
    channel: "Beta",
    summary: "Lucid 1.0.5 Public Beta delivers persistent reading positions across view modes, independent multi-window state, enhanced vector PDF and HTML export, Markdown footnotes, and major preview rendering and theme-switch performance optimizations.",
    highlights: [
      "Persistent Reading Position & Pane State: Switching between Reader, Editor, and Split view modes preserves your exact reading anchor and cursor position.",
      "Independent Multi-Window Controls: Each window maintains its own view mode, sidebar visibility, and Focus Mode independently.",
      "Enhanced Export Capabilities: Export beautifully paginated vector PDFs and self-contained HTML directly from any view mode.",
      "Markdown Footnotes Support: Render linked footnote references and an organized footnotes section automatically.",
      "Block-Level Preview Performance: Live preview updates only re-render modified blocks with capped typing debounce, eliminating editor restyling lag.",
    ],
    sections: [
      {
        title: "Navigation & View Modes",
        items: [
          {
            type: "new",
            text: "Preserved reading position and pane state across Reader, Editor, and Split view switches without jumping to the top.",
          },
          {
            type: "new",
            text: "Independent multi-window states: each document window maintains its own view mode, sidebar toggle state, and Focus Mode.",
          },
          {
            type: "improved",
            text: "Smoother sidebar transitions with directional hysteresis and sub-pixel deadband to eliminate outline flickering while scrolling.",
          },
          {
            type: "improved",
            text: "Native macOS View menu integration with synchronized checkmarks for display modes and layout options.",
          },
          {
            type: "fixed",
            text: "Fixed Split mode editor starting at the top of the document when opened.",
          },
        ],
      },
      {
        title: "Markdown & Rendering Engine",
        items: [
          {
            type: "new",
            text: "Markdown footnotes: render linked footnote numbers and an organized footnotes section at the bottom of the document.",
          },
          {
            type: "improved",
            text: "Block-level incremental preview rendering: typing now only re-renders modified blocks, eliminating editor lag.",
          },
          {
            type: "improved",
            text: "Serialized Mermaid diagram theme rendering with WebKit yielding and theme-cached SVGs for smooth theme switches.",
          },
          {
            type: "improved",
            text: "Mermaid syntax error presentation: unrecoverable syntax errors cleanly display reader-facing error cards without breaking the document.",
          },
          {
            type: "fixed",
            text: "Fixed outline navigation and heading ID parity for Unicode and duplicate headings.",
          },
          {
            type: "fixed",
            text: "In-page Find now avoids highlighting hidden markup inside Mermaid diagrams and KaTeX formulas.",
          },
          {
            type: "fixed",
            text: "Fixed long unbroken words overflowing preview margins.",
          },
        ],
      },
      {
        title: "Editor & Workflows",
        items: [
          {
            type: "new",
            text: "Focus Mode and Typewriter Mode support within the Editor view.",
          },
          {
            type: "new",
            text: "Paginated vector PDF and self-contained offline HTML export directly from any view mode (Reader, Editor, or Split).",
          },
          {
            type: "improved",
            text: "Support for opening UTF-16 and legacy 8-bit encoded text files alongside UTF-8.",
          },
          {
            type: "improved",
            text: "Responsive Settings Editor tab layout with compact font pickers and single-window reuse.",
          },
          {
            type: "fixed",
            text: "Command Palette immediately focuses the search field on open and returns focus upon dismissal.",
          },
          {
            type: "fixed",
            text: "Toolbar depth: document content scrolled beneath the floating glass toolbar is properly clipped.",
          },
        ],
      },
      {
        title: "Security & Quality",
        items: [
          {
            type: "improved",
            text: "Enforced strict Content-Security-Policy (CSP) on the Markdown preview and removed inline event handlers.",
          },
          {
            type: "improved",
            text: "Local image paths are sandboxed through the custom lucid-asset: URL scheme.",
          },
          {
            type: "improved",
            text: "STEM features (KaTeX, Mermaid, syntax highlighting, mhchem) are strictly gated by user preferences.",
          },
          {
            type: "improved",
            text: "Added descriptive accessibility labels for theme, accent, and workflow preset controls in Settings.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.4",
    date: "September 22, 2026",
    channel: "Beta",
    summary: "Lucid 1.0.4 Public Beta improves Mermaid diagram rendering compatibility for flowcharts containing mathematical notation and delivers the first in-app update via Sparkle.",
    highlights: [
      "Mermaid flowchart compatibility: diagrams with parenthesized math labels such as r(t), R(s), and G(s) now render seamlessly without manual syntax modifications.",
      "Graceful error handling: genuine Mermaid syntax errors are cleanly formatted as reader-facing cards rather than broken SVG charts.",
      "In-app update delivery: Lucid 1.0.3 users can update directly via Lucid → Check for Updates… without manual re-installation.",
    ],
    sections: [
      {
        title: "Mermaid Rendering",
        items: [
          {
            type: "fixed",
            text: "Fixed Mermaid flowchart diagrams containing parenthesized mathematical notation (e.g. r(t), R(s), G(s), θ(t), ω(t)) in node labels that previously caused syntax errors.",
          },
          {
            type: "improved",
            text: "Improved presentation of unrecoverable Mermaid diagram syntax errors with formatted reader-facing notification cards.",
          },
        ],
      },
      {
        title: "In-App Updates",
        items: [
          {
            type: "improved",
            text: "Delivered through the native Sparkle in-app updater introduced in v1.0.3.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.3",
    date: "September 21, 2026",
    channel: "Beta",
    summary: "First updater-bearing release introducing native Sparkle 2 in-app update checking, EdDSA cryptographic archive verification, and dedicated update preferences in Settings.",
    highlights: [
      "Built-in in-app updates: check for updates directly from the Lucid application menu or Settings",
      "Cryptographic EdDSA verification: all update packages are cryptographically signed and authenticated before installation",
      "User-controlled update preferences: configure automatic background checks and automatic downloading in Settings → Updates",
      "One-time manual migration: v1.0.2 and earlier must install v1.0.3 manually once; once verified, subsequent releases can update in-app",
      "Production HTTPS feed: securely hosted on Vercel with strict staged-vs-published gating to eliminate broken download links",
    ],
    sections: [
      {
        title: "In-App Updates",
        items: [
          {
            type: "new",
            text: "Native Check for Updates… command added to the Lucid application menu.",
          },
          {
            type: "new",
            text: "Dedicated Updates tab in Settings (⌘,) with current version display, last checked timestamp, and automatic check/download toggles.",
          },
          {
            type: "new",
            text: "Sparkle 2 integration with EdDSA archive signing and HTTPS feed delivery.",
          },
          {
            type: "improved",
            text: "Disk image detection displays a quiet notification if Lucid is launched from a read-only DMG volume, prompting to move to Applications.",
          },
        ],
      },
      {
        title: "Migration Notice",
        items: [
          {
            type: "improved",
            text: "Lucid 1.0.3 is the first release containing updater infrastructure. Users on 1.0.2 or earlier must manually install 1.0.3 once; subsequent releases will be delivered through the built-in updater once verified.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.2",
    date: "September 21, 2026",
    channel: "Beta",
    summary: "Quality, UX hardening, and Mermaid technical layout release delivering expandable scrollbars, zero-jitter sidebar transitions, adaptive tall flowchart presentation, and Lucid Blue-Tint diagrams.",
    highlights: [
      "Expandable Reader scrollbar: subtle 4px resting thumb, easy-to-grab 8px hover, 10px active drag, and zero layout shift",
      "Zero-jitter sidebar: smooth native transition, preserved WKWebView identity, preserved scroll, and stored width memory",
      "Tall Mermaid flowchart inline layout: adaptively expands up to 2400px so complex technical diagrams are readable without pressing Expand",
      "Lucid Blue-Tint theme: cohesive technical visual language across Dark, Light, and Sepia themes while preserving custom diagram styles",
      "Renderer conformance: verified 100% pass rate across all 13 core mathematical and structural rendering invariants",
    ],
    sections: [
      {
        title: "Reader & UX Hardening",
        items: [
          {
            type: "improved",
            text: "Expandable scrollbar thumb: subtle 4px rest, 8px hover hit area, and 10px active drag contrast inside a constant 12px gutter.",
          },
          {
            type: "fixed",
            text: "Completely eliminated left outline sidebar open/close jitter with a native SwiftUI transition and stored sidebar width memory.",
          },
          {
            type: "fixed",
            text: "WKWebView lifecycle and document scroll position remain completely uninterrupted across sidebar toggles and window resizing.",
          },
        ],
      },
      {
        title: "Mermaid Technical Diagrams",
        items: [
          {
            type: "improved",
            text: "Adaptive inline diagram presentation: tall technical flowcharts (e.g. ESP32 control flow) now expand inline up to 2400px so all labels remain readable at standard text size.",
          },
          {
            type: "improved",
            text: "Readability floor: enforces a minimum scale targeting ≥ 13.5px effective font size for labels on initial display.",
          },
          {
            type: "new",
            text: "Lucid Blue-Tint technical styling: curated node surfaces, crisp blue borders, and clear arrowheads across Dark, Light, and Sepia themes.",
          },
          {
            type: "improved",
            text: "User-interaction state preservation: user zoom and pan adjustments are preserved across window resizing.",
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
