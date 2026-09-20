import { NextResponse } from "next/server";
import { currentRelease } from "@/lib/release";
import { siteConfig } from "@/lib/site-config";

export async function GET() {
  if (currentRelease.hasPublicDownloadUrl && currentRelease.downloadUrl) {
    // 307 Temporary Redirect to ensure download triggers properly
    return NextResponse.redirect(currentRelease.downloadUrl, 307);
  }

  // If public binary is pending publication on GitHub releases, redirect to releases overview
  const fallbackUrl = currentRelease.githubReleaseUrl || siteConfig.githubUrl;
  return NextResponse.redirect(fallbackUrl, 307);
}
