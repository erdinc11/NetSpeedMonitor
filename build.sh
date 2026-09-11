#!/usr/bin/env bash
set -e

APP_NAME="NetSpeedMonitor"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🚀 Building NetSpeedMonitor (Universal Binary: Apple Silicon + Intel)..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

TMP_ARM64="/tmp/${APP_NAME}_arm64"
TMP_X86="/tmp/${APP_NAME}_x86"

swiftc "$DIR/Sources/NetworkMonitor.swift" \
       "$DIR/Sources/StatusBarView.swift" \
       "$DIR/Sources/AppDelegate.swift" \
       "$DIR/Sources/main.swift" \
       -target arm64-apple-macosx12.0 \
       -o "$TMP_ARM64" \
       -O

swiftc "$DIR/Sources/NetworkMonitor.swift" \
       "$DIR/Sources/StatusBarView.swift" \
       "$DIR/Sources/AppDelegate.swift" \
       "$DIR/Sources/main.swift" \
       -target x86_64-apple-macosx12.0 \
       -o "$TMP_X86" \
       -O

lipo -create "$TMP_ARM64" "$TMP_X86" -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
rm -f "$TMP_ARM64" "$TMP_X86"

echo "✅ Build successful: $APP_BUNDLE"

if [ "$1" == "--install" ]; then
    echo "📦 Installing to /Applications..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" /Applications/
    echo "🎉 Installed to /Applications/$APP_NAME.app"
    echo "▶️ Launching application..."
    open "/Applications/$APP_NAME.app"
elif [ "$1" == "--run" ]; then
    echo "▶️ Launching application..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    open "$APP_BUNDLE"
elif [ "$1" == "--dmg" ]; then
    DMG_NAME="${APP_NAME}-v1.0.0.dmg"
    echo "💿 Creating DMG: $BUILD_DIR/$DMG_NAME..."
    STAGING_DIR="/tmp/${APP_NAME}_dmg_staging"
    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    cp -R "$APP_BUNDLE" "$STAGING_DIR/"
    ln -s /Applications "$STAGING_DIR/Applications"
    rm -f "$BUILD_DIR/$DMG_NAME"
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"
    rm -rf "$STAGING_DIR"
    echo "🎉 DMG successfully created: $BUILD_DIR/$DMG_NAME"
fi
