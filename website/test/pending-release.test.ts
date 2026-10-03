import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { pendingRelease } from "../lib/pending-release";
import { currentRelease } from "../lib/release";
import { GET as appcast } from "../app/api/appcast/route";
import { GET as download } from "../app/api/download/route";

describe("Unpublished candidate safety", () => {
  it("matches the candidate app version and build without changing public downloads", async () => {
    const plist = readFileSync(new URL("../../Info.plist", import.meta.url), "utf8");
    expect(plist).toMatch(new RegExp(`<key>CFBundleShortVersionString</key>\\s*<string>${pendingRelease.version.replaceAll(".", "\\.")}</string>`));
    expect(plist).toMatch(new RegExp(`<key>CFBundleVersion</key>\\s*<string>${pendingRelease.buildNumber}</string>`));
    expect(pendingRelease.buildNumber).toBeGreaterThan(currentRelease.buildNumber);
    const response = await download();
    expect(response.headers.get("Location")).toBe(currentRelease.downloadUrl);
    expect(response.headers.get("Location")).not.toContain(`/v${pendingRelease.version}/`);
    const feed = await (await appcast()).text();
    expect(feed).toContain(`<sparkle:shortVersionString>${currentRelease.version}</sparkle:shortVersionString>`);
    expect(feed).not.toContain(`<sparkle:shortVersionString>${pendingRelease.version}</sparkle:shortVersionString>`);
  });
});
