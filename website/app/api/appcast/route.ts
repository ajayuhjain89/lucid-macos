import { NextResponse } from "next/server";
import { currentRelease } from "@/lib/release";
import { generateAppcastXml } from "@/lib/appcast";

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
