import Foundation
import AppKit
import Darwin

/// 監控與引導 macOS「完全取用磁碟 (Full Disk Access)」權限狀態的服務
@MainActor
public final class PermissionService: ObservableObject {
    public static let shared = PermissionService()

    @Published public var hasFullDiskAccess: Bool = false
    @Published public var isChecking: Bool = false

    private var pollingTask: Task<Void, Never>?

    private init() {
        refreshFullDiskAccessStatus()
        if !hasFullDiskAccess && AppSettings.shared.distributionTrack == .direct {
            startPolling()
        }
    }

    /// 檢查目前 App 是否已取得 macOS「完全取用磁碟 (Full Disk Access)」授權
    @discardableResult
    public func refreshFullDiskAccessStatus() -> Bool {
        // Mac App Store 沙盒版不依賴 Full Disk Access
        if AppSettings.shared.distributionTrack == .appStore {
            hasFullDiskAccess = true
            stopPolling()
            return true
        }

        let granted = Self.probeTCCProtectedFiles()
        if granted != hasFullDiskAccess {
            hasFullDiskAccess = granted
        }
        if granted {
            stopPolling()
        }
        return granted
    }

    /// 開始背景自動感應權限開通（每 0.6 秒檢查一次，開通後自動停止）
    public func startPolling() {
        guard pollingTask == nil else { return }
        guard AppSettings.shared.distributionTrack == .direct else { return }

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 600_000_000)
                guard let self, !Task.isCancelled else { break }
                if self.refreshFullDiskAccessStatus() {
                    break
                }
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// 一鍵打開「系統設定 ➔ 隱私權與安全性 ➔ 完全取用磁碟」
    public func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
        startPolling()
    }

    /// 在 Finder 中顯示 PureMount.app（備用）
    public func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    /// 嘗試以唯讀開啟 TCC 受保護檔案，驗證是否已通過系統「完全取用磁碟」檢查
    private static func probeTCCProtectedFiles() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/Library/Safari/Bookmarks.plist",
            "\(home)/Library/Safari/CloudTabs.db",
            "\(home)/Library/Messages/chat.db",
            "\(home)/Library/Mail/V10/MailData/Envelope Index",
            "/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        var foundAnyCandidate = false
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                foundAnyCandidate = true
                let fd = Darwin.open(path, O_RDONLY)
                if fd >= 0 {
                    Darwin.close(fd)
                    return true
                }
            }
        }

        // 若以上 TCC 保護檔案都不存在於此使用者環境，嘗試檢查使用者 TimeMachine 或系統 TCC 目錄
        if !foundAnyCandidate {
            let tccDir = "/Library/Application Support/com.apple.TCC"
            if let items = try? FileManager.default.contentsOfDirectory(atPath: tccDir), !items.isEmpty {
                return true
            }
        }
        return false
    }
}
