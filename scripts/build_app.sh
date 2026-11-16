#!/bin/zsh
set -euo pipefail
export TMPDIR=/tmp

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TRACK="${1:-direct}" # 可傳入 direct 或 mas
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/PureMount.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE="/tmp/puremount-module-cache"

echo "🚀 [PureMount] 開始編譯 macOS 應用程式 (雙軌通道: $TRACK, 最低系統需求: macOS 13.0)..."

cd "$PROJECT_DIR"
mkdir -p "$BUILD_DIR" "$MODULE_CACHE"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
mkdir -p "$RESOURCES_DIR/zh-Hant.lproj" "$RESOURCES_DIR/en.lproj"

SWIFT_FILES=(
    Sources/PureMount/Localization/L10n.swift
    Sources/PureMount/Models/DiskVolume.swift
    Sources/PureMount/Models/AppSettings.swift
    Sources/PureMount/Services/PermissionService.swift
    Sources/PureMount/Services/LicenseService.swift
    Sources/PureMount/Services/SandboxBookmarkService.swift
    Sources/PureMount/Services/DiskUtilityService.swift
    Sources/PureMount/Services/GhostCleanerService.swift
    Sources/PureMount/Services/SpotlightControlService.swift
    Sources/PureMount/Services/ProcessBlockerService.swift
    Sources/PureMount/Services/NTFSDriverService.swift
    Sources/PureMount/Services/SleepGuardService.swift
    Sources/PureMount/Services/DiskMonitorService.swift
    Sources/PureMount/Views/Components/StatusBadgeView.swift
    Sources/PureMount/Views/OnboardingPermissionView.swift
    Sources/PureMount/Views/ProUpgradeSheetView.swift
    Sources/PureMount/Views/RenameVolumeSheetView.swift
    Sources/PureMount/Views/FormatVolumeWizardView.swift
    Sources/PureMount/Views/VolumeDetailView.swift
    Sources/PureMount/Views/SettingsSheetView.swift
    Sources/PureMount/Views/MenuBarPopupView.swift
    Sources/PureMount/Views/MainWindowView.swift
    Sources/PureMount/PureMountApp.swift
)

if [[ "$TRACK" == "mas" ]]; then
    DEFINE_FLAG="-DDISTRIBUTION_MAS"
else
    DEFINE_FLAG="-DDISTRIBUTION_DIRECT"
fi

swiftc \
    -module-cache-path "$MODULE_CACHE" \
    -target arm64-apple-macosx13.0 \
    -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
    -O \
    "$DEFINE_FLAG" \
    -framework SwiftUI \
    -framework AppKit \
    -framework DiskArbitration \
    -framework IOKit \
    -framework ServiceManagement \
    -framework StoreKit \
    "${SWIFT_FILES[@]}" \
    -o "$MACOS_DIR/PureMount"

chmod +x "$MACOS_DIR/PureMount"
cp "$PROJECT_DIR/Configuration/Info.plist" "$CONTENTS_DIR/Info.plist"

# 將內建免重開機 NTFS 讀寫核心 (ntfs-3g + fuse-t + ntfsfix + mkntfs + ntfslabel) 打包進 App Bundle
if [[ -d "$PROJECT_DIR/Resources/ntfs-engine" ]]; then
    cp -R "$PROJECT_DIR/Resources/ntfs-engine" "$RESOURCES_DIR/ntfs-engine"
    chmod -R +x "$RESOURCES_DIR/ntfs-engine/bin" "$RESOURCES_DIR/ntfs-engine/lib"
fi

# 產生 AppIcon.icns
swift -module-cache-path "$MODULE_CACHE" "$PROJECT_DIR/scripts/generate_icon.swift" "$RESOURCES_DIR/AppIcon.icns"

# 進行本機開發簽章 (Ad-hoc Code Signing)
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ [PureMount] 打包完成: $APP_BUNDLE"
