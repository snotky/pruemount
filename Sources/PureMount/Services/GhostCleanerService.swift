import Foundation

/// 掃描與清理結果統計
public struct GhostScanResult: Sendable {
    public let fileURLs: [URL]
    public let totalBytes: Int64

    public var count: Int { fileURLs.count }
}

/// 負責掃描與清除外接硬碟中 Windows 看不懂的 Mac 隱藏垃圾檔（._*, .DS_Store, .Trashes 等）
public final class GhostCleanerService: Sendable {
    public static let shared = GhostCleanerService()

    /// 根目錄下應被清理的系統隱藏資料夾名稱
    private let rootJunkDirectories: Set<String> = [
        ".Trashes",
        ".fseventsd",
        ".TemporaryItems"
    ]

    private init() {}

    /// 掃描指定掛載路徑下的所有 Mac 幽靈檔案（限制深度與最大時間以確保極速）
    public func scanVolume(at mountPoint: String, maxDepth: Int = 4) -> GhostScanResult {
        let rootURL = URL(fileURLWithPath: mountPoint, isDirectory: true)
        let fm = FileManager.default
        var matchedURLs: [URL] = []
        var totalSize: Int64 = 0

        // 1. 檢查根目錄特定垃圾資料夾
        for dirName in rootJunkDirectories {
            let candidate = rootURL.appendingPathComponent(dirName)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: candidate.path, isDirectory: &isDir) {
                matchedURLs.append(candidate)
                totalSize += directorySize(at: candidate)
            }
        }

        // 2. 遞迴掃描 .DS_Store 與 ._* (AppleDouble) 檔案
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .nameKey]
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants]
        ) else {
            return GhostScanResult(fileURLs: matchedURLs, totalBytes: totalSize)
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if enumerator.level > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            let fileName = fileURL.lastPathComponent

            // 跳過根目錄已列入的系統目錄或 Spotlight 目錄
            if enumerator.level == 1 && (rootJunkDirectories.contains(fileName) || fileName == ".Spotlight-V100") {
                enumerator.skipDescendants()
                continue
            }

            if isGhostFileName(fileName) {
                matchedURLs.append(fileURL)
                if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let size = values.fileSize {
                    totalSize += Int64(size)
                } else {
                    totalSize += 4096
                }
            }
        }

        return GhostScanResult(fileURLs: matchedURLs, totalBytes: totalSize)
    }

    /// 執行清除所有掃描到的 Mac 幽靈垃圾檔，回傳成功刪除的檔案數量與釋放容量
    public func cleanVolume(at mountPoint: String) -> (deletedCount: Int, freedBytes: Int64) {
        let scan = scanVolume(at: mountPoint, maxDepth: 6)
        let fm = FileManager.default
        var deleted = 0
        var freed: Int64 = 0

        for url in scan.fileURLs {
            let itemSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 4096
            do {
                try fm.removeItem(at: url)
                deleted += 1
                freed += itemSize
            } catch {
                // 若部分系統檔案受權限保護則略過，不中斷整體清理流程
                continue
            }
        }

        return (deleted, freed)
    }

    private func isGhostFileName(_ name: String) -> Bool {
        if name == ".DS_Store" || name == ".apdisk" {
            return true
        }
        if name.hasPrefix("._") && name.count > 2 {
            return true
        }
        return false
    }

    private func directorySize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) else {
            return 4096
        }
        var sum: Int64 = 0
        var count = 0
        while let fileURL = enumerator.nextObject() as? URL {
            count += 1
            if count > 300 { break }
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                sum += Int64(size)
            }
        }
        return max(sum, 4096)
    }
}
