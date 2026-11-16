import SwiftUI

/// 磁碟詳情與極簡控制面板（右欄主視圖）
public struct VolumeDetailView: View {
    public let volume: DiskVolume
    @ObservedObject public var monitor: DiskMonitorService
    @ObservedObject public var settings: AppSettings

    public init(volume: DiskVolume, monitor: DiskMonitorService, settings: AppSettings) {
        self.volume = volume
        self.monitor = monitor
        self.settings = settings
    }

    private var l10n: L10n { settings.l10n }
    private var isBusy: Bool { monitor.isBusyVolumeID == volume.id }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 1. 頂部主磁碟卡片
                heroCard

                // 2. 情境式智慧修復橫幅（平時隱藏，只有 Windows 鎖定時才顯示）
                if volume.hasDirtyBit || volume.mountState == .dirtyLocked {
                    dirtyBitContextualBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 3. 情境式佔用程式橫幅（平時隱藏，只有退出被卡住時才顯示）
                if let blocker = volume.blockingProcess {
                    blockerContextualBanner(blocker: blocker)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 4. 智慧自動化守護（極簡開關區）
                if volume.isExternal {
                    automationCard
                }

                // 5. 輕量技術規格列
                specsFooterCard
            }
            .padding(24)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: volume.mountState)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: volume.blockingProcess)
    }

    // MARK: - 1. 主磁碟資訊與核心按鈕卡
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.18), Color.cyan.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: volume.iconSystemName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(volume.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        if volume.isDemo {
                            Text(l10n.demoModeActive)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.07)))
                        }
                    }

                    Text("\(volume.connectionBus) · /dev/\(volume.bsdName)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadgeView(volume: volume, l10n: l10n)

                // 右上角極簡「⋯」更多硬碟工具選單（僅對外接硬碟開放，系統內建硬碟硬鎖死隱藏）
                if volume.isExternal && DiskUtilityService.shared.isSafeExternalTarget(volume) {
                    Menu {
                        Button {
                            monitor.beginRename(volume)
                        } label: {
                            Label(l10n.menuRenameVolume, systemImage: "pencil")
                        }

                        if volume.isMounted {
                            Button {
                                Task {
                                    await monitor.runSpeedTest(on: volume)
                                }
                            } label: {
                                Label(l10n.menuQuickSpeedTest, systemImage: "speedometer")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            monitor.beginFormatWizard(volume)
                        } label: {
                            Label(l10n.menuFormatVolume, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help(l10n.moreToolsTooltip)
                }
            }

            // 容量進度條與統計
            VStack(alignment: .leading, spacing: 8) {
                StorageBarView(
                    usedPercentage: volume.usedPercentage,
                    isDirtyOrLocked: volume.hasDirtyBit || volume.mountState == .dirtyLocked,
                    height: 11
                )

                HStack {
                    Text(l10n.storageSummary(
                        used: volume.formattedUsed,
                        total: volume.formattedTotal,
                        free: volume.formattedFree
                    ))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                    Spacer()

                    if let speed = volume.speedTestResult {
                        Text(l10n.speedResultSummary(read: speed.readMBps, write: speed.writeMBps))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                    }

                    if volume.isExternal && volume.isMounted {
                        ghostStatusPill
                    }
                }
            }

            Divider()

            // 極簡核心操作按鈕列
            HStack(spacing: 12) {
                if volume.isMounted {
                    Button {
                        monitor.openInFinder(volume)
                    } label: {
                        Label(l10n.openInFinder, systemImage: "folder.fill")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    // 只有當 NTFS 硬碟處於「唯讀」狀態時，才顯示「啟用 NTFS 讀寫」按鈕；已可讀寫時保持極簡不顯示多餘按鈕
                    if volume.fileSystem.isNTFS && !volume.isWritable && !volume.hasDirtyBit {
                        Button {
                            Task {
                                await monitor.toggleReadWriteMode(for: volume)
                            }
                        } label: {
                            Label(
                                l10n.enableReadWrite,
                                systemImage: "lock.open.fill"
                            )
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                        .disabled(isBusy)
                    }

                    Spacer()

                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }

                    if volume.isExternal {
                        Button {
                            Task {
                                await monitor.ejectVolume(
                                    volume,
                                    cleanGhostFirst: settings.autoCleanGhostOnEject
                                )
                            }
                        } label: {
                            Label(
                                settings.autoCleanGhostOnEject ? l10n.cleanAndEject : l10n.simpleEject,
                                systemImage: settings.autoCleanGhostOnEject ? "sparkles" : "eject.fill"
                            )
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .controlSize(.large)
                        .disabled(isBusy)
                    }
                } else {
                    // 已安全卸載狀態：顯示重新掛載按鈕
                    Button {
                        Task {
                            await monitor.remountVolume(volume)
                        }
                    } label: {
                        Label(l10n.remountDrive, systemImage: "arrow.clockwise.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isBusy)

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - 幽靈垃圾檔輕量膠囊
    private var ghostStatusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: volume.ghostFilesCount > 0 ? "leaf.fill" : "checkmark.seal.fill")
                .font(.system(size: 11))
                .foregroundStyle(volume.ghostFilesCount > 0 ? Color.teal : Color.green)

            Text(l10n.ghostFilesFoundBadge(
                count: volume.ghostFilesCount,
                size: volume.formattedGhostBytes
            ))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)

            if volume.ghostFilesCount > 0 && volume.isWritable {
                Button {
                    Task {
                        await monitor.cleanGhostFiles(on: volume)
                    }
                } label: {
                    Text(l10n.cleanGhostFilesNow)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.teal)
                }
                .buttonStyle(.plain)
            }
        }
        .help(l10n.ghostCleanTooltip)
    }

    // MARK: - 2. 情境式卡片：Windows Dirty Bit 髒磁區一鍵修復
    private var dirtyBitContextualBanner: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.orange.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.dirtyBitAlertTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)

                Text(l10n.dirtyBitAlertDesc)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button {
                Task {
                    await monitor.repairDirtyVolume(volume)
                }
            } label: {
                Label(l10n.oneClickRepairAndMount, systemImage: "bolt.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(isBusy)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - 3. 情境式卡片：誰佔用了硬碟？(Process Blocker)
    private func blockerContextualBanner(blocker: BlockingProcessInfo) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.red.opacity(0.14)))

            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.blockerAlertTitle(appName: blocker.appName))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)

                Text(l10n.blockerAlertDesc(pid: blocker.pid, path: blocker.openFilePath))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Button {
                Task {
                    await monitor.forceReleaseAndEject(volume)
                }
            } label: {
                Label(l10n.forceReleaseAndEject, systemImage: "xmark.app.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isBusy)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.32), lineWidth: 1)
                )
        )
    }

    // MARK: - 4. 極簡自動化守護開關卡
    private var automationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(l10n.automationSectionTitle, systemImage: "sparkles.rectangle.stack.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                automationToggleRow(
                    icon: "externaldrive.badge.checkmark",
                    iconColor: .blue,
                    title: l10n.toggleAutoNTFSReadWrite,
                    subtitle: l10n.toggleAutoNTFSReadWriteSub,
                    isOn: $settings.autoMountNTFSReadWrite
                )

                Divider().padding(.vertical, 10)

                automationToggleRow(
                    icon: "leaf.arrow.triangle.circlepath",
                    iconColor: .teal,
                    title: l10n.toggleAutoCleanOnEject,
                    subtitle: l10n.toggleAutoCleanOnEjectSub,
                    isOn: $settings.autoCleanGhostOnEject
                )

                Divider().padding(.vertical, 10)

                automationToggleRow(
                    icon: "moon.zzz.fill",
                    iconColor: .indigo,
                    title: l10n.toggleSleepGuard,
                    subtitle: l10n.toggleSleepGuardSub,
                    isOn: $settings.sleepGuardEnabled
                )

                Divider().padding(.vertical, 10)

                automationToggleRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: l10n.toggleDisableSpotlight,
                    subtitle: l10n.toggleDisableSpotlightSub,
                    isOn: Binding(
                        get: { volume.isSpotlightDisabled },
                        set: { _ in monitor.toggleSpotlightIndexing(for: volume) }
                    )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func automationToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    // MARK: - 5. 底部輕量規格區
    private var specsFooterCard: some View {
        HStack(spacing: 24) {
            specItem(label: l10n.fileSystemLabel, value: volume.fileSystem.rawValue)
            Divider().frame(height: 26)
            specItem(label: l10n.deviceNodeLabel, value: "/dev/\(volume.bsdName)")
            Divider().frame(height: 26)
            specItem(label: l10n.mountPointLabel, value: volume.mountPoint ?? "—")
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }

    private func specItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .lineLimit(1)
        }
    }
}
