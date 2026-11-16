#!/bin/zsh
set -euo pipefail
export TMPDIR=/tmp

# PureMount 正式簽章與 Apple 公證腳本（官網 Direct DMG 專用）
# 使用方式：
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="puremount-notary" \
#   ./scripts/notarize_dmg.sh
#
# 事先建立公證憑證設定（只需執行一次）：
#   xcrun notarytool store-credentials "puremount-notary" \
#     --apple-id "your@email.com" --team-id "TEAMID" --password "app-specific-password"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/PureMount.app"
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_OUTPUT="$BUILD_DIR/PureMount-1.0.0.dmg"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "❌ 請指定 SIGN_IDENTITY，例如："
    echo "   SIGN_IDENTITY=\"Developer ID Application: Name (TEAMID)\" NOTARY_PROFILE=\"puremount-notary\" ./scripts/notarize_dmg.sh"
    exit 1
fi

echo "🔨 [1/5] 編譯 Direct 正式版 PureMount.app..."
"$PROJECT_DIR/scripts/build_app.sh" direct

echo "🔏 [2/5] 使用 Developer ID 簽章內建引擎與 App Bundle (Hardened Runtime)..."
ENTITLEMENTS="$PROJECT_DIR/Configuration/PureMount-Direct.entitlements"
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/Resources/ntfs-engine/lib/"*
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE/Contents/Resources/ntfs-engine/bin/"*
codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS" --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "📦 [3/5] 打包 PureMount-1.0.0.dmg..."
rm -rf "$DMG_STAGING" "$DMG_OUTPUT"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/PureMount.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "PureMount" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_OUTPUT"
rm -rf "$DMG_STAGING"

codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_OUTPUT"

if [[ -n "$NOTARY_PROFILE" ]]; then
    echo "☁️ [4/5] 送交 Apple Notary Service 公證..."
    xcrun notarytool submit "$DMG_OUTPUT" --keychain-profile "$NOTARY_PROFILE" --wait

    echo "📎 [5/5] 將公證票據釘選 (Staple) 至 DMG..."
    xcrun stapler staple "$DMG_OUTPUT"
    xcrun stapler validate "$DMG_OUTPUT"
    echo "🎉 公證完成！可正式上傳至 GitHub Releases 發佈：$DMG_OUTPUT"
else
    echo "⚠️ 未指定 NOTARY_PROFILE，已完成 Developer ID 簽章但略過 Apple 公證步驟。"
fi
