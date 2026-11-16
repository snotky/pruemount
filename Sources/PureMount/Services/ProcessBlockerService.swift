import Foundation
import AppKit

/// 偵測「誰佔用了我的外接硬碟」並支援一鍵釋放佔用程序
public final class ProcessBlockerService: Sendable {
    public static let shared = ProcessBlockerService()

    private init() {}

    /// 透過 lsof 檢查指定掛載路徑目前被哪個使用者或背景程序佔用
    public func findBlockingProcess(forMountPoint mountPoint: String) -> BlockingProcessInfo? {
        guard FileManager.default.fileExists(atPath: mountPoint) else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -F pcn0 使用機器可讀欄位格式輸出 PID(p)、Command(c)、Name(n)
        process.arguments = ["-F", "pcn", "--", mountPoint]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            return nil
        }

        return parseLsofOutput(output, mountPoint: mountPoint)
    }

    /// 嘗試優雅關閉或強制終止佔用硬碟的應用程式
    @MainActor
    public func terminateBlockingProcess(_ blocker: BlockingProcessInfo) -> Bool {
        // 避免誤殺自身或核心 Finder
        let currentPID = ProcessInfo.processInfo.processIdentifier
        if blocker.pid == currentPID {
            return true
        }

        // 1. 優先透過 NSRunningApplication 優雅關閉
        if let app = NSRunningApplication(processIdentifier: blocker.pid) {
            if app.bundleIdentifier == "com.apple.finder" {
                return true
            }
            if app.terminate() {
                return true
            }
            if app.forceTerminate() {
                return true
            }
        }

        // 2. 對一般 CLI 或背景程序發送 SIGTERM
        let result = kill(blocker.pid, SIGTERM)
        return result == 0
    }

    private func parseLsofOutput(_ raw: String, mountPoint: String) -> BlockingProcessInfo? {
        var currentPID: Int32?
        var currentCommand: String?
        var currentPath: String?
        let myPID = ProcessInfo.processInfo.processIdentifier

        for line in raw.split(separator: "\n") {
            guard let prefix = line.first else { continue }
            let value = String(line.dropFirst())

            switch prefix {
            case "p":
                if let pid = Int32(value) {
                    currentPID = pid
                }
            case "c":
                currentCommand = value
            case "n":
                if value.hasPrefix(mountPoint),
                   let pid = currentPID,
                   pid != myPID {
                    currentPath = value
                    let friendlyName = resolveFriendlyAppName(pid: pid, fallback: currentCommand ?? "Process")
                    return BlockingProcessInfo(
                        pid: pid,
                        appName: friendlyName,
                        openFilePath: currentPath ?? mountPoint
                    )
                }
            default:
                break
            }
        }

        return nil
    }

    private func resolveFriendlyAppName(pid: Int32, fallback: String) -> String {
        if let app = NSRunningApplication(processIdentifier: pid),
           let localizedName = app.localizedName,
           !localizedName.isEmpty {
            return localizedName
        }
        return fallback
    }
}
