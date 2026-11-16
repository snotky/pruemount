import Foundation
import AppKit

/// 檔案系統格式枚舉
public enum FileSystemFormat: String, Codable, CaseIterable {
    case ntfs = "NTFS"
    case exfat = "exFAT"
    case fat32 = "FAT32"
    case apfs = "APFS"
    case hfsPlus = "Mac OS Extended"
    case other = "Unknown"

    public var isNTFS: Bool {
        self == .ntfs
    }

    public var supportsGhostClean: Bool {
        switch self {
        case .ntfs, .exfat, .fat32:
            return true
        case .apfs, .hfsPlus, .other:
            return true
        }
    }
}

/// 磁區掛載與健康狀態
public enum VolumeMountState: String, Codable {
    case mountedReadWrite = "rw"
    case mountedReadOnly = "ro"
    case dirtyLocked = "dirty"
    case unmounted = "unmounted"
}

/// 佔用硬碟導致無法退出的程序資訊
public struct BlockingProcessInfo: Identifiable, Equatable, Codable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let appName: String
    public let openFilePath: String
    public let bundleIdentifier: String?

    public init(pid: Int32, appName: String, openFilePath: String, bundleIdentifier: String? = nil) {
        self.pid = pid
        self.appName = appName
        self.openFilePath = openFilePath
        self.bundleIdentifier = bundleIdentifier
    }
}

/// 磁碟分區完整資料模型
public struct DiskVolume: Identifiable, Equatable {
    public let id: String                 // 例如 "disk4s1" 或 UUID
    public var bsdName: String            // 例如 "disk4s1"
    public var name: String               // 卷標名稱，例如 "Samsung T7 Shield"
    public var fileSystem: FileSystemFormat
    public var mountPoint: String?        // 例如 "/Volumes/Samsung T7 Shield"
    public var totalBytes: Int64
    public var freeBytes: Int64
    public var isExternal: Bool
    public var connectionBus: String      // 例如 "USB 3.2", "Thunderbolt", "Internal NVMe"
    public var mountState: VolumeMountState
    public var hasDirtyBit: Bool
    public var blockingProcess: BlockingProcessInfo?
    public var ghostFilesCount: Int
    public var ghostFilesBytes: Int64
    public var isSpotlightDisabled: Bool
    public var isDemo: Bool
    public var speedTestResult: SpeedTestResult?

    public init(
        id: String,
        bsdName: String,
        name: String,
        fileSystem: FileSystemFormat,
        mountPoint: String?,
        totalBytes: Int64,
        freeBytes: Int64,
        isExternal: Bool,
        connectionBus: String = "USB 3.2",
        mountState: VolumeMountState,
        hasDirtyBit: Bool = false,
        blockingProcess: BlockingProcessInfo? = nil,
        ghostFilesCount: Int = 0,
        ghostFilesBytes: Int64 = 0,
        isSpotlightDisabled: Bool = false,
        isDemo: Bool = false,
        speedTestResult: SpeedTestResult? = nil
    ) {
        self.id = id
        self.bsdName = bsdName
        self.name = name
        self.fileSystem = fileSystem
        self.mountPoint = mountPoint
        self.totalBytes = max(totalBytes, 1)
        self.freeBytes = min(max(freeBytes, 0), max(totalBytes, 1))
        self.isExternal = isExternal
        self.connectionBus = connectionBus
        self.mountState = mountState
        self.hasDirtyBit = hasDirtyBit
        self.blockingProcess = blockingProcess
        self.ghostFilesCount = ghostFilesCount
        self.ghostFilesBytes = ghostFilesBytes
        self.isSpotlightDisabled = isSpotlightDisabled
        self.isDemo = isDemo
        self.speedTestResult = speedTestResult
    }

    public var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1.0, max(0.0, Double(usedBytes) / Double(totalBytes)))
    }

    public var isMounted: Bool {
        mountState != .unmounted && mountPoint != nil
    }

    public var isWritable: Bool {
        mountState == .mountedReadWrite
    }

    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }

    public var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
    }

    public var formattedGhostBytes: String {
        ByteCountFormatter.string(fromByteCount: max(ghostFilesBytes, 4096), countStyle: .file)
    }

    public var iconSystemName: String {
        if !isExternal {
            return "internaldrive.fill"
        }
        if connectionBus.localizedCaseInsensitiveContains("SD") {
            return "sdcard.fill"
        }
        return "externaldrive.fill"
    }
}
