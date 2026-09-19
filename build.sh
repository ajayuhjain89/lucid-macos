#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="Lucid"
APP_BUNDLE="$DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Compiling $APP_NAME for macOS (arm64)..."
swiftc -parse-as-library -target arm64-apple-macosx14.0 -O \
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
