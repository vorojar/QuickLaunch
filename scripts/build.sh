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

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")
DMG_NAME="$PROJECT_DIR/QuickLaunch-v${VERSION}.dmg"

echo "==> Creating DMG (v${VERSION})..."

# Create temp folder with app + Applications symlink for drag-and-drop install
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -r "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create writable DMG, copy contents, configure Finder view, then convert
rm -f "$DMG_NAME"
DMG_RW="$BUILD_DIR/QuickLaunch-rw.dmg"
rm -f "$DMG_RW"
hdiutil create -size 200m -fs HFS+ -volname "QuickLaunch" "$DMG_RW"

# Mount WITHOUT -nobrowse so Finder can see and configure it
hdiutil attach "$DMG_RW" -quiet
cp -R "$DMG_STAGING/QuickLaunch.app" "/Volumes/QuickLaunch/"
ln -s /Applications "/Volumes/QuickLaunch/Applications"

# Configure Finder window: compact size, icon view, icon positions
osascript <<'APPLESCRIPT'
tell application "Finder"
    tell disk "QuickLaunch"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 200, 760, 524}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set background color of theViewOptions to {65535, 65535, 65535}
        set position of item "QuickLaunch.app" of container window to {140, 160}
        set position of item "Applications" of container window to {420, 160}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "/Volumes/QuickLaunch" -quiet
hdiutil convert "$DMG_RW" -format UDZO -o "$DMG_NAME"
rm -f "$DMG_RW"
rm -rf "$DMG_STAGING"

echo ""
echo "==> Done!"
echo "App:  $APP_BUNDLE"
echo "DMG:  $DMG_NAME"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To install: open $DMG_NAME  (drag to Applications)"
