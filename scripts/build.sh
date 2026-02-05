#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="QuickLaunch"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "==> Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating app bundle..."

# Clean old bundle
rm -rf "$APP_BUNDLE"

# Create directory structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
EXEC_PATH=$(swift build -c release --show-bin-path)/$APP_NAME
cp "$EXEC_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy app icon
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Copy status bar icon
if [ -f "$PROJECT_DIR/Resources/StatusBarIcon.png" ]; then
    cp "$PROJECT_DIR/Resources/StatusBarIcon.png" "$APP_BUNDLE/Contents/Resources/StatusBarIcon.png"
    cp "$PROJECT_DIR/Resources/StatusBarIcon@2x.png" "$APP_BUNDLE/Contents/Resources/StatusBarIcon@2x.png"
fi

# Copy localization files
if [ -d "$PROJECT_DIR/Resources/en.lproj" ]; then
    cp -r "$PROJECT_DIR/Resources/en.lproj" "$APP_BUNDLE/Contents/Resources/"
fi
if [ -d "$PROJECT_DIR/Resources/zh-Hans.lproj" ]; then
    cp -r "$PROJECT_DIR/Resources/zh-Hans.lproj" "$APP_BUNDLE/Contents/Resources/"
fi
echo "==> Build complete: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
