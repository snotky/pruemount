import SwiftUI

/// 具備三道安全防呆與「白話使用情境二選一」的格式化精靈視窗
public struct FormatVolumeWizardView: View {
    public let volume: DiskVolume
    @ObservedObject public var monitor: DiskMonitorService
    @ObservedObject public var settings: AppSettings

    private var l10n: L10n { settings.l10n }

    public init(volume: DiskVolume, monitor: DiskMonitorService, settings: AppSettings) {
        self.volume = volume
        self.monitor = monitor
        self.settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 頂部步驟標題
            HStack {
                Text(monitor.formatWizardStep == 1 ? l10n.formatWizardStep1Title : l10n.formatWizardStep2Title)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button {
                    monitor.formattingVolume = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(monitor.isFormattingInProgress)
            }

            // 醒目紅色警告橫幅（清空整個硬碟提醒）
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.formatRedWarningTitle(name: volume.name))
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.red)

                    Text(l10n.formatRedWarningDesc(usedSize: volume.formattedUsed))
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.38), lineWidth: 1)
                    )
            )

            if monitor.formatWizardStep == 1 {
                step1ScenarioSelector
            } else {
                step2FinalConfirmation
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    // MARK: - 步驟 1：使用情境二選一（exFAT vs NTFS + 底部收合進階格式）
    private var step1ScenarioSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(l10n.formatUsageQuestion)
                .font(.system(size: 13.5, weight: .semibold))

            // 選項 1（預設推薦）：Mac + Windows 雙平台通用 (exFAT)
            scenarioOptionCard(
                format: .exfat,
                title: l10n.formatOptionExfatTitle,
                badge: l10n.formatOptionExfatBadge,
                description: l10n.formatOptionExfatDesc,
                accent: .teal
            )

            // 選項 2：Windows 原生格式 (NTFS)
            scenarioOptionCard(
                format: .ntfs,
                title: l10n.formatOptionNtfsTitle,
                badge: l10n.formatOptionNtfsBadge,
                description: l10n.formatOptionNtfsDesc,
                accent: .blue
            )

            // 低調可收合的進階/特殊設備格式（預設收合，避免一般消費者誤選導致 Windows 讀不到）
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        monitor.showAdvancedFormatOptions.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: monitor.showAdvancedFormatOptions ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(l10n.showAdvancedFormatsToggle)
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if monitor.showAdvancedFormatOptions {
                    VStack(spacing: 8) {
                        compactAdvancedFormatRow(
                            format: .apfs,
                            title: l10n.formatOptionApfsTitle,
                            badge: "APFS"
                        )
                        compactAdvancedFormatRow(
                            format: .fat32,
                            title: l10n.formatOptionFat32Title,
                            badge: "FAT32"
                        )
                    }
                    .padding(.top, 4)
                }
            }

            Divider()

            // 新硬碟名稱輸入框
            HStack(spacing: 12) {
                Text(l10n.formatNewVolumeNameLabel)
                    .font(.system(size: 12.5, weight: .medium))
                TextField(volume.name, text: $monitor.formatNewVolumeName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }

            // 步驟 1 底部按鈕
            HStack {
                Button(l10n.cancelAction) {
                    monitor.formattingVolume = nil
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    monitor.proceedToFormatStep2()
                } label: {
                    HStack(spacing: 6) {
                        Text(l10n.formatNextStepButton)
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 步驟 2：最終二次確認（方案 1：必勾選確認才解鎖紅色清空按鈕）
    private var step2FinalConfirmation: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 即將抹除摘要卡
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(
                    label: l10n.formatSummaryTargetDrive,
                    value: "\(volume.name) (/dev/\(volume.bsdName) · \(volume.formattedTotal))",
                    isHighlightRed: false
                )
                Divider()
                summaryRow(
                    label: l10n.formatSummaryDataToDestroy,
                    value: "\(volume.formattedUsed) (\(Int(volume.usedPercentage * 100))%)",
                    isHighlightRed: true
                )
                Divider()
                summaryRow(
                    label: l10n.formatSummaryTargetFormat,
                    value: "\(monitor.selectedFormatType.rawValue) — 「\(monitor.formatNewVolumeName.isEmpty ? volume.name : monitor.formatNewVolumeName)」",
                    isHighlightRed: false
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )

            // 必勾選安全確認核取方塊（方案 1 核心防呆）
            Button {
                monitor.hasCheckedEraseConfirmation.toggle()
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: monitor.hasCheckedEraseConfirmation ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(monitor.hasCheckedEraseConfirmation ? Color.red : Color.secondary)

                    Text(l10n.formatMandatoryCheckboxLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(monitor.hasCheckedEraseConfirmation ? Color.red.opacity(0.08) : Color.primary.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    monitor.hasCheckedEraseConfirmation ? Color.red.opacity(0.4) : Color.primary.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)

            // 步驟 2 底部按鈕
            HStack {
                Button {
                    monitor.backToFormatStep1()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(l10n.formatBackStepButton)
                    }
                }
                .disabled(monitor.isFormattingInProgress)

                Spacer()

                if monitor.isFormattingInProgress {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 8)
                }

                Button {
                    Task {
                        await monitor.executeConfirmedFormat()
                    }
                } label: {
                    Label(l10n.formatFinalDestructiveButton, systemImage: "trash.fill")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!monitor.hasCheckedEraseConfirmation || monitor.isFormattingInProgress)
            }
            .padding(.top, 4)
        }
    }

    private func scenarioOptionCard(
        format: FileSystemFormat,
        title: String,
        badge: String,
        description: String,
        accent: Color
    ) -> some View {
        let isSelected = monitor.selectedFormatType == format
        return Button {
            monitor.selectedFormatType = format
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? accent : .secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(badge)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? accent : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? accent.opacity(0.14) : Color.primary.opacity(0.06))
                            )
                    }

                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.07) : Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? accent.opacity(0.55) : Color.primary.opacity(0.08),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func compactAdvancedFormatRow(
        format: FileSystemFormat,
        title: String,
        badge: String
    ) -> some View {
        let isSelected = monitor.selectedFormatType == format
        return Button {
            monitor.selectedFormatType = format
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.orange : .secondary)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(badge)
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color.primary.opacity(0.03))
            )
        }
        .buttonStyle(.plain)
    }

    private func summaryRow(label: String, value: String, isHighlightRed: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isHighlightRed ? Color.red : Color.primary)
        }
    }
}
