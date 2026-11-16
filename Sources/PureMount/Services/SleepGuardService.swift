import Foundation
import AppKit

/// 筆電闔蓋休眠自動卸載保護引擎（對標 Jettison，防止「磁碟未正常退出」與 NTFS 壞軌）
@MainActor
public final class SleepGuardService {
    public static let shared = SleepGuardService()

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var unmountedBSDNodesBeforeSleep: [String] = []
    public var onSleepProtectionTriggered: ((_ bsdNodes: [String]) -> Void)?
    public var onWakeRemountTriggered: ((_ bsdNodes: [String]) -> Void)?

    private init() {}

    public func startMonitoring(diskMonitor: DiskMonitorService) {
        stopMonitoring()

        let wsCenter = NSWorkspace.shared.notificationCenter

        sleepObserver = wsCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak diskMonitor] _ in
            Task { @MainActor in
                guard let self, let diskMonitor else { return }
                guard AppSettings.shared.sleepGuardEnabled else { return }
                await self.handleSystemWillSleep(diskMonitor: diskMonitor)
            }
        }

        wakeObserver = wsCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak diskMonitor] _ in
            Task { @MainActor in
                guard let self, let diskMonitor else { return }
                guard AppSettings.shared.sleepGuardEnabled else { return }
                await self.handleSystemDidWake(diskMonitor: diskMonitor)
            }
        }
    }

    public func stopMonitoring() {
        let wsCenter = NSWorkspace.shared.notificationCenter
        if let sleepObserver {
            wsCenter.removeObserver(sleepObserver)
            self.sleepObserver = nil
        }
        if let wakeObserver {
            wsCenter.removeObserver(wakeObserver)
            self.wakeObserver = nil
        }
    }

    private func handleSystemWillSleep(diskMonitor: DiskMonitorService) async {
        let externalMounted = diskMonitor.volumes.filter { $0.isExternal && $0.isMounted }
        guard !externalMounted.isEmpty else { return }

        unmountedBSDNodesBeforeSleep = externalMounted.map { $0.bsdName }
        for volume in externalMounted {
            await diskMonitor.ejectVolume(volume, cleanGhostFirst: AppSettings.shared.autoCleanGhostOnEject)
        }
        onSleepProtectionTriggered?(unmountedBSDNodesBeforeSleep)
    }

    private func handleSystemDidWake(diskMonitor: DiskMonitorService) async {
        guard !unmountedBSDNodesBeforeSleep.isEmpty else { return }
        let nodesToRemount = unmountedBSDNodesBeforeSleep
        unmountedBSDNodesBeforeSleep.removeAll()

        for bsd in nodesToRemount {
            if let vol = diskMonitor.volumes.first(where: { $0.bsdName == bsd }) {
                await diskMonitor.remountVolume(vol)
            } else {
                _ = runDiskutilMount(bsdName: bsd)
            }
        }
        diskMonitor.refreshPhysicalVolumes()
        onWakeRemountTriggered?(nodesToRemount)
    }

    private func runDiskutilMount(bsdName: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["mount", "/dev/\(bsdName)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
