import { NextResponse } from "next/server";
import { currentRelease, ReleaseMetadata } from "@/lib/release";

function escapeXml(unsafe: string): string {
  return unsafe.replace(/[<>&'"]/g, (c) => {
    switch (c) {
      case "<": return "&lt;";
      case ">": return "&gt;";
      case "&": return "&amp;";
      case "'": return "&apos;";
      case '"': return "&quot;";
      default: return c;
    }
  });
}

export function generateAppcastXml(release: ReleaseMetadata = currentRelease): string {
  const channelLink = "https://website-phi-umber-70.vercel.app/api/appcast";
  const channelTitle = "Lucid Updates";
  const channelDescription = "Software updates for Lucid, a native macOS Markdown reader and editor.";

  let itemXml = "";
  if (release.sparklePublished && release.sparkleEdSignature && release.sizeBytes > 0) {
    const itemTitle = escapeXml(`${release.productName} ${release.version}`);
    const enclosureUrl = escapeXml(release.downloadUrl);
    const signature = escapeXml(release.sparkleEdSignature);
    const notesUrl = release.releaseNotesUrl.startsWith("http")
      ? escapeXml(release.releaseNotesUrl)
      : escapeXml(`https://website-phi-umber-70.vercel.app${release.releaseNotesUrl}`);
    const pubDate = new Date(release.releaseDate).toUTCString();

    itemXml = `        <item>
            <title>${itemTitle}</title>
            <link>${channelLink}</link>
            <sparkle:version>${release.buildNumber}</sparkle:version>
            <sparkle:shortVersionString>${escapeXml(release.version)}</sparkle:shortVersionString>
            <sparkle:releaseNotesLink>${notesUrl}</sparkle:releaseNotesLink>
            <pubDate>${pubDate}</pubDate>
            <enclosure
                url="${enclosureUrl}"
                length="${release.sizeBytes}"
                type="application/octet-stream"
                sparkle:edSignature="${signature}" />
            <sparkle:minimumSystemVersion>${escapeXml(release.minimumMacOS)}</sparkle:minimumSystemVersion>
        </item>`;
  }

  return `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>${escapeXml(channelTitle)}</title>
        <link>${channelLink}</link>
        <description>${escapeXml(channelDescription)}</description>
        <language>en</language>
${itemXml ? itemXml + "\n" : ""}    </channel>
</rss>
`;
}

export async function GET() {
  const xml = generateAppcastXml(currentRelease);
  return new NextResponse(xml, {
    status: 200,
    headers: {
      "Content-Type": "application/rss+xml; charset=utf-8",
      "Cache-Control": "public, max-age=300, s-maxage=300",
    },
  });
}
