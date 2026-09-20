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

## Updating Releases

When a new version of Lucid is built:

1. **Calculate Checksum**:
   ```bash
   npx tsx scripts/checksum.ts ../Lucid-X.Y.Z.dmg
   ```

2. **Update `lib/release.ts`**:
   - Update `version`, `releaseDate`, `fileName`, `fileSize`, and `sha256`.
   - Update `downloadUrl` and set `hasPublicDownloadUrl: true` when published.

3. **Update `lib/changelog.ts`**:
   - Add new entry with release highlights and categorized changes (New, Improved, Fixed).

4. **Verify**:
   ```bash
   npx tsx scripts/validate-release.ts
   npm test
   npm run build
   ```

---

## License

MIT License. Copyright © 2026 Ayush Jain.
