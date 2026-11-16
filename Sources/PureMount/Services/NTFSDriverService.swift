import Foundation
import AppKit
import Darwin

/// 系統與內建 NTFS 驅動元件檢測報告
public struct NTFSDriverEnvironment: Sendable {
    public let hasFSKitSupport: Bool
    public let hasMacFUSE: Bool
    public let ntfs3gPath: String?
    public let ntfsfixPath: String?
    public let goNfsv4Path: String?

    public var isDirectDriverReady: Bool {
        ntfs3gPath != nil && (goNfsv4Path != nil || hasMacFUSE)
    }
}

/// NTFS 讀寫掛載與 Windows Dirty Bit 修復核心引擎
/// 透過 PureMount 主程序直接呼叫 sudo -S 執行 ntfs-3g，確保 100% 繼承 PureMount.app 的「完全取用磁碟」TCC 權限
public final class NTFSDriverService: Sendable {
    public static let shared = NTFSDriverService()

    private init() {}

    private var candidateBinaryDirs: [String] {
        var dirs: [String] = []
        if let res = Bundle.main.resourcePath {
            dirs.append("\(res)/ntfs-engine/bin")
            dirs.append("\(res)/bin")
        }
        dirs.append(contentsOf: [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/sbin"
        ])
        return dirs
    }

    public func inspectEnvironment() -> NTFSDriverEnvironment {
        let fm = FileManager.default
        let hasFSKit = fm.fileExists(atPath: "/System/Library/Frameworks/FSKit.framework")
        let hasMacFUSE = fm.fileExists(atPath: "/Library/Filesystems/macfuse.fs")
            || fm.fileExists(atPath: "/Library/Filesystems/osxfuse.fs")

        let ntfs3g = locateBinary(named: "ntfs-3g")
        let ntfsfix = locateBinary(named: "ntfsfix")
        let goNfsv4 = locateBinary(named: "go-nfsv4")

        return NTFSDriverEnvironment(
            hasFSKitSupport: hasFSKit,
            hasMacFUSE: hasMacFUSE,
            ntfs3gPath: ntfs3g,
            ntfsfixPath: ntfsfix,
            goNfsv4Path: goNfsv4
        )
    }

    /// 檢查指定掛載路徑在 macOS VFS 底層是否「真正已掛載為可讀寫檔案系統」
    public func isMountPointTrulyWritable(_ path: String) -> Bool {
        var st = statfs()
        guard statfs(path, &st) == 0 else { return false }
        let mntFrom = withUnsafePointer(to: &st.f_mntfromname) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
                String(cString: $0)
            }
        }
        let mntOn = withUnsafePointer(to: &st.f_mntonname) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
                String(cString: $0)
            }
        }
        if mntOn == "/" || mntOn == "/System/Volumes/Data" || mntOn == "/private/tmp" {
            return false
        }
        if mntFrom.hasPrefix("127.0.0.1:/") || mntFrom.contains("fuse-t") {
            return true
        }
        let isReadOnlyFlag = (st.f_flags & UInt32(MNT_RDONLY)) != 0
        return !isReadOnlyFlag
    }

    /// 將 NTFS 磁區切換為「可讀寫 (Read-Write)」模式掛載
    public func mountReadWrite(
        volume: DiskVolume,
        track: DistributionTrack
    ) async -> Result<String, Error> {
        let devNode = "/dev/\(volume.bsdName)"
        let cleanDirName = volume.name.isEmpty ? volume.bsdName : volume.name.replacingOccurrences(of: "/", with: "_")
        let safeExportName = cleanDirName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "_")

        let targetMountPoint = volume.mountPoint ?? "/Volumes/\(cleanDirName)"
        let env = inspectEnvironment()

        guard let ntfs3gPath = env.ntfs3gPath else {
            return .failure(NSError(
                domain: "PureMount.NTFSDriver",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "找不到內建 ntfs-3g 讀寫核心"]
            ))
        }

        let userUID = getuid()
        let userGID = getgid()
        let goNfsv4 = env.goNfsv4Path ?? ""
        let ntfsfix = env.ntfsfixPath ?? ""
        let mountOptions = "rw,allow_other,recover,remove_hiberfile,uid=\(userUID),gid=\(userGID),umask=000,volname=\(safeExportName)"

        // 直接由 PureMount.app 子程序 sudo -S 執行（完整繼承 PureMount.app 的 Full Disk Access 權限）
        let sudoScript = """
        export FUSE_NFSSRV_PATH=\(shellQuote(goNfsv4))
        unmount_vol() {
            /sbin/umount -f \(shellQuote(targetMountPoint)) 2>/dev/null || true
            /usr/sbin/diskutil unmount force \(shellQuote(devNode)) 2>/dev/null || true
            /sbin/umount -f \(shellQuote(devNode)) 2>/dev/null || true
        }
        unmount_vol
        /bin/mkdir -p \(shellQuote(targetMountPoint))
        /usr/sbin/chown \(userUID):\(userGID) \(shellQuote(targetMountPoint))
        /bin/chmod 777 \(shellQuote(targetMountPoint))
        if ! \(shellQuote(ntfs3gPath)) -o \(shellQuote(mountOptions)) \(shellQuote(devNode)) \(shellQuote(targetMountPoint)) </dev/null; then
            if [ -n \(shellQuote(ntfsfix)) ] && [ -x \(shellQuote(ntfsfix)) ]; then
                \(shellQuote(ntfsfix)) -d \(shellQuote(devNode)) || true
                /bin/sleep 0.3
            fi
            unmount_vol
            /bin/mkdir -p \(shellQuote(targetMountPoint))
            /usr/sbin/chown \(userUID):\(userGID) \(shellQuote(targetMountPoint))
            /bin/chmod 777 \(shellQuote(targetMountPoint))
            \(shellQuote(ntfs3gPath)) -o \(shellQuote(mountOptions)) \(shellQuote(devNode)) \(shellQuote(targetMountPoint)) </dev/null
        fi
        """

        let ok = DiskUtilityService.shared.runWithAdminPrivileges(shellCommand: sudoScript)
        if ok {
            for _ in 0..<16 {
                try? await Task.sleep(nanoseconds: 250_000_000)
                if isMountPointTrulyWritable(targetMountPoint) {
                    return .success(targetMountPoint)
                }
            }
        }

        // 若未掛載成功，立即將硬碟重新掛回桌面，絕不讓硬碟消失
        _ = runProcess("/usr/sbin/diskutil", arguments: ["mount", devNode])

        let logMsg = (try? String(contentsOfFile: "/tmp/puremount-osascript.log", encoding: .utf8)) ?? ""
        let lang = await AppSettings.shared.language
        if logMsg.contains("Operation not permitted") {
            return .failure(NSError(
                domain: "PureMount.NTFSDriver",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey: lang == .zhHant
                        ? "請於「系統設定 ➔ 隱私權與安全性 ➔ 完全取用磁碟」確認已開啟 PureMount 並重開本程式。"
                        : "Please enable PureMount in System Settings > Privacy & Security > Full Disk Access and restart PureMount."
                ]
            ))
        }

        return .failure(NSError(
            domain: "PureMount.NTFSDriver",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: lang == .zhHant
                    ? "請確認輸入的 Mac 登入密碼正確。"
                    : "Please verify your Mac login password."
            ]
        ))
    }

    public func mountReadOnly(volume: DiskVolume) async -> Result<String, Error> {
        let devNode = "/dev/\(volume.bsdName)"
        if let mp = volume.mountPoint {
            _ = runProcess("/sbin/umount", arguments: ["-f", mp])
        }
        _ = runProcess("/usr/sbin/diskutil", arguments: ["unmount", "force", devNode])
        let status = runProcess("/usr/sbin/diskutil", arguments: ["mount", "readOnly", devNode])
        if status == 0 {
            return .success("/Volumes/\(volume.name)")
        }
        return .failure(NSError(domain: "PureMount.NTFSDriver", code: Int(status)))
    }

    public func repairDirtyBitAndMount(
        volume: DiskVolume,
        track: DistributionTrack
    ) async -> Result<String, Error> {
        return await mountReadWrite(volume: volume, track: track)
    }

    public func locateBinary(named name: String) -> String? {
        let fm = FileManager.default
        for dir in candidateBinaryDirs where !dir.isEmpty {
            let fullPath = "\(dir)/\(name)"
            if fm.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }
        return nil
    }

    private func shellQuote(_ s: String) -> String {
        return "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    @discardableResult
    private func runProcess(_ executable: String, arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
