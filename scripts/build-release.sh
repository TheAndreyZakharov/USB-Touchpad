#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ANDROID_DIR="$ROOT_DIR/android-app"
MACOS_DIR="$ROOT_DIR/macos-app"
ASSETS_DIR="$ROOT_DIR/assets"

RELEASE_DIR="$ROOT_DIR/release"
APP_NAME="Touchpad"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"

VERSION="${1:-1.0.0}"

echo "Building Touchpad release $VERSION"
echo

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# ------------------------------------------------------------
# Android
# ------------------------------------------------------------

echo "Building Android APK..."

cd "$ANDROID_DIR"
./gradlew clean assembleDebug

ANDROID_APK="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"

if [ ! -f "$ANDROID_APK" ]; then
    echo "Android APK was not created."
    exit 1
fi

cp \
    "$ANDROID_APK" \
    "$RELEASE_DIR/Touchpad-Android-$VERSION.apk"

echo "Android APK created."

# ------------------------------------------------------------
# macOS
# ------------------------------------------------------------

echo
echo "Building macOS application..."

cd "$MACOS_DIR"
swift build -c release --product Touchpad

MACOS_BINARY="$MACOS_DIR/.build/release/Touchpad"

if [ ! -f "$MACOS_BINARY" ]; then
    echo "macOS executable was not created."
    exit 1
fi

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp \
    "$MACOS_BINARY" \
    "$APP_BUNDLE/Contents/MacOS/Touchpad"

chmod +x "$APP_BUNDLE/Contents/MacOS/Touchpad"

# ------------------------------------------------------------
# Swift Package resources
# ------------------------------------------------------------

find "$MACOS_DIR/.build/release" \
    -maxdepth 1 \
    -type d \
    -name "*.bundle" \
    -exec cp -R {} "$APP_BUNDLE/Contents/Resources/" \;

if [ -f "$ASSETS_DIR/app-icon.png" ]; then
    cp \
        "$ASSETS_DIR/app-icon.png" \
        "$APP_BUNDLE/Contents/Resources/app-icon.png"
fi

# ------------------------------------------------------------
# macOS icon
# ------------------------------------------------------------

ICON_SOURCE="$ASSETS_DIR/app-icon.png"
ICONSET_DIR="$RELEASE_DIR/AppIcon.iconset"
ICNS_FILE="$APP_BUNDLE/Contents/Resources/AppIcon.icns"

if [ -f "$ICON_SOURCE" ]; then
    echo "Generating macOS icon..."

    mkdir -p "$ICONSET_DIR"

    sips -z 16 16 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_16x16.png" \
        >/dev/null

    sips -z 32 32 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_16x16@2x.png" \
        >/dev/null

    sips -z 32 32 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_32x32.png" \
        >/dev/null

    sips -z 64 64 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_32x32@2x.png" \
        >/dev/null

    sips -z 128 128 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_128x128.png" \
        >/dev/null

    sips -z 256 256 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_128x128@2x.png" \
        >/dev/null

    sips -z 256 256 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_256x256.png" \
        >/dev/null

    sips -z 512 512 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_256x256@2x.png" \
        >/dev/null

    sips -z 512 512 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_512x512.png" \
        >/dev/null

    sips -z 1024 1024 \
        "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_512x512@2x.png" \
        >/dev/null

    iconutil \
        -c icns \
        -o "$ICNS_FILE" \
        "$ICONSET_DIR"

    rm -rf "$ICONSET_DIR"
fi

# ------------------------------------------------------------
# Info.plist
# ------------------------------------------------------------

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>

    <key>CFBundleDisplayName</key>
    <string>Touchpad</string>

    <key>CFBundleExecutable</key>
    <string>Touchpad</string>

    <key>CFBundleIconFile</key>
    <string>AppIcon</string>

    <key>CFBundleIdentifier</key>
    <string>com.theandreyzakharov.usbtouchpad</string>

    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>

    <key>CFBundleName</key>
    <string>Touchpad</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>

    <key>CFBundleVersion</key>
    <string>$VERSION</string>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>LSUIElement</key>
    <true/>

    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Andrey Zakharov</string>
</dict>
</plist>
EOF

# ------------------------------------------------------------
# Signing
# ------------------------------------------------------------

echo "Signing macOS application..."

codesign \
    --force \
    --deep \
    --sign - \
    "$APP_BUNDLE"

codesign \
    --verify \
    --deep \
    --strict \
    "$APP_BUNDLE"

# ------------------------------------------------------------
# Archive
# ------------------------------------------------------------

echo "Creating macOS ZIP..."

cd "$RELEASE_DIR"

ditto \
    -c \
    -k \
    --sequesterRsrc \
    --keepParent \
    "$APP_NAME.app" \
    "Touchpad-macOS-$VERSION.zip"

rm -rf "$APP_BUNDLE"

echo
echo "Release files created:"
echo

ls -lh "$RELEASE_DIR"
