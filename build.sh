#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="Lucid"
APP_BUNDLE="$DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

RELEASE_MODE=false
OVERWRITE=false
NOTARIZE=false
IDENTITY=""
NOTARY_PROFILE="${NOTARY_PROFILE:-Lucid}"

while [ $# -gt 0 ]; do
  case "$1" in
    --release)
      RELEASE_MODE=true
      shift
      ;;
    --overwrite|--force)
      OVERWRITE=true
      shift
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --notarize)
      NOTARIZE=true
      shift
      ;;
    --keychain-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: ./build.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --release                Package a versioned release artifact (Lucid-<version>.dmg)."
      echo "                           Refuses to overwrite an existing release artifact unless --overwrite is passed."
      echo "  --overwrite              Allow overwriting an existing release artifact when --release is specified."
      echo "  --identity <name>        Code signing identity (defaults to DEVELOPER_ID_APPLICATION or ad-hoc '-')."
      echo "  --notarize               Submit the packaged release DMG to Apple for notarization and staple tickets."
      echo "  --keychain-profile <p>   notarytool keychain profile name (default: Lucid)."
      echo "  --help, -h               Show this help message."
      echo ""
      echo "Default (no flags): Produces Lucid.app and a local development disk image (Lucid-local.dmg)."
      echo "                    Never modifies or overwrites canonical release artifacts."
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Run './build.sh --help' for usage." >&2
      exit 1
      ;;
  esac
done

# Determine target DMG name and enforce fail-safe overwrite protection early
if [ "$RELEASE_MODE" = "true" ]; then
  VERSION=""
  if [ -f "$DIR/Info.plist" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DIR/Info.plist" 2>/dev/null || true)
    if [ -z "$VERSION" ]; then
      VERSION=$(grep -A1 "CFBundleShortVersionString" "$DIR/Info.plist" | grep "<string>" | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | tr -d '[:space:]')
    fi
  fi

  if [ -z "$VERSION" ]; then
    echo "Error: Could not determine version from Info.plist for release packaging." >&2
    exit 1
  fi

  DMG_NAME="$APP_NAME-$VERSION.dmg"
  DMG_PATH="$DIR/$DMG_NAME"

  if [ -f "$DMG_PATH" ] && [ "$OVERWRITE" != "true" ]; then
    echo "Error: Release artifact already exists: $DMG_NAME" >&2
    echo "Refusing to overwrite canonical release artifact." >&2
    echo "Pass --overwrite explicitly if you intentionally want to replace it." >&2
    exit 1
  fi
else
  DMG_NAME="$APP_NAME-local.dmg"
  DMG_PATH="$DIR/$DMG_NAME"

  # Safeguard: ensure local development build never writes to a versioned release artifact
  if [[ "$DMG_NAME" =~ ^$APP_NAME-[0-9]+\.[0-9]+\.[0-9]+.*\.dmg$ ]]; then
    echo "Error: Local build attempted to use release artifact filename: $DMG_NAME" >&2
    exit 1
  fi
fi

FRAMEWORKS="$CONTENTS/Frameworks"

if [[ -z "${SDKROOT:-}" && -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk" ]]; then
  export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
fi

echo "==> Compiling $APP_NAME for macOS (arm64)..."
SWIFT_BUILD_ARGS=(-c release --arch arm64 -Xlinker -rpath -Xlinker @executable_path/../Frameworks)
if ! swift build "${SWIFT_BUILD_ARGS[@]}"; then
  echo "Error: swift build failed." >&2
  echo "If the errors mention SwiftUIMacros or @State, the active SDK lacks the SwiftUI macro plugins" >&2
  echo "(e.g. Command Line Tools for macOS 27). Install Xcode, or point SDKROOT at an SDK that has them:" >&2
  echo "  SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ./build.sh" >&2
  exit 1
fi
# The build output directory differs between SwiftPM build systems; ask SwiftPM for it.
BIN_DIR="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"

echo "==> Creating application bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

cp "$BIN_DIR/$APP_NAME" "$MACOS/$APP_NAME"
cp "$DIR/Info.plist" "$CONTENTS/Info.plist"
echo "APPL????" > "$CONTENTS/PkgInfo"

if [ -f "$DIR/AppIcon.icns" ]; then
  cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

echo "==> Copying WebEngine resources..."
cp -R "$DIR/Sources/Lucid/Resources/WebEngine" "$RESOURCES/WebEngine"

echo "==> Copying Sparkle framework..."
cp -R "$BIN_DIR/Sparkle.framework" "$FRAMEWORKS/"

# Resolve signing identity
SIGN_IDENTITY="${IDENTITY:-${DEVELOPER_ID_APPLICATION:-${CODE_SIGN_IDENTITY:-}}}"
if [ -z "$SIGN_IDENTITY" ]; then
  DEV_ID="$(security find-identity -p codesigning -v 2>/dev/null | grep 'Developer ID Application:' | head -n1 | sed -E 's/.*"Developer ID Application: ([^"]+)".*/Developer ID Application: \1/' || true)"
  if [ -n "$DEV_ID" ]; then
    SIGN_IDENTITY="$DEV_ID"
    echo "==> Using detected Developer ID signing identity: $SIGN_IDENTITY"
  else
    SIGN_IDENTITY="-"
  fi
fi

SPARKLE_DIR="$FRAMEWORKS/Sparkle.framework"

if [ "$SIGN_IDENTITY" = "-" ]; then
  echo "==> Signing application bundle (ad-hoc)..."
  if [ -d "$SPARKLE_DIR" ]; then
    codesign --force -s - "$SPARKLE_DIR/Versions/B/XPCServices/Downloader.xpc"
    codesign --force -s - "$SPARKLE_DIR/Versions/B/XPCServices/Installer.xpc"
    codesign --force -s - "$SPARKLE_DIR/Versions/B/Autoupdate"
    codesign --force -s - "$SPARKLE_DIR/Versions/B/Updater.app"
    codesign --force -s - "$SPARKLE_DIR/Versions/B"
  fi
  codesign --force -s - "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
else
  echo "==> Signing application bundle with Developer ID ($SIGN_IDENTITY)..."
  ENTITLEMENTS_ARGS=()
  if [ -f "$DIR/Lucid.entitlements" ]; then
    ENTITLEMENTS_ARGS=(--entitlements "$DIR/Lucid.entitlements")
  fi
  if [ -d "$SPARKLE_DIR" ]; then
    codesign --force --timestamp --options runtime -s "$SIGN_IDENTITY" "$SPARKLE_DIR/Versions/B/XPCServices/Downloader.xpc"
    codesign --force --timestamp --options runtime -s "$SIGN_IDENTITY" "$SPARKLE_DIR/Versions/B/XPCServices/Installer.xpc"
    codesign --force --timestamp --options runtime -s "$SIGN_IDENTITY" "$SPARKLE_DIR/Versions/B/Autoupdate"
    codesign --force --timestamp --options runtime -s "$SIGN_IDENTITY" "$SPARKLE_DIR/Versions/B/Updater.app"
    codesign --force --timestamp --options runtime -s "$SIGN_IDENTITY" "$SPARKLE_DIR/Versions/B"
  fi
  codesign --force --timestamp --options runtime "${ENTITLEMENTS_ARGS[@]}" -s "$SIGN_IDENTITY" "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
  spctl --assess --type exec -vv "$APP_BUNDLE" || true
fi

echo "==> Done! $APP_BUNDLE is ready."

echo "==> Creating DMG installer ($DMG_NAME)..."
DMG_STAGING="$DIR/.dmg_staging"
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_STAGING"

if [ "$SIGN_IDENTITY" != "-" ]; then
  echo "==> Signing DMG installer ($DMG_NAME)..."
  codesign --force --timestamp -s "$SIGN_IDENTITY" "$DMG_PATH"
fi

if [ "$NOTARIZE" = "true" ]; then
  echo "==> Submitting DMG to Apple for notarization..."
  if ! command -v xcrun &>/dev/null; then
    echo "Error: xcrun not found for notarization." >&2
    exit 1
  fi
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  echo "==> Stapling notarization ticket to DMG..."
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler staple "$APP_BUNDLE" 2>/dev/null || true
  spctl --assess --type open --context context:primary-signature -vv "$DMG_PATH" || true
fi

echo ""
if [ "$RELEASE_MODE" = "true" ]; then
  echo "Release packaging complete:"
  echo "  App: $APP_BUNDLE"
  echo "  Release DMG: $DMG_PATH"
  if [ "$SIGN_IDENTITY" = "-" ]; then
    echo ""
    echo "  NOTE: Packaged with ad-hoc signature (-). Developer ID signing and notarization"
    echo "        are required before publishing as a stable public release."
  fi
else
  echo "Build complete:"
  echo "  App: $APP_BUNDLE"
  echo "  Local DMG: $DMG_PATH"
  echo ""
  echo "This is a local development artifact and is not the published release binary."
fi
