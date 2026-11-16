import SwiftUI

/// PureMount 正式版主控台視窗（左側極簡磁碟清單 + 右側智慧儀表板）
public struct MainWindowView: View {
    @ObservedObject public var monitor: DiskMonitorService
    @ObservedObject public var settings: AppSettings
    @ObservedObject public var license = LicenseService.shared
    @ObservedObject public var permissions = PermissionService.shared

    public init(monitor: DiskMonitorService, settings: AppSettings) {
        self.monitor = monitor
        self.settings = settings
    }

    private var l10n: L10n { settings.l10n }

    public var body: some View {
        Group {
            if settings.distributionTrack == .direct && !permissions.hasFullDiskAccess {
                OnboardingPermissionView(permissions: permissions, settings: settings)
                    .transition(.opacity)
            } else {
                consoleView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: permissions.hasFullDiskAccess)
    }

    private var consoleView: some View {
        ZStack(alignment: .bottom) {
            NavigationSplitView {
                sidebarContent
                    .navigationSplitViewColumnWidth(min: 235, ideal: 255, max: 290)
            } detail: {
                if let selected = monitor.selectedVolume {
                    VolumeDetailView(
                        volume: selected,
                        monitor: monitor,
                        settings: settings
                    )
                } else {
                    emptyStateView
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // Pro 授權或免費體驗狀態按鈕
                    Button {
                        license.isShowingUpgradeSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: license.isProAuthorized ? "checkmark.seal.fill" : "sparkles")
                                .font(.system(size: 11.5))
                                .foregroundStyle(license.isProAuthorized ? Color.green : Color.blue)
                            Text(license.isProAuthorized
                                 ? l10n.proBadgeAuthorized
                                 : "\(l10n.freeTrialAvailableBadge(remaining: license.freeTrialSessionsRemaining)) · \(l10n.upgradeToProButton)")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                    }

                    // 一鍵中英文即時切換按鈕
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            settings.toggleLanguage()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 12))
                            Text(settings.language == .zhHant ? "中 / EN" : "EN / 中")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 6)
                    }
                    .help("Switch Language / 切換中英文")

                    // 重新掃描磁碟
                    Button {
                        monitor.refreshPhysicalVolumes()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(l10n.refreshDrives)

                    // 偏好設定
                    Button {
                        settings.isShowingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .help(l10n.settingsTitle)
                }
            }

            // 底部輕量浮動狀態提示 (Toast)
            if let toast = monitor.statusToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $settings.isShowingSettings) {
            SettingsSheetView(settings: settings, monitor: monitor)
        }
        .sheet(isPresented: $license.isShowingUpgradeSheet) {
            ProUpgradeSheetView(license: license, settings: settings, monitor: monitor)
        }
        .sheet(item: $monitor.renamingVolume) { targetVol in
            RenameVolumeSheetView(volume: targetVol, monitor: monitor, settings: settings)
        }
        .sheet(item: $monitor.formattingVolume) { targetVol in
            FormatVolumeWizardView(volume: targetVol, monitor: monitor, settings: settings)
        }
        .frame(minWidth: 820, minHeight: 540)
    }

    // MARK: - 側邊欄磁碟列表
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            List(selection: $monitor.selectedVolumeID) {
                Section(l10n.externalDrivesSection) {
                    if monitor.externalVolumes.isEmpty {
                        Text(l10n.noExternalDrivesTitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(monitor.externalVolumes) { volume in
                            sidebarRow(for: volume)
                                .tag(volume.id)
                        }
                    }
                }

                if settings.showInternalDrives && !monitor.internalVolumes.isEmpty {
                    Section(l10n.systemDrivesSection) {
                        ForEach(monitor.internalVolumes) { volume in
                            sidebarRow(for: volume)
                                .tag(volume.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            if monitor.externalVolumes.contains(where: { $0.isMounted }) {
                Divider()
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await monitor.ejectAllExternalVolumes()
                        }
                    } label: {
                        Label(
                            l10n.ejectAllExternal,
                            systemImage: "eject.circle.fill"
                        )
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.teal)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func sidebarRow(for volume: DiskVolume) -> some View {
        let isSelected = (monitor.selectedVolumeID == volume.id)
        return HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.primary.opacity(0.07))
                    .frame(width: 30, height: 30)

                Image(systemName: volume.iconSystemName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : (volume.isExternal ? Color.accentColor : Color.primary.opacity(0.75)))
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(statusDotColor(for: volume))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.white : Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
                    )
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(volume.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(volume.fileSystem.rawValue)
                        .font(.system(size: 10.5, weight: .semibold))
                    Text("·")
                    Text(volume.formattedFree)
                        .font(.system(size: 10.5))
                }
                .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
            }

            Spacer()

            if volume.hasDirtyBit {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.white : Color.orange)
            } else if volume.blockingProcess != nil {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.white : Color.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusDotColor(for volume: DiskVolume) -> Color {
        switch volume.mountState {
        case .mountedReadWrite: return .green
        case .mountedReadOnly: return .orange
        case .dirtyLocked: return .red
        case .unmounted: return .gray
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "externaldrive.badge.plus")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.secondary)

            Text(l10n.noExternalDrivesTitle)
                .font(.system(size: 18, weight: .bold))

            Text(settings.language == .zhHant
                 ? "請將 NTFS、exFAT 或 USB 外接硬碟插入您的 Mac，系統將自動偵測並顯示於此。"
                 : "Plug an NTFS, exFAT, or USB external drive into your Mac to manage it here.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
