#!/bin/bash
# Build the Debug channel and replace the Tinycast Dev.app used day to day.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
IDENTITY="Tinycast Self-Signed"
DERIVED="build/DerivedData"
DEST="/Applications/Tinycast Dev.app"

if ! security find-identity -p codesigning | grep -q "$IDENTITY"; then
    echo "✗ '$IDENTITY' code-signing identity not found — create it once (docs/signing.md)." >&2
    exit 1
fi

echo "▸ Building Tinycast Dev.app (Debug)…"
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Debug \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    build

APP="$DERIVED/Build/Products/Debug/Tinycast Dev.app"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
# A Release product shares this scheme and must never replace the dev app.
[ "$BUNDLE_ID" = "com.tinycast.app.dev" ] || {
    echo "✗ $APP is $BUNDLE_ID, not com.tinycast.app.dev." >&2
    exit 1
}
codesign --verify --deep --strict "$APP"

# Replacing the bundle while its process is still mapped leaves a broken running copy.
if pgrep -x "Tinycast Dev" >/dev/null; then
    osascript -e 'tell application "Tinycast Dev" to quit'
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        pgrep -x "Tinycast Dev" >/dev/null || break
        sleep 0.25
    done
    if pgrep -x "Tinycast Dev" >/dev/null; then
        echo "✗ Tinycast Dev did not quit." >&2
        exit 1
    fi
fi

STAGING="/Applications/.Tinycast Dev.app.installing"
rm -rf "$STAGING"
ditto "$APP" "$STAGING"
rm -rf "$DEST"
mv "$STAGING" "$DEST"
open "$DEST"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEST/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$DEST/Contents/Info.plist")"
echo "✓ $DEST ($VERSION ($BUILD))"
