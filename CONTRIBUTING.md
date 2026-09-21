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
./build.sh          # full app bundle + local development DMG (Lucid-local.dmg)
open Lucid.app
```

`build.sh` is the supported build path (it compiles with `swiftc`, bundles, and
signs). Ordinary `./build.sh` builds produce `Lucid.app` and a local development disk
image (`Lucid-local.dmg`) without touching canonical release artifacts (`Lucid-<version>.dmg`).
For release packaging, `./build.sh --release` packages the versioned release artifact with
overwrite protection. Release validation (`npm run release:validate` in `website/`) checks
the published/canonical release artifact, which must never be replaced by a local development rebuild.
A `Package.swift` is provided for editor/tooling integration; `swift build`
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

Lucid uses a **direct category-branch** workflow — read
[docs/github_workflow.md](docs/github_workflow.md) for the authoritative model. In short:

1. The repository uses five permanent branches: `main`, `develop`, `logic`, `design`, and `docs`.
2. Decide whether your work is **logic** (engineering), **design** (UI/UX), or
   **docs**, and work **directly on that category branch** — do **not** create a
   task branch for ordinary work.
3. Work flows **strictly forward**: `logic` / `design` / `docs` → `develop` → `main`.
   Never merge `develop` backwards into a category branch.
4. Ensure the project builds (`./build.sh`) and relevant checks pass before pushing.
5. Include before/after screenshots for any visible UI change.
6. Integrate by opening a PR from your category branch into `develop`. Release merges
   promote `develop` → `main`.
7. Create a temporary branch (`experiment/…`, `prototype/…`, `migration/…`,
   `refactor/…`) only when isolation is genuinely useful; accepted work folds back
   into a category branch first, and rejected work is deleted.
8. Do not commit build artifacts (`Lucid`, `Lucid.app`, `*.dmg`, `scratch/`) — they
   are covered by `.gitignore`.

## Reporting issues

Use the issue templates. For bugs, include your macOS version, whether you're on
Apple Silicon, steps to reproduce, and a sample Markdown snippet when relevant.
