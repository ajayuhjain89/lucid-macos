import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

function calculateChecksum() {
  const targetArg = process.argv[2];
  const targetPath = targetArg
    ? path.resolve(process.cwd(), targetArg)
    : path.resolve(__dirname, "../../Lucid-1.0.2.dmg");

  if (!fs.existsSync(targetPath)) {
    console.error(`Error: File not found at: ${targetPath}`);
    console.error("Usage: npx tsx scripts/checksum.ts [path/to/artifact.dmg]");
    process.exit(1);
  }

  const stat = fs.statSync(targetPath);
  const buffer = fs.readFileSync(targetPath);
  const sha256 = crypto.createHash("sha256").update(buffer).digest("hex");
  const sizeMb = (stat.size / (1024 * 1024)).toFixed(1);

  console.log("==> Artifact Checksum & Metadata:");
  console.log(`File:    ${path.basename(targetPath)}`);
  console.log(`Path:    ${targetPath}`);
  console.log(`Bytes:   ${stat.size} bytes`);
  console.log(`Size:    ${sizeMb} MB`);
  console.log(`SHA-256: ${sha256}`);
  console.log("\nSnippet for lib/release.ts:");
  console.log(`fileName: "${path.basename(targetPath)}",`);
  console.log(`fileSize: "${sizeMb} MB",`);
  console.log(`sha256: "${sha256}",`);
}

calculateChecksum();
