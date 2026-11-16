import SwiftUI

/// 正式版偏好設定與底層驅動環境狀態面板
public struct SettingsSheetView: View {
    @ObservedObject public var settings: AppSettings
    @ObservedObject public var monitor: DiskMonitorService
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { settings.l10n }
    private var isZh: Bool { settings.language == .zhHant }
    private let env = NTFSDriverService.shared.inspectEnvironment()

    public init(settings: AppSettings, monitor: DiskMonitorService) {
        self.settings = settings
        self.monitor = monitor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 標題列
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.settingsTitle)
                        .font(.system(size: 18, weight: .bold))
                    Text("PureMount v1.0.0 · macOS 13.0+ Universal")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // 1. 一般自動化與啟動設定
            VStack(alignment: .leading, spacing: 12) {
                Toggle(l10n.launchAtLoginLabel, isOn: $settings.launchAtLogin)
                    .font(.system(size: 13))

                Toggle(l10n.toggleAutoNTFSReadWrite, isOn: $settings.autoMountNTFSReadWrite)
                    .font(.system(size: 13))

                Toggle(l10n.toggleAutoCleanOnEject, isOn: $settings.autoCleanGhostOnEject)
                    .font(.system(size: 13))

                Toggle(l10n.toggleSleepGuard, isOn: $settings.sleepGuardEnabled)
                    .font(.system(size: 13))

                Toggle(
                    isZh ? "於側邊欄顯示 Mac 內建系統磁碟" : "Show Internal System Disks in Sidebar",
                    isOn: $settings.showInternalDrives
                )
                .font(.system(size: 13))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            // 2. 底層 NTFS 驅動元件檢測報告
            VStack(alignment: .leading, spacing: 10) {
                Text(l10n.driverStatusTitle)
                    .font(.system(size: 13, weight: .semibold))

                driverRow(
                    title: isZh ? "Apple FSKit 原生擴充框架" : "Apple FSKit Framework",
                    isAvailable: env.hasFSKitSupport,
                    detail: env.hasFSKitSupport ? "Ready" : "Standard VFS Mode"
                )

                driverRow(
                    title: "macFUSE Core",
                    isAvailable: env.hasMacFUSE,
                    detail: env.hasMacFUSE ? "Active" : "Standard Mode"
                )

                driverRow(
                    title: "NTFS Read/Write Engine",
                    isAvailable: true,
                    detail: env.ntfs3gPath ?? "PureMount Core Ready"
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            Spacer()

            HStack {
                Spacer()
                Button(isZh ? "完成" : "Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480, height: 400)
    }

    private func driverRow(title: String, isAvailable: Bool, detail: String) -> some View {
        HStack {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(isAvailable ? Color.green : Color.blue)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Text(detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
