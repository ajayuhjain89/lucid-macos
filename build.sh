#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="Lucid"
APP_BUNDLE="$DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Compiling $APP_NAME for macOS (arm64)..."
mkdir -p "$DIR/scratch/ModuleCache"
# Pin the Swift 5 language mode so the build is deterministic across toolchains
# (newer Xcode defaults `swiftc` to Swift 6 mode, whose stricter actor isolation
# the codebase is not written against).
swiftc -parse-as-library -target arm64-apple-macosx14.0 -O -swift-version 5 \
  -module-cache-path "$DIR/scratch/ModuleCache" \
  -o "$DIR/$APP_NAME" \
  $(find "$DIR/Sources/Lucid" -name "*.swift")

echo "==> Creating application bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$DIR/$APP_NAME" "$MACOS/$APP_NAME"
cp "$DIR/Info.plist" "$CONTENTS/Info.plist"
echo "APPL????" > "$CONTENTS/PkgInfo"

if [ -f "$DIR/AppIcon.icns" ]; then
  cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

echo "==> Copying WebEngine resources..."
cp -R "$DIR/Sources/Lucid/Resources/WebEngine" "$RESOURCES/WebEngine"

echo "==> Signing application bundle..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "==> Done! $APP_BUNDLE is ready."

echo "==> Creating DMG installer..."
DMG_PATH="$DIR/$APP_NAME-1.0.0.dmg"
DMG_STAGING="$DIR/.dmg_staging"
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_STAGING"

echo "==> DMG Installer created at $DMG_PATH"
