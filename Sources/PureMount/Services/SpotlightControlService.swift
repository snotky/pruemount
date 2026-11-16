import Foundation

/// 控制外接硬碟是否允許 macOS Spotlight 建立背景索引（避免發燙與退出被 mds_stores 卡住）
public final class SpotlightControlService: Sendable {
    public static let shared = SpotlightControlService()

    private let markerFileName = ".metadata_never_index"

    private init() {}

    /// 檢查該掛載路徑是否已停用 Spotlight 索引
    public func isIndexingDisabled(at mountPoint: String) -> Bool {
        let markerURL = URL(fileURLWithPath: mountPoint, isDirectory: true)
            .appendingPathComponent(markerFileName)
        return FileManager.default.fileExists(atPath: markerURL.path)
    }

    /// 切換是否停用 Spotlight 索引
    @discardableResult
    public func setIndexingDisabled(_ disabled: Bool, at mountPoint: String) -> Bool {
        let markerURL = URL(fileURLWithPath: mountPoint, isDirectory: true)
            .appendingPathComponent(markerFileName)
        let fm = FileManager.default

        if disabled {
            if fm.fileExists(atPath: markerURL.path) {
                return true
            }
            return fm.createFile(atPath: markerURL.path, contents: Data(), attributes: nil)
        } else {
            guard fm.fileExists(atPath: markerURL.path) else {
                return true
            }
            do {
                try fm.removeItem(at: markerURL)
                return true
            } catch {
                return false
            }
        }
    }
}
