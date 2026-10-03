import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { pendingRelease } from "../lib/pending-release";
import { currentRelease } from "../lib/release";
import { GET as appcast } from "../app/api/appcast/route";
import { GET as download } from "../app/api/download/route";

describe("Release candidate safety", () => {
  it("matches the app version and build in Info.plist and publishes correct endpoints", async () => {
    const plist = readFileSync(new URL("../../Info.plist", import.meta.url), "utf8");
    expect(plist).toMatch(new RegExp(`<key>CFBundleShortVersionString</key>\\s*<string>${currentRelease.version.replaceAll(".", "\\.")}</string>`));
    expect(plist).toMatch(new RegExp(`<key>CFBundleVersion</key>\\s*<string>${currentRelease.buildNumber}</string>`));
    const response = await download();
    expect(response.headers.get("Location")).toBe(currentRelease.downloadUrl);
    const feed = await (await appcast()).text();
    expect(feed).toContain(`<sparkle:shortVersionString>${currentRelease.version}</sparkle:shortVersionString>`);
  });
});
