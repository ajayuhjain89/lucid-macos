# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2026-09-25

### Added
- Native support for rendering Markdown footnotes with linked anchors and endnotes section.
- Multi-window independent view states: view mode, sidebar state, and Focus Mode are window-scoped.
- Focus Mode and Typewriter Mode support within the Editor view.
- Support for opening UTF-16 and legacy 8-bit encoded files alongside UTF-8.
- Comprehensive Swift Testing unit test target covering decoding, list continuation, outline parsing, pane layout, presets, and window state.

### Improved
- Preserved reading position and pane state across mode switches and document reloads without jumping to the top.
- Smoother sidebar transitions with directional hysteresis and sub-pixel deadband to eliminate outline flickering while scrolling.
- Serialized Mermaid diagram theme rendering with WebKit yielding and theme-cached SVGs for seamless theme switches.
- Enhanced Mermaid error presentation with reader-facing error cards while keeping the rest of the document functional.
- Responsive Settings Editor layout with compact font pickers and single-window reuse.
- Native macOS View menu integration with synchronized checkmarks for display modes and layout options.
- Floating toolbar content clipping: content scrolled under the floating glass toolbar is properly clipped.
- Search field in Command Palette automatically receives focus on open and returns focus upon dismissal.
- Wrapped long unbroken words in preview to prevent horizontal overflow.
- Accessible names and labels across theme, accent, and workflow preset controls in Settings.

### Fixed
- Fixed Split mode editor starting at the top of the document when opened.
- Fixed native outline parser parity with renderer for duplicate and non-Latin Unicode heading IDs.
- Fixed in-page Find from highlighting hidden markup inside Mermaid diagrams and KaTeX formulas.
- Fixed live reload to remain active after file renames and external edits.
- Fixed Developer workflow preset to apply full developer settings without leaking previous preset options.

### Security
- Enforced strict Content-Security-Policy (CSP) on the Markdown preview and removed inline event handlers.
- Local image paths are strictly sandboxed through the custom `lucid-asset:` scheme.
- Gated KaTeX, Mermaid, syntax highlighting, and chemistry rendering strictly behind user preferences.
- Hardened Sparkle release signature lookup and update check availability guards.

## [1.0.4] - 2026-09-22

### Fixed
- Fixed Mermaid flowchart rendering compatibility for node labels containing parenthesized mathematical notation (such as `r(t)`, `R(s)`, and `G(s)`).
- Formatted unrecoverable Mermaid diagram syntax errors cleanly as reader-facing notification cards instead of broken SVG charts.

### Added
- First in-app update delivery via Sparkle for users on Lucid 1.0.3.

## [1.0.3] - 2026-09-21

### Added
- Native built-in update mechanism powered by Sparkle 2 (v2.10.0).
- "Check for Updates…" menu command in the Lucid application menu.
- Dedicated Updates tab in Settings (`⌘,` → Updates) displaying installed version, build number, last check timestamp, and update controls.
- User-configurable automatic update preferences: toggle automatic background checks and automatic background downloads.
- Cryptographic EdDSA archive signing and verification (`SUPublicEDKey`) ensuring update integrity and authenticity.
- Production HTTPS update feed endpoint at `/api/appcast` with strict staged-vs-published gating to prevent broken update links.
- Helper script `scripts/sparkle-sign-release.sh` for deterministic EdDSA release signing.
- Runtime disk image detection alerting users to move Lucid to `/Applications` for automatic updates if launched from a read-only DMG.

### Security
- Update archives are cryptographically verified using EdDSA signatures before extraction.
- Telemetry and system profiling remain disabled (`sendsSystemProfile = false`).
- Ad-hoc signed public beta; Developer ID signing and Apple notarization remain deferred until enrollment in the Apple Developer Program and a future release.

### Migration Note
- Lucid v1.0.0, v1.0.1, and v1.0.2 do not contain an in-app updater and cannot automatically receive v1.0.3.
- Existing users must manually install v1.0.3 once by downloading `Lucid-1.0.3.dmg`.
- Once verified, subsequent releases such as v1.0.4 can be checked and downloaded directly from inside Lucid.

## [1.0.2] - 2026-09-21

### Added
- Lucid Blue-Tint technical visual language for Mermaid diagrams across Dark, Light, and Sepia themes with coherent borders, surfaces, and arrowheads while preserving custom user styles.
- Custom draggable `SidebarDivider` with AppKit `NSCursor.resizeLeftRight` cursor rects and active drag capture.
- Persistent sidebar width preference (`lucid.sidebarWidth`, 180–320px) stored across sessions.

### Improved
- Reader scrollbar interaction: expandable visible thumb inside a constant 12px gutter (4px rest, 8px hover, 10px active drag) with theme-specific contrast, eliminating accidental misses and layout shifts.
- Adaptive inline Mermaid presentation: tall technical flowcharts (e.g. ESP32 control flow) expand inline up to 2400px, remaining readable without pressing Expand.
- Diagram typography floor: enforces minimum scale targeting ≥ 13.5px effective font size for labels on initial display.
- Preserved user zoom and pan adjustments on diagrams across window resize events.

### Fixed
- Completely eliminated left outline sidebar open/close jitter by replacing AppKit `HSplitView` with SwiftUI `HStack` and an animated leading transition.
- WKWebView lifecycle, document scroll position, and active heading scroll-spy remain completely uninterrupted across sidebar toggles.
- Verified 100% pass rate across all 13 core mathematical and structural renderer conformance invariants.

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

[1.0.5]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.5
[1.0.4]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.4
[1.0.3]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.3
[1.0.2]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.2
[1.0.1]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.1
[1.0.0]: https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.0
