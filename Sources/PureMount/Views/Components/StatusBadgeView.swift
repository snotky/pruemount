import SwiftUI

/// 磁碟讀寫與檔案系統極簡膠囊標籤
public struct StatusBadgeView: View {
    public let volume: DiskVolume
    public let l10n: L10n

    public init(volume: DiskVolume, l10n: L10n) {
        self.volume = volume
        self.l10n = l10n
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)

            Text("\(volume.fileSystem.rawValue) · \(statusText)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(dotColor.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var statusText: String {
        switch volume.mountState {
        case .mountedReadWrite:
            return l10n.readWriteBadge
        case .mountedReadOnly:
            return l10n.readOnlyBadge
        case .dirtyLocked:
            return l10n.dirtyLockedBadge
        case .unmounted:
            return l10n.unmountedBadge
        }
    }

    private var dotColor: Color {
        switch volume.mountState {
        case .mountedReadWrite:
            return Color.green
        case .mountedReadOnly:
            return Color.orange
        case .dirtyLocked:
            return Color.red
        case .unmounted:
            return Color.secondary
        }
    }

    private var textColor: Color {
        switch volume.mountState {
        case .mountedReadWrite:
            return Color.green
        case .mountedReadOnly:
            return Color.orange
        case .dirtyLocked:
            return Color.red
        case .unmounted:
            return Color.secondary
        }
    }

    private var backgroundColor: Color {
        dotColor.opacity(0.12)
    }
}

/// 極簡平滑容量進度條
public struct StorageBarView: View {
    public let usedPercentage: Double
    public let isDirtyOrLocked: Bool
    public var height: CGFloat = 10

    public init(usedPercentage: Double, isDirtyOrLocked: Bool = false, height: CGFloat = 10) {
        self.usedPercentage = usedPercentage
        self.isDirtyOrLocked = isDirtyOrLocked
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))

                Capsule()
                    .fill(barGradient)
                    .frame(width: max(height, geo.size.width * CGFloat(usedPercentage)))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: usedPercentage)
            }
        }
        .frame(height: height)
    }

    private var barGradient: LinearGradient {
        if isDirtyOrLocked {
            return LinearGradient(
                colors: [Color.orange, Color.red.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        if usedPercentage > 0.88 {
            return LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [Color.blue, Color.cyan.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
