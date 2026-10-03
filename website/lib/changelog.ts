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
    version: "1.0.7",
    date: "September 29, 2026",
    channel: "Beta",
    summary: "Lucid 1.0.7 Public Beta delivers everyday productivity enhancements: an intuitive new tab empty-state card, direct file drag-and-drop, persistent toolbar and tab bar open affordances, safe multi-document application termination, and clean window closing.",
    highlights: [
      "New Tab Empty State: Opening a new tab (⌘T or +) presents an intuitive, welcoming card with 'Open File… (⌘O)', 'Start Writing', recent documents, and file drag-and-drop.",
      "File Drag & Drop: Drag Markdown files directly from Finder onto empty tabs or the window to open them immediately.",
      "Direct Open Affordances: Quickly access your files with persistent Open File (arrow.up.doc) and New Tab (+) buttons directly on the window toolbar and tab strip, with contextual tab menus.",
      "Safe Application Termination: Quitting Lucid (⌘Q) sequentially reviews and prompts to save each modified document tab by its actual file name, preventing data loss across multi-window and multi-tab workflows.",
    ],
    sections: [
      {
        title: "Productivity",
        items: [
          {
            type: "new",
            text: "New tab empty-state card: opening a new tab (⌘T or +) presents an intuitive, welcoming card with 'Open File… (⌘O)', 'Start Writing', recent documents, and file drag-and-drop.",
          },
          {
            type: "new",
            text: "Drag-and-drop file opening: dragging Markdown files directly from Finder onto empty tabs or the window immediately opens them.",
          },
          {
            type: "new",
            text: "Direct toolbar and tab bar open affordances: added persistent Open File (arrow.up.doc) and New Tab (+) buttons on the main window toolbar and tab strip, alongside contextual tab menus.",
          },
          {
            type: "new",
            text: "Safe application termination (⌘Q): sequentially prompts to save each modified document tab by its actual file name, preventing data loss across multi-window and multi-tab workflows.",
          },
        ],
      },
      {
        title: "Fixes & Stability",
        items: [
          {
            type: "fixed",
            text: "Fixed spurious 'save Untitled' prompts when closing clean windows or switching files by clearing change counts on clean tabs.",
          },
          {
            type: "fixed",
            text: "Fixed AppKit editor layering so the new tab empty-state view is fully interactive and responsive to clicks and typing.",
          },
          {
            type: "fixed",
            text: "Fixed empty untitled window persistence when opening files at launch or from Finder.",
          },
          {
            type: "fixed",
            text: "Fixed key window notification routing ensuring single-window setups never drop menu or shortcut actions.",
          },
        ],
      },
    ],
  },
  {
    version: "1.0.6",
    date: "September 28, 2026",
    channel: "Beta",
    summary: "Lucid 1.0.6 Public Beta introduces everyday productivity features: keep multiple Markdown documents open in lightweight tabs, quickly reopen recent documents, restore your open session across relaunches, and paste or drag images directly into your documents.",
    highlights: [
      "Lightweight Tabs: Keep multiple Markdown documents open in one window with keyboard navigation and single-preview rendering efficiency.",
      "Recent Files: Quickly reopen documents you've recently worked on from File → Open Recent.",
      "Session Restoration: Return to your open documents and active reading state when you relaunch Lucid.",
      "Paste & Drag Images: Paste screenshots or drag supported images directly into your Markdown documents with automatic local asset storage.",
    ],
    sections: [
      {
        title: "Productivity",
        items: [
          {
            type: "new",
            text: "Lightweight document tabs: keep multiple Markdown documents open in one window with keyboard shortcuts (⌘T to open a new tab, ⌘W to close, and ⌘} / ⌘{ to switch tabs).",
          },
          {
            type: "new",
            text: "Same-document deduplication: opening an already open document activates its existing tab rather than creating duplicates.",
          },
          {
            type: "new",
            text: "Dirty tab protection: confirms before closing tabs with unsaved edits to prevent accidental data loss.",
          },
          {
            type: "new",
            text: "Recent Files: quickly reopen documents you've recently worked on from File → Open Recent, with deduplicated history and a Clear Menu option.",
          },
          {
            type: "new",
            text: "Session restoration: return to your open documents and reading state when you relaunch Lucid.",
          },
          {
            type: "new",
            text: "Paste & drag images: paste screenshots or drag image files directly into the Markdown editor; Lucid organizes them in a local assets folder and inserts relative Markdown links.",
          },
          {
            type: "new",
            text: "Supports PNG, JPEG, GIF, WebP, SVG, TIFF, and BMP image formats.",
          },
        ],
      },
      {
        title: "Architecture & Performance",
        items: [
          {
            type: "improved",
            text: "Lightweight tab architecture: inactive tabs avoid separate WebKit preview pipelines, saving memory and keeping editing responsive.",
          },
          {
            type: "improved",
            text: "Lazy session restoration: restores tab lists and document metadata cleanly on launch without blocking the UI.",
          },
        ],
      },
      {
        title: "Fixes",
        items: [
          {
            type: "fixed",
            text: "Fixed an application startup crash when initializing recent documents on launch.",
          },
          {
            type: "fixed",
            text: "Fixed document-relative image resolution in preview so relative images load reliably from any folder structure.",
          },
        ],
      },
    ],
  },
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
