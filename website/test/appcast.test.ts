import { describe, it, expect } from "vitest";
import { generateAppcastXml, GET } from "../app/api/appcast/route";
import { currentRelease, ReleaseMetadata } from "../lib/release";

describe("Sparkle Appcast Feed", () => {
  it("returns application/rss+xml content type and 200 status from GET handler", async () => {
    const response = await GET();
    expect(response.status).toBe(200);
    expect(response.headers.get("Content-Type")).toContain("application/rss+xml");
  });

  it("generates valid XML with Sparkle namespaces", () => {
    const xml = generateAppcastXml(currentRelease);
    expect(xml).toContain('<?xml version="1.0" encoding="utf-8"?>');
    expect(xml).toContain('<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"');
    expect(xml).toContain("<channel>");
    expect(xml).toContain("<title>Lucid Updates</title>");
    expect(xml).toContain("</channel>");
    expect(xml).toContain("</rss>");
  });

  it("does not advertise unverified/staged release when sparklePublished is false", () => {
    const stagedRelease: ReleaseMetadata = {
      ...currentRelease,
      sparklePublished: false,
    };
    const xml = generateAppcastXml(stagedRelease);
    expect(xml).not.toContain("<item>");
    expect(xml).not.toContain("<enclosure");
  });

  it("advertises release item with correct Sparkle attributes when sparklePublished is true", () => {
    const activeRelease: ReleaseMetadata = {
      ...currentRelease,
      version: "1.0.3",
      buildNumber: 4,
      downloadUrl: "https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.3/Lucid-1.0.3.dmg",
      sizeBytes: 5262700,
      sparkleEdSignature: "dGVzdC1lZGRzYS1zaWduYXR1cmUtZm9yLXZlcmlmaWNhdGlvbg==",
      sparklePublished: true,
      minimumMacOS: "14.0",
      releaseNotesUrl: "/changelog#1-0-3",
    };

    const xml = generateAppcastXml(activeRelease);
    expect(xml).toContain("<item>");
    expect(xml).toContain("<sparkle:version>4</sparkle:version>");
    expect(xml).toContain("<sparkle:shortVersionString>1.0.3</sparkle:shortVersionString>");
    expect(xml).toContain("<sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>");
    expect(xml).toContain('url="https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.3/Lucid-1.0.3.dmg"');
    expect(xml).toContain('length="5262700"');
    expect(xml).toContain('sparkle:edSignature="dGVzdC1lZGRzYS1zaWduYXR1cmUtZm9yLXZlcmlmaWNhdGlvbg=="');
    expect(xml).toContain("<sparkle:releaseNotesLink>https://website-phi-umber-70.vercel.app/changelog#1-0-3</sparkle:releaseNotesLink>");
  });

  it("escapes special XML characters in release fields", () => {
    const specialRelease: ReleaseMetadata = {
      ...currentRelease,
      productName: "Lucid & Friends <Beta>",
      version: '1.0.3"test',
      buildNumber: 4,
      sizeBytes: 12345,
      sparkleEdSignature: "abc&123",
      sparklePublished: true,
    };
    const xml = generateAppcastXml(specialRelease);
    expect(xml).toContain("Lucid &amp; Friends &lt;Beta&gt;");
    expect(xml).toContain("sparkle:edSignature=\"abc&amp;123\"");
  });
});
