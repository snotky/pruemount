#!/bin/zsh
set -euo pipefail
export TMPDIR=/tmp

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/PureMount.app"
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_OUTPUT="$BUILD_DIR/PureMount-1.0.0.dmg"

echo "📦 [PureMount] 開始建置官網發佈用 DMG 安裝映像檔..."

if [[ ! -d "$APP_BUNDLE" ]]; then
    "$PROJECT_DIR/scripts/build_app.sh" direct
fi

rm -rf "$DMG_STAGING" "$DMG_OUTPUT"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/PureMount.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "PureMount" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

rm -rf "$DMG_STAGING"
echo "✅ [PureMount] DMG 安裝包製作完成: $DMG_OUTPUT"
