import SwiftUI
import AppKit

/// 首次啟動強制權限引導閘門（未開啟「完全取用磁碟」前擋在主控台外，開通後自動感應進入）
public struct OnboardingPermissionView: View {
    @ObservedObject public var permissions: PermissionService
    @ObservedObject public var settings: AppSettings

    public init(permissions: PermissionService, settings: AppSettings) {
        self.permissions = permissions
        self.settings = settings
    }

    private var l10n: L10n { settings.l10n }

    public var body: some View {
        VStack(spacing: 0) {
            // 頂部標題與語系切換
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.onboardingTitle)
                            .font(.system(size: 19, weight: .bold))
                        Text(l10n.onboardingSubtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        settings.toggleLanguage()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 11.5))
                        Text(settings.language == .zhHant ? "中 / EN" : "EN / 中")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.primary.opacity(0.07)))
                }
                .buttonStyle(.plain)
            }
            .padding(28)

            Divider()

            // 中間雙欄：左側「可拖曳圖示卡」＋ 右側「3 步驟指引」
            HStack(alignment: .center, spacing: 26) {
                // 左側可拖曳卡片
                VStack(spacing: 14) {
                    Text(l10n.onboardingDragCardTitle)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

                        Text("PureMount.app")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        Color.accentColor.opacity(0.45),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    )
                            )
                    )
                    .onDrag {
                        NSItemProvider(object: Bundle.main.bundleURL as NSURL)
                    }
                    .help(l10n.onboardingDragCardHint)

                    Text(l10n.onboardingDragCardHint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 240)

                // 右側 3 步驟指引與主操作按鈕
                VStack(alignment: .leading, spacing: 18) {
                    stepRow(
                        icon: "gearshape.fill",
                        color: .blue,
                        title: l10n.onboardingStep1Title,
                        description: l10n.onboardingStep1Desc
                    )

                    stepRow(
                        icon: "hand.draw.fill",
                        color: .teal,
                        title: l10n.onboardingStep2Title,
                        description: l10n.onboardingStep2Desc
                    )

                    stepRow(
                        icon: "checkmark.shield.fill",
                        color: .green,
                        title: l10n.onboardingStep3Title,
                        description: l10n.onboardingStep3Desc
                    )

                    HStack(spacing: 12) {
                        Button {
                            permissions.openFullDiskAccessSettings()
                        } label: {
                            Label(l10n.onboardingOpenSettingsButton, systemImage: "lock.open.display")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            permissions.revealAppInFinder()
                        } label: {
                            Text(l10n.onboardingRevealInFinder)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(28)

            Spacer()

            Divider()

            // 底部即時權限感應狀態列
            HStack(spacing: 12) {
                if permissions.hasFullDiskAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.green)
                    Text(l10n.onboardingGrantedStatus)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.green)
                } else {
                    ProgressView()
                        .controlSize(.small)
                    Text(l10n.onboardingWaitingStatus)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(l10n.onboardingCheckNow) {
                    _ = permissions.refreshFullDiskAccessStatus()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.03))
        }
        .frame(minWidth: 780, minHeight: 500)
        .onAppear {
            _ = permissions.refreshFullDiskAccessStatus()
            if !permissions.hasFullDiskAccess {
                permissions.startPolling()
            }
        }
    }

    private func stepRow(
        icon: String,
        color: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
