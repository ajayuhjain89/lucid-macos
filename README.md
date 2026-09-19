<p align="center">
  <img src="https://raw.githubusercontent.com/ajayuhjain89/lucid/main/icon.png" width="128" height="128" alt="Lucid Logo" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.25);" />
</p>

<h1 align="center">Lucid for macOS</h1>

<p align="center">
  <strong>A high-performance, distraction-free native Markdown reader and editor for macOS.</strong><br>
  Built with Swift, SwiftUI, and Apple Silicon native optimization.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-black?style=flat-square&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/arch-Apple%20Silicon%20(arm64)-orange?style=flat-square" alt="arm64">
  <img src="https://img.shields.io/badge/binary-645%20KB-blue?style=flat-square" alt="Binary Size">
  <img src="https://img.shields.io/badge/bundle-8.9%20MB-emerald?style=flat-square" alt="Bundle Size">
  <img src="https://img.shields.io/badge/license-MIT-purple?style=flat-square" alt="MIT License">
</p>

---

## Highlights

- ⚡️ **Instant Launch (< 50ms)**: Pure native Mach-O binary without Electron runtime overhead. Consumes ~25 MB RAM.
- 📖 **Reader Mode (`⌘1`)**: Zero-chrome, centered reading canvas with optical margin alignment and ProMotion 120Hz smooth scrolling.
- ✍️ **Split Editor Mode (`⌘2`)**: Side-by-side Markdown editor with bidirectional synchronized scrolling and smart-substitutions disabled.
- 🎨 **Inspector Panel (`⌘I`)**: Live control over font family (SF Pro, New York Serif, SF Mono), font size, line height, reading width, accent color, and themes.
- 🌓 **Themes**: System Auto, Light, Dark, Sepia, OLED True Black, Nord, and Dracula.
- 🔔 **GitHub Alerts**: Full support for `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]` with custom iconography.
- 📐 **KaTeX Equations**: Instant offline rendering of inline math (`$...$`) and block math (`$$...$$`).
- 📊 **Mermaid Diagrams**: Interactive flowcharts, sequence diagrams, and architecture maps rendered directly.
- 📑 **Table of Contents (`⌘⌥T`)**: Live outline extracted from headings with smooth jump-to-section navigation.
- 👁 **Live External File Watcher**: Edit in Neovim, VS Code, or Obsidian and watch Lucid update live on save without losing your scroll position.
- 🖨 **Pro Export**: Pixel-perfect vector PDF, self-contained standalone HTML (offline assets embedded), and formatted Rich Text copy to clipboard.

---

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘1` | Switch to **Reader Mode** |
| `⌘2` | Switch to **Split Editor Mode** |
| `⌘3` | Switch to **Editor Mode** |
| `⌘I` | Toggle **Inspector Panel** |
| `⌘⌥T` | Toggle **Table of Contents Outline** |
| `⌘+` / `⌘-` | Increase / Decrease Font Size |
| `⌘0` | Reset Font Size (16px) |
| `⌘P` | Export as Vector PDF |
| `⌘E` | Export as Standalone HTML |
| `⌥⌘C` | Copy Formatted Rich Text |

---

## Building from Source

Requirements: macOS 14.0+ and Swift 6+ (Apple Command Line Tools).

```bash
# Clone the repository
git clone https://github.com/ajayuhjain89/lucid-macos.git
cd lucid-macos

# Compile and package Lucid.app
./build.sh

# Launch the app
open Lucid.app
```

---

## License

MIT © [Ayush Jain](https://github.com/ajayuhjain89)
