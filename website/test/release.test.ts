import { describe, it, expect } from "vitest";
import { currentRelease, systemRequirements } from "../lib/release";
import { changelogData } from "../lib/changelog";
import { siteConfig } from "../lib/site-config";
import { docsConfig } from "../lib/docs-config";

describe("Release Configuration", () => {
  it("has valid product release metadata", () => {
    expect(currentRelease.productName).toBe("Lucid");
    expect(currentRelease.version).toMatch(/^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$/);
    expect(currentRelease.releaseChannel).toBe("beta");
    expect(currentRelease.productState).toBe("publicBeta");
    expect(currentRelease.fileName).toMatch(/\.dmg$/);
    expect(currentRelease.fileSize).toMatch(/\d+(\.\d+)?\sMB/);
  });

  it("has a valid 64-character lowercase hex SHA-256 hash", () => {
    expect(currentRelease.sha256).toMatch(/^[a-f0-9]{64}$/);
  });

  it("reflects honest signing and notarization state", () => {
    // Verified: build is ad-hoc signed, not yet Apple Developer ID notarized
    expect(currentRelease.notarized).toBe(false);
    expect(currentRelease.developerIDSigned).toBe(false);
    expect(currentRelease.gatekeeperVerified).toBe(false);
  });

  it("specifies correct macOS system requirements", () => {
    expect(currentRelease.minimumMacOS).toBe("14.0");
    expect(currentRelease.minimumMacOSCodeName).toBe("Sonoma");
    expect(currentRelease.architectures).toContain("Apple Silicon (arm64)");

    const osReq = systemRequirements.find((r) => r.label === "Operating System");
    expect(osReq).toBeDefined();
    expect(osReq?.value).toContain("macOS 14.0 (Sonoma)");

    const archReq = systemRequirements.find((r) => r.label === "Architecture");
    expect(archReq).toBeDefined();
    expect(archReq?.value).toContain("Apple Silicon");
  });

  it("configures verified direct download URL and public release endpoint", () => {
    expect(currentRelease.hasPublicDownloadUrl).toBe(true);
    expect(currentRelease.downloadUrl).toBe(
      "https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.0/Lucid-1.0.0.dmg"
    );
    expect(currentRelease.githubReleaseUrl).toBe(
      "https://github.com/ajayuhjain89/lucid-macos/releases/tag/v1.0.0"
    );
  });
});

describe("Changelog & Documentation Integrity", () => {
  it("includes changelog notes for current release version", () => {
    const currentEntry = changelogData.find((entry) => entry.version === currentRelease.version);
    expect(currentEntry).toBeDefined();
    expect(currentEntry?.highlights.length).toBeGreaterThan(0);
    expect(currentEntry?.sections.length).toBeGreaterThan(0);

    // Verify all items in sections have valid types
    currentEntry?.sections.forEach((sec) => {
      expect(sec.title).toBeTruthy();
      expect(sec.items.length).toBeGreaterThan(0);
      sec.items.forEach((item) => {
        expect(["new", "improved", "fixed"]).toContain(item.type);
        expect(item.text).toBeTruthy();
      });
    });
  });

  it("has complete site navigation structure", () => {
    const navLabels = siteConfig.nav.map((n) => n.label);
    expect(navLabels).toContain("Features");
    expect(navLabels).toContain("Docs");
    expect(navLabels).toContain("Changelog");
    expect(navLabels).toContain("Download");
  });

  it("has documentation sections with valid links", () => {
    expect(docsConfig.sections.length).toBeGreaterThan(0);
    docsConfig.sections.forEach((sec) => {
      expect(sec.id).toBeTruthy();
      expect(sec.title).toBeTruthy();
      expect(sec.items.length).toBeGreaterThan(0);
      sec.items.forEach((item) => {
        expect(item.href).toMatch(/^\/docs/);
        expect(item.title).toBeTruthy();
      });
    });
  });
});
