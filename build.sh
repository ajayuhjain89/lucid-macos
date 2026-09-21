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

for arg in "$@"; do
  case "$arg" in
    --release)
      RELEASE_MODE=true
      ;;
    --overwrite|--force)
      OVERWRITE=true
      ;;
    --help|-h)
      echo "Usage: ./build.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --release    Package a versioned release artifact (Lucid-<version>.dmg)."
      echo "               Refuses to overwrite an existing release artifact unless --overwrite is passed."
      echo "  --overwrite  Allow overwriting an existing release artifact when --release is specified."
      echo "  --help, -h   Show this help message."
      echo ""
      echo "Default (no flags): Produces Lucid.app and a local development disk image (Lucid-local.dmg)."
      echo "                    Never modifies or overwrites canonical release artifacts."
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
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

echo "==> Compiling $APP_NAME for macOS (arm64)..."
swift build -c release --arch arm64 -Xlinker -rpath -Xlinker @executable_path/../Frameworks

echo "==> Creating application bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

cp "$DIR/.build/arm64-apple-macosx/release/$APP_NAME" "$MACOS/$APP_NAME"
cp "$DIR/Info.plist" "$CONTENTS/Info.plist"
echo "APPL????" > "$CONTENTS/PkgInfo"

if [ -f "$DIR/AppIcon.icns" ]; then
  cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

echo "==> Copying WebEngine resources..."
cp -R "$DIR/Sources/Lucid/Resources/WebEngine" "$RESOURCES/WebEngine"

echo "==> Copying Sparkle framework..."
cp -R "$DIR/.build/arm64-apple-macosx/release/Sparkle.framework" "$FRAMEWORKS/"

echo "==> Signing application bundle (inside-out)..."
SPARKLE_DIR="$FRAMEWORKS/Sparkle.framework"
if [ -d "$SPARKLE_DIR" ]; then
  codesign --force -s - "$SPARKLE_DIR/Versions/B/XPCServices/Downloader.xpc"
  codesign --force -s - "$SPARKLE_DIR/Versions/B/XPCServices/Installer.xpc"
  codesign --force -s - "$SPARKLE_DIR/Versions/B/Autoupdate"
  codesign --force -s - "$SPARKLE_DIR/Versions/B/Updater.app"
  codesign --force -s - "$SPARKLE_DIR/Versions/B"
fi
codesign --force -s - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "==> Done! $APP_BUNDLE is ready."

echo "==> Creating DMG installer ($DMG_NAME)..."
DMG_STAGING="$DIR/.dmg_staging"
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_STAGING"

echo ""
if [ "$RELEASE_MODE" = "true" ]; then
  echo "Release packaging complete:"
  echo "  App: $APP_BUNDLE"
  echo "  Release DMG: $DMG_PATH"
else
  echo "Build complete:"
  echo "  App: $APP_BUNDLE"
  echo "  Local DMG: $DMG_PATH"
  echo ""
  echo "This is a local development artifact and is not the published release binary."
fi
