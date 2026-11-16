import SwiftUI

/// 重新命名外接硬碟極簡對話框
public struct RenameVolumeSheetView: View {
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
            HStack(spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.renameSheetTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text("\(volume.name) · /dev/\(volume.bsdName)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            TextField(l10n.renameFieldPlaceholder, text: $monitor.renameInputText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))

            HStack {
                Spacer()
                Button(l10n.cancelAction) {
                    monitor.renamingVolume = nil
                }
                .keyboardShortcut(.cancelAction)

                Button(l10n.confirmRenameAction) {
                    Task {
                        await monitor.confirmRename()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(monitor.renameInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
