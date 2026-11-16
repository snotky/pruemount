import SwiftUI
import AppKit

/// 右上角狀態列（Menu Bar）極簡彈出卡片視窗
public struct MenuBarPopupView: View {
    @ObservedObject public var monitor: DiskMonitorService
    @ObservedObject public var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    public init(monitor: DiskMonitorService, settings: AppSettings) {
        self.monitor = monitor
        self.settings = settings
    }

    private var l10n: L10n { settings.l10n }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. 頂部極簡品牌列
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("PureMount")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }

                Spacer()

                // 語系一鍵切換
                Button {
                    settings.toggleLanguage()
                } label: {
                    Text(settings.language.shortBadge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)

                // 退出全部外接硬碟
                if monitor.externalVolumes.contains(where: { $0.isMounted }) {
                    Button {
                        Task {
                            await monitor.ejectAllExternalVolumes()
                        }
                    } label: {
                        Text(settings.language == .zhHant ? "全退" : "Eject All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.teal.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Divider()

            // 2. 外接硬碟極簡卡片清單
            if monitor.externalVolumes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text(l10n.noExternalDrivesTitle)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(monitor.externalVolumes) { volume in
                        menuBarDriveCard(volume)
                    }
                }
                .padding(.horizontal, 12)
            }

            Divider()

            // 3. 底部極簡控制列
            HStack {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main-console")
                } label: {
                    Label(l10n.openMainWindow, systemImage: "macwindow")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text(l10n.quitApp)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 340)
    }

    private func menuBarDriveCard(_ volume: DiskVolume) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: volume.iconSystemName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(volume.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(dotColor(for: volume))
                            .frame(width: 6, height: 6)
                        Text("\(volume.fileSystem.rawValue) · \(statusShortText(for: volume))")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 右側只有 2 個極簡圖示按鈕：打開 Finder + 純淨退出（或重新掛載）
                if volume.isMounted {
                    Button {
                        monitor.openInFinder(volume)
                    } label: {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 13))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.primary.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .help(l10n.openInFinder)

                    Button {
                        Task {
                            await monitor.ejectVolume(
                                volume,
                                cleanGhostFirst: settings.autoCleanGhostOnEject
                            )
                        }
                    } label: {
                        Image(systemName: "eject.fill")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.teal)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.teal.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .help(settings.autoCleanGhostOnEject ? l10n.cleanAndEject : l10n.simpleEject)
                } else {
                    Button {
                        Task {
                            await monitor.remountVolume(volume)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.blue.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .help(l10n.remountDrive)
                }
            }

            // 輕量容量條
            StorageBarView(
                usedPercentage: volume.usedPercentage,
                isDirtyOrLocked: volume.hasDirtyBit,
                height: 6
            )

            // 情境式單行按鈕（平時隱藏，只有發生 Windows 鎖定或佔用時才展開）
            if volume.hasDirtyBit {
                Button {
                    Task {
                        await monitor.repairDirtyVolume(volume)
                    }
                } label: {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                        Text(l10n.oneClickRepairAndMount)
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            } else if let blocker = volume.blockingProcess {
                Button {
                    Task {
                        await monitor.forceReleaseAndEject(volume)
                    }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.lock.fill")
                        Text("\(blocker.appName) — \(l10n.forceReleaseAndEject)")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func dotColor(for volume: DiskVolume) -> Color {
        switch volume.mountState {
        case .mountedReadWrite: return .green
        case .mountedReadOnly: return .orange
        case .dirtyLocked: return .red
        case .unmounted: return .gray
        }
    }

    private func statusShortText(for volume: DiskVolume) -> String {
        switch volume.mountState {
        case .mountedReadWrite: return l10n.readWriteBadge
        case .mountedReadOnly: return l10n.readOnlyBadge
        case .dirtyLocked: return l10n.dirtyLockedBadge
        case .unmounted: return l10n.unmountedBadge
        }
    }
}
