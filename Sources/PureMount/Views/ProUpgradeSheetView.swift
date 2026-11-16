import SwiftUI

/// 正式版 Pro 專業版購買與授權碼綁定視窗（無任何測試假帳號）
public struct ProUpgradeSheetView: View {
    @ObservedObject public var license: LicenseService
    @ObservedObject public var settings: AppSettings
    @ObservedObject public var monitor: DiskMonitorService

    private var l10n: L10n { settings.l10n }
    private var isZh: Bool { settings.language == .zhHant }

    public init(license: LicenseService, settings: AppSettings, monitor: DiskMonitorService) {
        self.license = license
        self.settings = settings
        self.monitor = monitor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. 標題列
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.accountAndLicenseTitle)
                        .font(.system(size: 17, weight: .bold))
                    Text(l10n.accountAndLicenseSubtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    license.isShowingUpgradeSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // 2. 方案選擇區（US$ 9.99 終身買斷 vs US$ 2.99 / 年）
            VStack(alignment: .leading, spacing: 10) {
                Text(isZh ? "選擇您的 Pro 授權方案" : "Choose Your Pro License Plan")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.secondary)

                planCard(
                    plan: .lifetime999,
                    title: l10n.planLifetimeTitle,
                    priceBadge: l10n.planLifetimePriceBadge,
                    description: l10n.planLifetimeDesc,
                    accent: .blue
                )

                planCard(
                    plan: .annual299,
                    title: l10n.planAnnualTitle,
                    priceBadge: l10n.planAnnualPriceBadge,
                    description: l10n.planAnnualDesc,
                    accent: .teal
                )
            }

            Divider()

            // 3. 購買信箱與授權碼綁定區
            if license.isProAuthorized {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isZh ? "此 Mac 已正式開通 PureMount Pro 專業版" : "PureMount Pro is active on this Mac")
                            .font(.system(size: 13, weight: .bold))
                        if let email = license.activatedEmail {
                            Text(isZh ? "綁定信箱：\(email)" : "Bound Email: \(email)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(isZh ? "解除此裝置綁定" : "Deactivate Mac") {
                        license.deactivateCurrentMac()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.08))
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isZh ? "已在官網購買？輸入購買信箱與授權碼綁定此 Mac" : "Already purchased on our website? Enter your Email & License Key")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        TextField(isZh ? "購買時的電子信箱 (Email)" : "Purchase Email", text: $license.inputEmail)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))

                        TextField(isZh ? "訂單授權碼 (License Key)" : "License Key", text: $license.inputLicenseKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5, design: .monospaced))

                        Button(isZh ? "驗證並啟用" : "Activate") {
                            Task {
                                let ok = await license.activateWithLicenseKey()
                                if ok {
                                    monitor.showToast(isZh
                                        ? "已成功驗證並開通 PureMount Pro 專業版"
                                        : "Successfully activated PureMount Pro")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(license.isProcessingPurchase)
                    }

                    if let err = license.activationErrorMessage {
                        Text(err)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }

            Divider()

            // 4. 底部主購買與恢復列
            HStack(spacing: 14) {
                Button {
                    Task {
                        let ok = await license.restorePurchases()
                        if ok {
                            monitor.showToast(isZh
                                ? "已成功恢復您的 Pro 專業版授權"
                                : "Successfully restored your Pro license")
                        }
                    }
                } label: {
                    Text(l10n.restorePurchasesAction)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(license.isProcessingPurchase)

                Button {
                    license.resetFreeTrial()
                    monitor.showToast(isZh
                        ? "已重置免費完整體驗次數（剩餘 1 次）"
                        : "Free trial session has been reset (1 left)")
                } label: {
                    Text(isZh ? "重置免費體驗" : "Reset Free Trial")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                if license.isProcessingPurchase {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 8)
                }

                Button(l10n.cancelAction) {
                    license.isShowingUpgradeSheet = false
                }

                if !license.isProAuthorized {
                    Button {
                        Task {
                            let ok = await license.startCheckoutForSelectedPlan()
                            if ok {
                                monitor.showToast(isZh
                                    ? "已成功開通 PureMount Pro 專業版授權"
                                    : "PureMount Pro License Activated")
                            }
                        }
                    } label: {
                        Label(
                            settings.distributionTrack == .direct
                                ? (isZh ? "前往官網購買此方案" : "Purchase Selected Plan")
                                : l10n.activateProAction,
                            systemImage: "lock.open.fill"
                        )
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(license.isProcessingPurchase)
                }
            }
        }
        .padding(24)
        .frame(width: 560)
    }

    private func planCard(
        plan: LicensePlan,
        title: String,
        priceBadge: String,
        description: String,
        accent: Color
    ) -> some View {
        let isSelected = license.selectedPurchasePlan == plan
        return Button {
            license.selectedPurchasePlan = plan
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
                        Text(priceBadge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? accent : .primary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(isSelected ? accent.opacity(0.15) : Color.primary.opacity(0.07))
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
                                isSelected ? accent.opacity(0.55) : Color.primary.opacity(0.09),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
