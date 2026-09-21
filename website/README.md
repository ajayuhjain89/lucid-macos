# Lucid Official Website

The public landing, documentation, and download website for **Lucid** — the native macOS Markdown reader and editor built for technical documents.

Built with Next.js 15 (App Router), React 19, TypeScript, and Tailwind CSS.

---

## Architecture & Design Principles

- **Editorial Typography**: 680px optimal prose measure, calibrated line heights, and restrained typography.
- **Varied Layout Rhythm**: Full-width breakout diagrams, technical detail cards, and interactive comparison previews instead of generic repeating SaaS grids.
- **Honest Product Proof**: Real application screenshots, verified SHA-256 checksums, and accurate signing status.
- **Zero Telemetry**: No tracking cookies, no third-party analytics SDKs, and no external font or script dependencies at runtime.

---

## Directory Structure

```
website/
├── app/
│   ├── layout.tsx                # Root layout (anti-flash theme script, Navbar, Footer)
│   ├── page.tsx                  # Homepage with editorial and technical sections
│   ├── download/page.tsx         # Dedicated download page with checksum verification
│   ├── features/page.tsx         # Comprehensive feature deep-dives
│   ├── docs/                     # Documentation hub & syntax cheat sheets
│   │   ├── page.tsx
│   │   └── getting-started/page.tsx
│   ├── changelog/page.tsx        # Version release notes & history
│   ├── privacy/page.tsx          # Local-first privacy policy
│   ├── support/page.tsx          # Troubleshooting & Gatekeeper guidance
│   ├── api/download/route.ts     # Dynamic 307 download redirect
│   ├── sitemap.ts & robots.ts   # Search engine discovery
│   └── not-found.tsx & error.tsx # Editorial error boundaries
├── components/
│   ├── layout/                   # Navbar, Footer
│   ├── sections/                 # Hero, PlatformStrip, TechnicalShowcase, etc.
│   └── ui/                       # Button, CopyButton, Lightbox, ThemeToggle, WindowFrame
├── lib/
│   ├── release.ts                # Single source of truth for release metadata & checksums
│   ├── site-config.ts            # Site navigation & URLs
│   ├── changelog.ts              # Structured release notes
│   └── docs-config.ts            # Documentation hierarchy
├── public/
│   └── images/app/               # Real application screenshots & icons
├── scripts/
│   ├── checksum.ts               # CLI utility to compute SHA-256 for DMG artifacts
│   └── validate-release.ts       # Release integrity validator
└── test/
    └── release.test.ts           # Vitest unit tests
```

---

## Local Development

### Prerequisites

- Node.js 20+ (or Node 18 LTS)
- npm 9+

### Setup

```bash
cd website
npm install
npm run dev
```

The site will be available at `http://localhost:3000`.

---

## Building & Verification

### Run Type Checking & Production Build

```bash
npm run build
```

### Run Tests

```bash
npm test
```

### Validate Release Metadata

```bash
npx tsx scripts/validate-release.ts
```

---

## Release & Download Architecture

The website provides a seamless one-click download experience for users while keeping repository and deployment footprints minimal:

```
website (Download button)
  → /api/download
  → HTTP 307 Temporary Redirect
  → GitHub Releases asset (Lucid-1.0.0.dmg)
```

- **Hosted on GitHub Releases**: The public DMG binary is hosted directly on GitHub Releases.
- **No Proxying / No Streaming**: Next.js / Vercel does not proxy or stream the binary.
- **Not Stored in `website/public`**: The DMG is not tracked in the web application static assets.
- **Single Source of Truth**: Release metadata and checksums live in [`website/lib/release.ts`](lib/release.ts).

---

## Release Process

When a new version of Lucid is prepared for release:

1. **Build and verify new DMG**: Build the native macOS artifact using `./build.sh` and verify application packaging.
2. **Calculate SHA-256**: Run `npx tsx scripts/checksum.ts ../Lucid-X.Y.Z.dmg` to generate the official checksum.
3. **Create/update GitHub Release**: Draft or publish the release tag (e.g. `vX.Y.Z`) on GitHub.
4. **Attach verified DMG**: Upload the verified DMG file to the GitHub Release.
5. **Update `website/lib/release.ts`**: Set `version`, `releaseDate`, `fileName`, `fileSize`, `sha256`, `downloadUrl`, and `hasPublicDownloadUrl: true`.
6. **Verify direct asset URL**: Confirm the direct GitHub Release asset URL returns HTTP 200/302.
7. **Verify `/api/download`**: Confirm the route issues an HTTP 307 redirect to the asset.
8. **Verify website Download button**: Test that clicking "Download Lucid" initiates the download immediately.
9. **Run validation, tests, and build**:
   ```bash
   npm run lint
   npm test
   npm run release:validate
   npm run build
   ```
10. **Promote through canonical workflow**: Land changes through `docs`/`logic` → `develop` → `main` as defined in `docs/github_workflow.md`.

---

## License

MIT License. Copyright © 2026 Ayush Jain.
