# Contributing to Lucid

Thanks for your interest in improving Lucid. This is a native macOS app that
values restraint: contributions should make the product quieter, smoother, and
more deliberate — never busier.

## Design principles

- **Document-first.** The rendered content is the star; chrome stays quiet.
- **Native, not simulated.** Prefer real AppKit/WebKit behavior over reimplementations.
- **One design system.** Reuse the tokens and components in `Sources/Lucid/DesignSystem`
  (spacing, radius, motion, materials) instead of introducing ad-hoc values.
- **The VS Code extension is the visual source of truth** for rendered Markdown.
  Changes to `Resources/WebEngine` should track it.

## Development setup

Requirements: macOS 14+, Apple Silicon, and Xcode Command Line Tools.

```bash
git clone https://github.com/ajayuhjain89/lucid-macos.git
cd lucid-macos
./build.sh          # full app bundle + DMG
open Lucid.app
```

`build.sh` is the supported build path (it compiles with `swiftc`, bundles, and
signs). A `Package.swift` is provided for editor/tooling integration; `swift build`
additionally requires a full Xcode toolchain.

To preview the Markdown reader (`Resources/WebEngine`) in isolation, serve the
folder over HTTP and drive it from the JS console:

```bash
cd Sources/Lucid/Resources/WebEngine
python3 -m http.server 8899
# then, in the browser console:
# window.lucid.updateContent("# Hello");
# window.lucid.updatePreferences({ theme: "dark" });
```

## Pull requests

Lucid uses a category-branch workflow — read [docs/github_workflow.md](docs/github_workflow.md)
for the full model. In short:

1. Branch from the relevant category branch (`design`, `logic`, or `docs`) using a
   `design-<task>` / `logic-<task>` / `docs-<task>` name.
2. Keep changes focused and one task per branch; describe the *why*, not just the *what*.
3. Ensure the project builds (`./build.sh`) before opening the PR.
4. Include before/after screenshots for any visible UI change.
5. Open the task PR into its category branch; promotion then flows
   category → `develop` → `main`.
6. Do not commit build artifacts (`Lucid`, `Lucid.app`, `*.dmg`, `scratch/`) — they
   are covered by `.gitignore`.

## Reporting issues

Use the issue templates. For bugs, include your macOS version, whether you're on
Apple Silicon, steps to reproduce, and a sample Markdown snippet when relevant.
