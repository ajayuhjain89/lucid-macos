<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="Lucid" />
</p>

<h1 align="center">Lucid</h1>

<p align="center">
  <strong>A native macOS Markdown reader and editor built for technical documents.</strong><br>
  Markdown, made lucid. Built with Swift &amp; SwiftUI. Apple Silicon native.
</p>

<p align="center">
  <a href="https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.1"><img src="https://img.shields.io/badge/release-v1.0.1--beta-blue?style=flat-square" alt="v1.0.1 Public Beta"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-black?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/arch-Apple%20Silicon%20(arm64)-orange?style=flat-square" alt="Apple Silicon (arm64)">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+">
  <a href="https://github.com/ajayuhjain89/lucid-macos/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ajayuhjain89/lucid-macos/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-purple?style=flat-square" alt="MIT License"></a>
</p>

<p align="center">
  <a href="https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.1/Lucid-1.0.1.dmg"><strong>Download Lucid (5.0 MB)</strong></a> &nbsp;•&nbsp;
  <a href="https://website-phi-umber-70.vercel.app"><strong>Official Website</strong></a> &nbsp;•&nbsp;
  <a href="https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.1">Release Notes</a>
</p>

---

Lucid renders Markdown with an editorial identity and wraps it in a genuinely native macOS shell: a floating glass toolbar that content scrolls beneath, scroll-responsive depth, and motion tuned to feel deliberate and quiet. It provides offline mathematics (KaTeX), chemistry (`mhchem`), interactive Mermaid diagrams, code syntax highlighting, and wide technical tables — designed for technical notes, research papers, and system documentation.

## Install

1. Download [**Lucid-1.0.1.dmg**](https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.1/Lucid-1.0.1.dmg) (5.0 MB).
2. Open `Lucid-1.0.1.dmg` in your Downloads folder.
3. Drag `Lucid.app` into your `Applications` folder.
4. Launch Lucid from Applications or Spotlight.

### First Launch (macOS Gatekeeper Notice)

Lucid is currently in **Public Beta** and is ad-hoc signed rather than Apple Developer ID notarized. On first launch, macOS Gatekeeper may present a dialog stating that Apple cannot verify the developer.

To open Lucid:
- **Primary**: In Finder, open your `Applications` folder, right-click (or Control-click) `Lucid.app`, select **Open**, and click **Open** in the confirmation prompt.
- **Alternative**: Navigate to **System Settings → Privacy & Security**, scroll down to the Security section, and click **Open Anyway** next to the notification for Lucid.

Official Apple Developer ID signing and notarization will be configured for the stable release.

## System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (`arm64`)
- **Intel (x86_64)**: Not currently supported by the distributed Public Beta binary

## Release Integrity

| Property | Value |
| :--- | :--- |
| **Release** | Lucid 1.0.1 Public Beta (`v1.0.1`) |
| **Artifact** | `Lucid-1.0.1.dmg` |
| **File Size** | 5,246,936 bytes (~5.0 MB) |
| **SHA-256** | `3e21388d85a42316fc60e6e060c2b7834949755746ed4826528b05b8af0b82a5` |

To verify the checksum of your download in Terminal:

```bash
shasum -a 256 ~/Downloads/Lucid-1.0.1.dmg
```

The output should match the SHA-256 hash above. Authoritative release assets and release notes are published on [GitHub Releases](https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.1).

## Features

- 📖 **Reader, Split, and Editor modes** (`⌘1` / `⌘2` / `⌘3`) — a distraction-free reading canvas, a synchronized side-by-side editor/reader, and a focused source editor.
- 📐 **KaTeX mathematics & mhchem** — offline inline (`$…$`) and block (`$$…$$`) formula rendering, with full chemistry notation (`\ce{…}`).
- 📊 **Interactive Mermaid diagrams** — flowcharts, sequence diagrams, state machines, and class diagrams with pan, zoom, fit-to-view, reset, and SVG export.
- 💻 **Syntax-highlighted code & wide tables** — syntax highlighting across 180+ languages with code block copy, plus horizontally scrollable technical tables.
- 🔔 **GitHub-style callouts** — `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]` alerts with native styling and collapsible variants.
- 🧭 **Document outline & navigation** — real-time heading outline sidebar (`⌘⌥T` / `⌃⌘S`) with scroll-spy tracking, plus in-document find (`⌘F`).
- ⚡️ **Fuzzy command palette** — quick command execution (`⌘K`) for actions, view switching, and settings.
- 🎯 **Focus & Typewriter modes** — dim inactive Markdown blocks (`⌘⇧D`) and keep the active cursor line vertically centered (`⌘⇧T`).
- 🎨 **Curated typography & themes** — System Dynamic, Lucid Studio Dark, Editorial Light, and Warm Book Sepia, each calibrated with a customizable accent color.
- 👁 **Live file watching** — edit documents in external editors (Neovim, VS Code, Obsidian) and Lucid updates automatically on save without losing scroll position.
- 🖨 **Vector export** — export to high-resolution vector PDF, standalone self-contained HTML (all assets embedded offline), and rich text copy (`⌥⌘C`).
- ♿️ **Accessibility-aware** — respects system settings for Reduce Transparency, Reduce Motion, and Increase Contrast.

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘1` / `⌘2` / `⌘3` | Reader / Split / Editor mode |
| `⌘K` | Command palette |
| `⌘F` | Find in document |
| `⌘⌥T` | Toggle table-of-contents sidebar |
| `⌃⌘S` | Toggle outline sidebar |
| `⌘⇧D` | Toggle Focus mode |
| `⌘⇧T` | Toggle Typewriter mode |
| `⌘+` / `⌘-` / `⌘0` | Increase / decrease / reset font size |
| `⌥⌘C` | Copy formatted rich text |
| `⌘E` | Export as standalone HTML |
| `⌘,` | Settings |

> Export as PDF and the full theme/preset list are available from the command palette (`⌘K`) and the toolbar's overflow menu.

## Local-First & Privacy

Lucid is designed to respect document privacy:
- **Zero telemetry**: No analytics, no tracking pixels, and no network requests for document parsing.
- **Offline rendering**: KaTeX, Mermaid, highlight.js, and markdown-it run entirely locally inside a sandboxed WebKit instance.
- **Local files**: Documents never leave your Mac.

Read our full [Privacy Policy](https://website-phi-umber-70.vercel.app/privacy).

## Building from Source

### Prerequisites

- macOS 14.0 (Sonoma) or later on Apple Silicon
- Xcode Command Line Tools (`xcode-select --install`) — provides the Swift compiler (`swiftc`)

### Build Steps

```bash
git clone https://github.com/ajayuhjain89/lucid-macos.git
cd lucid-macos

# Compile, bundle, ad-hoc sign Lucid.app, and produce Lucid-1.0.0.dmg
./build.sh

# Launch the built application
open Lucid.app
```

The `./build.sh` script compiles an optimized `arm64` binary, bundles resources (including the offline WebEngine), ad-hoc code-signs `Lucid.app`, and packages `Lucid-1.0.0.dmg`.

> Note: A `Package.swift` is included for Swift Package Manager and editor tooling integration. For complete development guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Architecture

Lucid pairs a native document-based SwiftUI/AppKit application shell with a high-performance, offline WebKit rendering engine:

```
Sources/Lucid/
├── LucidApp.swift            # App entry, DocumentGroup, native menu commands
├── DesignSystem/             # Tokens (spacing, radius, motion, materials) & controls
├── Models/                   # Preferences, document state, commands, outline model
├── Views/                    # Main window, floating glass toolbar, editor, preview,
│                             #   sidebar, status bar, command palette, find, settings
├── Services/                 # Render coordination, file watching, export, metrics
└── Resources/WebEngine/      # Bundled offline HTML/CSS/JS reader (markdown-it,
                              #   KaTeX, Mermaid, highlight.js)
```

- **Native editing**: Text editing runs in a native macOS text view (`NSTextView`).
- **Offline WebEngine**: The reading canvas is a read-only `WKWebView` running a bundled, offline engine. A `PreviewRenderCoordinator` coordinates updates with debouncing and revision equality to guarantee deterministic rendering.
- **Floating glass chrome**: Translucent `NSVisualEffectView` toolbar where content scrolls underneath, dynamically adjusting depth and hairline borders based on scroll offset.

## Documentation & Links

- **Official Website**: [website-phi-umber-70.vercel.app](https://website-phi-umber-70.vercel.app)
- **Features Overview**: [website-phi-umber-70.vercel.app/features](https://website-phi-umber-70.vercel.app/features)
- **Documentation Hub**: [website-phi-umber-70.vercel.app/docs](https://website-phi-umber-70.vercel.app/docs)
- **Getting Started Guide**: [website-phi-umber-70.vercel.app/docs/getting-started](https://website-phi-umber-70.vercel.app/docs/getting-started)
- **Download Page**: [website-phi-umber-70.vercel.app/download](https://website-phi-umber-70.vercel.app/download)
- **Changelog**: [website-phi-umber-70.vercel.app/changelog](https://website-phi-umber-70.vercel.app/changelog) or repository [CHANGELOG.md](CHANGELOG.md)
- **Support & Help**: [website-phi-umber-70.vercel.app/support](https://website-phi-umber-70.vercel.app/support)
- **Privacy Policy**: [website-phi-umber-70.vercel.app/privacy](https://website-phi-umber-70.vercel.app/privacy)
- **Engineering Showcase**: [docs/Engineering_Showcase.md](docs/Engineering_Showcase.md)
- **Reader Sample Document**: [docs/Sample.md](docs/Sample.md)
- **Git & GitHub Workflow**: [docs/github_workflow.md](docs/github_workflow.md)

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/github_workflow.md](docs/github_workflow.md) before opening pull requests.

Lucid uses a strictly unidirectional category-branch workflow:
- Permanent branches: `main`, `develop`, `logic`, `design`, `docs`
- Work flows strictly forward: `category → develop → main`
- Work directly on the appropriate category branch; no ordinary task branches and no backwards merges from `develop`.

## License

Lucid is released under the [MIT License](LICENSE). Copyright © 2026 Ayush Jain.
