import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";
import { currentRelease } from "../lib/release";

function validateRelease() {
  console.log("==> Validating release metadata...");

  const errors: string[] = [];

  // 1. Version format (semver-like)
  if (!/^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$/.test(currentRelease.version)) {
    errors.push(`Invalid version format: "${currentRelease.version}"`);
  }

  // 2. SHA-256 format (64-character lowercase hex)
  if (!/^[a-f0-9]{64}$/.test(currentRelease.sha256)) {
    errors.push(`Invalid SHA-256 format: "${currentRelease.sha256}"`);
  }

  // 3. File name
  if (!currentRelease.fileName || !currentRelease.fileName.endsWith(".dmg")) {
    errors.push(`Invalid fileName: "${currentRelease.fileName}"`);
  }

  // 4. Check if local artifact exists to verify hash directly
  const candidatePaths = [
    path.resolve(__dirname, "../../", currentRelease.fileName),
    path.resolve(process.cwd(), currentRelease.fileName),
    path.resolve(process.cwd(), "../", currentRelease.fileName),
  ];

  let localArtifactFound = false;
  for (const p of candidatePaths) {
    if (fs.existsSync(p)) {
      localArtifactFound = true;
      console.log(`Found local DMG artifact at: ${p}`);
      const fileBuffer = fs.readFileSync(p);
      const computedHash = crypto.createHash("sha256").update(fileBuffer).digest("hex");
      if (computedHash !== currentRelease.sha256) {
        errors.push(`SHA-256 mismatch! Config has: ${currentRelease.sha256}, actual file has: ${computedHash}`);
      } else {
        console.log(`✓ SHA-256 hash matches local artifact: ${computedHash}`);
      }
      break;
    }
  }

  if (!localArtifactFound) {
    console.log(`Note: No local artifact "${currentRelease.fileName}" found in search paths. Skipping byte-for-byte verification.`);
  }

  if (errors.length > 0) {
    console.error("❌ Release validation failed:");
    errors.forEach((err) => console.error(`  - ${err}`));
    process.exit(1);
  }

  console.log("✓ Release configuration is valid.");
}

validateRelease();
