/**
 * Centralized Release Configuration
 * 
 * Single source of truth for all release, download, and verification metadata.
 * Every component on the website (hero CTA, /download page, /api/download, changelog)
 * reads from this file.
 */

export type ProductReleaseState = "development" | "privateBeta" | "publicBeta" | "stable";

export interface ReleaseMetadata {
  productName: string;
  version: string;
  buildNumber: number;
  productState: ProductReleaseState;
  releaseChannel: "stable" | "beta" | "preview";
  releaseDate: string; // ISO date string (YYYY-MM-DD)
  
  // Artifact details (verified from local build Lucid-1.0.0.dmg)
  fileName: string;
  fileSize: string;
  sizeBytes: number;
  sha256: string;
  
  // Sparkle update metadata
  sparkleEdSignature?: string;
  sparklePublished: boolean;
  
  // Target environment (verified from Info.plist and build.sh)
  minimumMacOS: string;
  minimumMacOSCodeName: string;
  architectures: ("Apple Silicon (arm64)" | "Intel (x86_64)")[];
  
  // Signing & verification (proven facts: ad-hoc signed, not notarized yet)
  notarized: boolean;
  developerIDSigned: boolean;
  gatekeeperVerified: boolean;
  
  // URLs & endpoints
  downloadUrl: string; // Remote URL where DMG is hosted (e.g. GitHub Releases)
  hasPublicDownloadUrl: boolean; // Set to true once the asset is published to GitHub Releases/CDN
  githubReleaseUrl?: string;
  releaseNotesUrl: string;
  
  // Performance benchmarks flag
  showPerformanceBenchmarks: boolean;
}

export const currentRelease: ReleaseMetadata = {
  productName: "Lucid",
  version: "1.0.7",
  buildNumber: 8,
  productState: "publicBeta",
  releaseChannel: "beta",
  releaseDate: "2026-09-29",
  
  // Exact properties from canonical artifact Lucid-1.0.7.dmg
  fileName: "Lucid-1.0.7.dmg",
  fileSize: "6.4 MB",
  sizeBytes: 6743060,
  sha256: "175805b93b16a693ac59989d71b53b2ffccf49f29ddd519a0727c327efee7d25",
  
  // Sparkle update publication (verified against published GitHub release asset)
  sparkleEdSignature: "f7HZF4Dpl52Uz5IaEHHd8UhPx5iCbu1C6YSzdC/gr6FwqxRCKge9YJOtlZvfE49V4IateDEug8lBytIS2B7TAg==",
  sparklePublished: true,
  
  // Environment requirements verified from Info.plist (LSMinimumSystemVersion 14.0) and build.sh (arm64-apple-macosx14.0)
  minimumMacOS: "14.0",
  minimumMacOSCodeName: "Sonoma",
  architectures: ["Apple Silicon (arm64)"],
  
  // Honesty: ad-hoc signed build, not Apple Developer ID notarized yet
  notarized: false,
  developerIDSigned: false,
  gatekeeperVerified: false,
  
  // URL configurations
  downloadUrl: "https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.7/Lucid-1.0.7.dmg",
  hasPublicDownloadUrl: true,
  githubReleaseUrl: "https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.7",
  releaseNotesUrl: "/changelog#1-0-7",
  
  // Kept false until official accepted benchmark numbers are measured
  showPerformanceBenchmarks: false,
};

export interface SystemRequirement {
  label: string;
  value: string;
  note?: string;
}

export const systemRequirements: SystemRequirement[] = [
  {
    label: "Operating System",
    value: `macOS ${currentRelease.minimumMacOS} (${currentRelease.minimumMacOSCodeName}) or later`,
    note: "Declared minimum: macOS 14.0. Candidate runtime checks currently cover macOS 27.0.1; older-OS qualification is pending.",
  },
  {
    label: "Architecture",
    value: currentRelease.architectures.join(", "),
    note: "M1, M2, M3, M4 or newer. Intel Macs are not currently supported.",
  },
  {
    label: "Distribution",
    value: "Direct DMG download & build from source",
    note: "Open source on GitHub (MIT License)",
  },
  {
    label: "Code Signing",
    value: "Ad-hoc signed (Beta)",
    note: "Public Developer ID signing and Apple notarization in progress for 1.0 stable",
  },
];
