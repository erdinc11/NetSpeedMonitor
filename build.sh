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
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

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
    echo "💿 Creating styled DMG: $BUILD_DIR/$DMG_NAME..."
    
    if [ ! -f "$DIR/Resources/dmg_background.png" ]; then
        swift "$DIR/scripts/generate_dmg_background.swift" "$DIR/Resources/dmg_background.png"
    fi
    
    STAGING_DIR="/tmp/${APP_NAME}_dmg_staging"
    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    cp -R "$APP_BUNDLE" "$STAGING_DIR/"
    
    rm -f "$BUILD_DIR/$DMG_NAME"
    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$DIR/Resources/AppIcon.icns" \
        --background "$DIR/Resources/dmg_background.png" \
        --window-pos 200 120 \
        --window-size 540 380 \
        --icon-size 128 \
        --text-size 12 \
        --icon "$APP_NAME.app" 140 200 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 400 200 \
        --no-internet-enable \
        --overwrite \
        "$BUILD_DIR/$DMG_NAME" \
        "$STAGING_DIR" || true
        
    rm -rf "$STAGING_DIR"
    echo "🎉 DMG successfully created: $BUILD_DIR/$DMG_NAME"
fi
