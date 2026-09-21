import { describe, it, expect } from "vitest";
import { GET } from "../app/api/download/route";

describe("Download API Route (/api/download)", () => {
  it("returns a 307 temporary redirect to the verified direct GitHub DMG asset URL", async () => {
    const response = await GET();
    expect(response.status).toBe(307);
    expect(response.headers.get("location")).toBe(
      "https://github.com/ajayuhjain89/lucid-macos/releases/download/v1.0.2/Lucid-1.0.2.dmg"
    );
  });
});
