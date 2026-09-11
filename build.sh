#!/usr/bin/env bash
set -e

APP_NAME="NetSpeedMonitor"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🚀 NetSpeedMonitor derleniyor..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

swiftc "$DIR/Sources/NetworkMonitor.swift" \
       "$DIR/Sources/StatusBarView.swift" \
       "$DIR/Sources/AppDelegate.swift" \
       "$DIR/Sources/main.swift" \
       -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
       -O

echo "✅ Derleme başarılı: $APP_BUNDLE"

if [ "$1" == "--install" ]; then
    echo "📦 /Applications dizinine yükleniyor..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" /Applications/
    echo "🎉 /Applications/$APP_NAME.app yüklendi."
    echo "▶️ Uygulama başlatılıyor..."
    open "/Applications/$APP_NAME.app"
elif [ "$1" == "--run" ]; then
    echo "▶️ Uygulama başlatılıyor..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    open "$APP_BUNDLE"
fi
