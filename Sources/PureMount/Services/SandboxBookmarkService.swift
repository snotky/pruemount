import Foundation
import AppKit

/// Mac App Store (MAS) 沙盒永久授權管理器（Security-Scoped Bookmark）
/// 新隨身碟只需在第一次清理時點選「允許存取」，之後每次插拔即可全自動無感清理幽靈檔與管理索引
@MainActor
public final class SandboxBookmarkService {
    public static let shared = SandboxBookmarkService()

    private let storageKey = "pm.securityScopedBookmarks.v1"
    private var activeAccessedURLs: [String: URL] = [:]

    private init() {}

    /// 檢查指定掛載路徑是否已具備沙盒讀寫權限（官網 DMG 版預設為 true，MAS 版檢查 Bookmark）
    public func hasAccess(to mountPoint: String, track: DistributionTrack) -> Bool {
        if track == .direct {
            return true
        }
        if activeAccessedURLs[mountPoint] != nil {
            return true
        }
        return restoreBookmark(for: mountPoint) != nil
    }

    /// 確保取得該外接硬碟的沙盒存取權；若尚未授權則彈出一次定位於該硬碟根目錄的原生授權視窗
    public func ensureAccess(
        for volume: DiskVolume,
        track: DistributionTrack,
        lang: AppLanguage
    ) -> Bool {
        if volume.isDemo || track == .direct {
            return true
        }
        guard let mountPoint = volume.mountPoint else {
            return false
        }

        if let restored = restoreBookmark(for: mountPoint) {
            _ = restored.startAccessingSecurityScopedResource()
            activeAccessedURLs[mountPoint] = restored
            return true
        }

        // 彈出 macOS 原生 NSOpenPanel 定位於該外接硬碟根目錄，讓使用者一鍵授權並永久保存 Bookmark
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: mountPoint, isDirectory: true)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if lang == .zhHant {
            panel.title = "首次授權存取「\(volume.name)」"
            panel.message = "為符合 Mac App Store 安全沙盒規範，請直接點擊右下角「允許存取」，PureMount 即可永久記住此硬碟並自動清理隱藏垃圾檔。"
            panel.prompt = "允許存取此硬碟"
        } else {
            panel.title = "Grant One-Time Access to \"\(volume.name)\""
            panel.message = "To comply with Mac App Store Sandbox security, click 'Allow Access' below. PureMount will remember this drive permanently for automatic cleanup."
            panel.prompt = "Allow Access"
        }

        let response = panel.runModal()
        guard response == .OK, let selectedURL = panel.url else {
            return false
        }

        saveBookmark(for: selectedURL, keyPath: mountPoint)
        _ = selectedURL.startAccessingSecurityScopedResource()
        activeAccessedURLs[mountPoint] = selectedURL
        return true
    }

    private func saveBookmark(for url: URL, keyPath: String) {
        guard let data = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return
        }
        var dict = (UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Data]) ?? [:]
        dict[keyPath] = data
        UserDefaults.standard.set(dict, forKey: storageKey)
    }

    private func restoreBookmark(for keyPath: String) -> URL? {
        guard let dict = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Data],
              let data = dict[keyPath] else {
            return nil
        }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        if isStale {
            saveBookmark(for: url, keyPath: keyPath)
        }
        return url
    }
}
