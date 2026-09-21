#!/bin/bash
set -euo pipefail

# scripts/sparkle-sign-release.sh
#
# Cryptographically sign a canonical release DMG using Sparkle's official EdDSA
# signing tool (`sign_update`) and extract length and signature attributes.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$DIR/.." && pwd )"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-dmg>" >&2
  echo "Example: $0 Lucid-1.0.3.dmg" >&2
  exit 1
fi

DMG_PATH="$1"

if [ ! -f "$DMG_PATH" ]; then
  echo "Error: Release artifact not found: $DMG_PATH" >&2
  exit 1
fi

# Verify filename pattern
DMG_BASENAME="$(basename "$DMG_PATH")"
if [[ ! "$DMG_BASENAME" =~ ^Lucid-[0-9]+\.[0-9]+\.[0-9]+.*\.dmg$ ]]; then
  echo "Error: Artifact filename does not match expected release format (Lucid-<version>.dmg): $DMG_BASENAME" >&2
  exit 1
fi

# Locate sign_update tool
SIGN_UPDATE=""
CANDIDATE_PATHS=(
  "$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/sign_update"
  "/tmp/sparkle_tools/bin/sign_update"
  "$(which sign_update 2>/dev/null || true)"
)

for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -n "$p" ] && [ -x "$p" ]; then
    SIGN_UPDATE="$p"
    break
  fi
done

if [ -z "$SIGN_UPDATE" ]; then
  echo "Error: Sparkle sign_update tool not found." >&2
  echo "Ensure Sparkle SPM dependencies are resolved or sign_update is in PATH." >&2
  exit 1
fi

# Compute exact byte size
BYTE_SIZE="$(stat -f%z "$DMG_PATH" 2>/dev/null || wc -c < "$DMG_PATH" | tr -d ' ')"

# Generate Sparkle EdDSA signature
# sign_update outputs: sparkle:edSignature="..." length="..."
SIGN_OUTPUT="$("$SIGN_UPDATE" "$DMG_PATH")"

if [ -z "$SIGN_OUTPUT" ]; then
  echo "Error: sign_update produced empty output." >&2
  exit 1
fi

ED_SIGNATURE="$(echo "$SIGN_OUTPUT" | sed -E 's/.*sparkle:edSignature="([^"]+)".*/\1/' | tr -d '[:space:]')"

if [ -z "$ED_SIGNATURE" ] || [ "$ED_SIGNATURE" = "$SIGN_OUTPUT" ]; then
  echo "Error: Failed to parse sparkle:edSignature from sign_update output:" >&2
  echo "$SIGN_OUTPUT" >&2
  exit 1
fi

# Verify signature immediately using sign_update --verify
"$SIGN_UPDATE" --verify "$DMG_PATH" "$ED_SIGNATURE" >/dev/null

echo "==> Sparkle EdDSA Signing Verified Successfully"
echo "Artifact:  $DMG_BASENAME"
echo "Length:    $BYTE_SIZE"
echo "Signature: $ED_SIGNATURE"
