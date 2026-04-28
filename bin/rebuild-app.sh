#!/bin/bash
# Rebuild and install NanoReminder.app to /Applications

set -euo pipefail

NANO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$NANO_DIR/NanoReminder"
BUILD_DIR="$APP_DIR/.build/arm64-apple-macosx/release"
APP_BUNDLE="/Applications/NanoReminder.app"

echo "1. Building NanoReminder in release mode..."
(cd "$APP_DIR" && swift build -c release)

echo "2. Cleaning old app bundle..."
rm -rf "$APP_BUNDLE"

echo "3. Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "4. Copying binary and resources..."
cp "$BUILD_DIR/NanoReminder" "$APP_BUNDLE/Contents/MacOS/"
cp "$APP_DIR/Sources/NanoReminder/Assets/nano-face-cute-real.png" "$APP_BUNDLE/Contents/Resources/"
if [[ -f /tmp/nano-icon.icns ]]; then
  cp /tmp/nano-icon.icns "$APP_BUNDLE/Contents/Resources/NanoReminder.icns"
fi

echo "5. Writing Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NanoReminder</string>
    <key>CFBundleIconFile</key>
    <string>NanoReminder</string>
    <key>CFBundleIconName</key>
    <string>NanoReminder</string>
    <key>CFBundleIdentifier</key>
    <string>com.nanoreminder.app</string>
    <key>CFBundleName</key>
    <string>NanoReminder</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 NanoReminder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
</dict>
</plist>
PLIST

echo "6. Setting permissions..."
chmod +x "$APP_BUNDLE/Contents/MacOS/NanoReminder"

echo ""
echo "NanoReminder.app installed to $APP_BUNDLE"
ls -la "$APP_BUNDLE/Contents/MacOS/"
ls -la "$APP_BUNDLE/Contents/Resources/"
