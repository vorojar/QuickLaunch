#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="QuickLaunch"
CASK_FILE="$PROJECT_DIR/Casks/quicklaunch.rb"
REMOTE_SIGN_SCRIPT="${REMOTE_MAC_SIGN_SCRIPT:-$HOME/.codex/skills/remote-mac-sign/sign_remote.sh}"

cd "$PROJECT_DIR"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PROJECT_DIR/Resources/Info.plist")
DMG_NAME="$APP_NAME-v$VERSION.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
SIGNED_DMG="$PROJECT_DIR/signed-output/signed_$DMG_NAME"
SIGNED_RELEASE_DMG="$PROJECT_DIR/signed-output/$DMG_NAME"

if [ ! -x "$REMOTE_SIGN_SCRIPT" ]; then
    echo "Missing remote signing script: $REMOTE_SIGN_SCRIPT" >&2
    echo "Install or link the remote-mac-sign skill before releasing." >&2
    exit 1
fi

echo "==> Building $DMG_NAME"
"$PROJECT_DIR/scripts/build.sh"

echo "==> Remote signing and notarizing $DMG_NAME"
"$REMOTE_SIGN_SCRIPT" "$DMG_PATH"

if [ ! -f "$SIGNED_DMG" ]; then
    echo "Expected signed DMG not found: $SIGNED_DMG" >&2
    exit 1
fi

cp "$SIGNED_DMG" "$SIGNED_RELEASE_DMG"
cp "$SIGNED_DMG" "$DMG_PATH"

SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
python3 - "$CASK_FILE" "$VERSION" "$SHA256" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
version = sys.argv[2]
sha256 = sys.argv[3]
text = path.read_text()
text = re.sub(r'version "[^"]+"', f'version "{version}"', text, count=1)
text = re.sub(r'sha256 "[^"]+"', f'sha256 "{sha256}"', text, count=1)
path.write_text(text)
PY

echo "==> Validating signed release asset"
xcrun stapler validate "$DMG_PATH"
spctl -a -vv -t install "$DMG_PATH"
hdiutil verify "$DMG_PATH"

MOUNT_DIR="$(mktemp -d /tmp/quicklaunch-release.XXXXXX)"
cleanup_mount() {
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
    rmdir "$MOUNT_DIR" 2>/dev/null || true
}
trap cleanup_mount EXIT

hdiutil attach "$DMG_PATH" -quiet -nobrowse -mountpoint "$MOUNT_DIR"
test -d "$MOUNT_DIR/$APP_NAME.app"
test -L "$MOUNT_DIR/Applications"
test -f "$MOUNT_DIR/.DS_Store"
MOUNTED_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$MOUNT_DIR/$APP_NAME.app/Contents/Info.plist")
if [ "$MOUNTED_VERSION" != "$VERSION" ]; then
    echo "Version mismatch in DMG: expected $VERSION, got $MOUNTED_VERSION" >&2
    exit 1
fi
spctl -a -vv -t execute "$MOUNT_DIR/$APP_NAME.app"
codesign --verify --deep --strict --verbose=2 "$MOUNT_DIR/$APP_NAME.app"
cleanup_mount
trap - EXIT

if command -v brew >/dev/null; then
    brew style "$CASK_FILE"
fi
swift build
git diff --check

echo ""
echo "==> Release asset ready"
echo "DMG:    $DMG_PATH"
echo "Signed: $SIGNED_RELEASE_DMG"
echo "SHA256: $SHA256"
