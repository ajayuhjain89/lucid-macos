# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Floating glass toolbar (`NSVisualEffectView`) that document content scrolls beneath.
- Scroll-responsive chrome depth: material, hairline, and shadow fade in with scroll.
- Refined content top inset so the first heading clears the toolbar at rest and
  travels beneath it on scroll.
- Reduce Motion and Reduce Transparency accessibility support across chrome and motion.
- Focus Mode toolbar recede-on-idle with gentle reveal on hover.

### Changed
- Unified motion vocabulary (hover / state / panel / modal / glass) in the design system.
- Command palette and find bar moved to the native glass material with a lighter,
  less intrusive entrance.
- Status bar softened from a hard band to a barely-there hairline.
- Moved application/project documentation into `docs/` (workflow guide, engineering
  showcase, sample), keeping README/LICENSE/CHANGELOG/CONTRIBUTING/THIRD-PARTY-NOTICES
  in the repository root.

## [1.0.1] - 2026-09-21

### Added
- Smart adaptive initial Mermaid diagram layout: normal and medium diagrams fit completely on first render when readable, with dynamic viewport height up to `min(840px, 80vh)`.

### Improved
- Mermaid Hand/Pan interaction: visible `grab`/`grabbing` cursor states, Pointer Events with pointer capture, stable drag origin, requestAnimationFrame transform coalescing, and smooth 1:1 panning with no CSS transition fight.
- Huge Mermaid diagrams retain a comfortable working scale (targeting ≥ 13.5px effective typography) with pan navigation, while Fit provides a full-diagram overview and Reset restores the exact smart initial view.

### Fixed
- Outline sidebar toggle no longer causes a brief Reader/WKWebView blank flash or Markdown rerender; scroll position and Mermaid transform states are preserved across sidebar toggles.

## [1.0.0] - 2026-09-20

### Added
- Initial **v1.0.0 Public Beta** release for macOS 14 Sonoma (Apple Silicon arm64).
- Native macOS Markdown reader & editor with Reader / Split / Editor modes (`⌘1` / `⌘2` / `⌘3`).
- Offline WebKit rendering engine: markdown-it, KaTeX (+ mhchem), Mermaid, highlight.js.
- GitHub/Obsidian alerts, live outline sidebar with scroll-spy, command palette, find.
- Focus & Typewriter modes, curated themes, customizable accent color.
- Live external file watching and PDF / standalone-HTML / rich-text export.
- Pre-packaged `Lucid-1.0.0.dmg` release artifact with verified SHA-256 checksum.

[1.0.1]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.1
[1.0.0]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.0
