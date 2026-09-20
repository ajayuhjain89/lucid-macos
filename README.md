<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="Lucid" />
</p>

<h1 align="center">Lucid for macOS</h1>

<p align="center">
  <strong>A quiet, premium, native Markdown reader &amp; editor for macOS.</strong><br>
  Built with Swift &amp; SwiftUI. No Electron. Apple-Silicon native.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-black?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/arch-Apple%20Silicon%20(arm64)-orange?style=flat-square" alt="arm64">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-1575F9?style=flat-square" alt="SwiftUI + AppKit">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-purple?style=flat-square" alt="MIT License"></a>
</p>

---

Lucid renders Markdown with an editorial identity and wraps it in a genuinely native macOS shell: a floating glass toolbar that content scrolls *beneath*, scroll-responsive depth, and motion tuned to feel deliberate and quiet. The document is always the star.

## Highlights

- ⚡️ **Native &amp; instant** — a pure Swift/AppKit/WebKit binary. No Electron runtime, no bundled Chromium; launches immediately and stays light on memory.
- 🪟 **Floating glass chrome** — a translucent `NSVisualEffectView` toolbar that content scrolls underneath. The glass is near-transparent at the top of a document and frosts subtly as content passes beneath it.
- 📖 **Reader / Split / Editor** — three modes (`⌘1` / `⌘2` / `⌘3`) with a distraction-free reading canvas, a live side-by-side editor with synchronized scrolling, and a focused source editor.
- 🎯 **Focus &amp; Typewriter modes** — dim inactive blocks (`⌘⇧D`) and keep the active line centered (`⌘⇧T`).
- 🎨 **Curated themes** — System Dynamic, Lucid Studio Dark, Editorial Light, and Warm Book Sepia, each tuned separately (not just inverted) with a user-customizable accent color.
- 🔔 **GitHub / Obsidian alerts** — `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`, and more, with iconography and collapsible variants.
- 📐 **KaTeX math** — offline inline (`$…$`) and block (`$$…$$`) rendering, with `mhchem` for chemistry.
- 📊 **Mermaid diagrams** — flowcharts and diagrams rendered inline with zoom and SVG copy/export.
- 🧭 **Live outline &amp; command palette** — a heading outline sidebar (`⌘⌥T`) with scroll-spy, and a fuzzy command palette (`⌘K`).
- 🔎 **In-document find** — a floating find bar (`⌘F`) with match navigation.
- 👁 **Live file watching** — edit in Neovim, VS Code, or Obsidian and Lucid updates on save without losing your place.
- 🖨 **Pro export** — vector PDF, self-contained standalone HTML (assets embedded), and formatted rich-text copy.
- ♿️ **Accessibility-aware** — honors Reduce Transparency, Reduce Motion, and Increased Contrast.

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

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (arm64)
- Xcode Command Line Tools (`xcode-select --install`) — provides the Swift toolchain

## Building from Source

```bash
git clone https://github.com/ajayuhjain89/lucid-macos.git
cd lucid-macos

# Compile, bundle, sign Lucid.app, and produce the DMG
./build.sh

# Run it
open Lucid.app
```

The build script compiles an optimized arm64 binary, assembles `Lucid.app`, ad-hoc code-signs it, and creates `Lucid-1.0.0.dmg`.

> A `Package.swift` is included for editor/tooling integration. `swift build`
> requires a full Xcode toolchain; the supported build path is `./build.sh`.

## Architecture

Lucid is a document-based SwiftUI app with a WebKit rendering surface for Markdown.

```
Sources/Lucid/
├── LucidApp.swift            # App entry, DocumentGroup, menu commands
├── DesignSystem/             # Spacing, radius, motion, materials, reusable controls
├── Models/                   # Preferences, document, commands, heading outline
├── Views/                    # Main window, toolbar, editor, preview, sidebar,
│                             #   status bar, command palette, find, settings
├── Services/                 # Render coordination, file watching, export, metrics
└── Resources/WebEngine/      # HTML/CSS/JS reader (markdown-it, KaTeX, Mermaid,
                              #   highlight.js) — the visual source of truth
```

**How rendering works:** editing happens only in the native Markdown source editor (`NSTextView`). The rendered preview is a strictly read-only `WKWebView` running a bundled, fully offline engine (`markdown-it` + plugins, KaTeX/mhchem, Mermaid, highlight.js). A `PreviewRenderCoordinator` debounces updates and enforces revision equality so renders never race. Native chrome (the floating glass toolbar) is layered over the full-height content so the document scrolls beneath it; the toolbar height and the content's top inset are coupled through `LucidChrome` in the design system.

The `Resources/WebEngine` reader is ported from the companion **Lucid** VS Code extension, which remains the visual source of truth for rendered Markdown content.

## Documentation

Application and project documentation lives in [`docs/`](docs/):

- [docs/github_workflow.md](docs/github_workflow.md) — the canonical Git/GitHub branching, verification, and release workflow.
- [docs/Engineering_Showcase.md](docs/Engineering_Showcase.md) — engineering/architecture showcase.
- [docs/Sample.md](docs/Sample.md) — sample Markdown for exercising the reader.

Community, legal, and meta files stay in the repository root: this README,
[LICENSE](LICENSE), [CHANGELOG.md](CHANGELOG.md), [CONTRIBUTING.md](CONTRIBUTING.md),
and [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and the
[workflow guide](docs/github_workflow.md). Please keep changes aligned with the app's design principles: quiet, native, and document-first.

## License

MIT © [Ayush Jain](https://github.com/ajayuhjain89) — see [LICENSE](LICENSE).
