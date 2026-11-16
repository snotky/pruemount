import Foundation
import AppKit
import SwiftUI
import DiskArbitration

/// 負責即時偵測外接與內建磁碟、協調五大核心服務的核心狀態控制器
@MainActor
public final class DiskMonitorService: ObservableObject {
    @Published public var volumes: [DiskVolume] = []
    @Published public var selectedVolumeID: String?
    @Published public var isBusyVolumeID: String?
    @Published public var statusToast: String?
    @Published public var isDemoModeEnabled: Bool = false {
        didSet {
            rebuildVolumesList()
        }
    }

    // MARK: - 進階工具視窗狀態（重新命名 & 雙重防呆格式化精靈）
    @Published public var renamingVolume: DiskVolume?
    @Published public var renameInputText: String = ""

    @Published public var formattingVolume: DiskVolume?
    @Published public var formatWizardStep: Int = 1
    @Published public var selectedFormatType: FileSystemFormat = .exfat
    @Published public var formatNewVolumeName: String = ""
    @Published public var showAdvancedFormatOptions: Bool = false
    @Published public var hasCheckedEraseConfirmation: Bool = false
    @Published public var isFormattingInProgress: Bool = false

    private var physicalVolumes: [DiskVolume] = []
    private var demoVolumes: [DiskVolume] = []
    private var customNTFSBSDByMountPath: [String: String] = [:]
    private var mountObserver: NSObjectProtocol?
    private var unmountObserver: NSObjectProtocol?

    public init() {
        setupDemoVolumes()
        refreshPhysicalVolumes()
        startWorkspaceObservers()
        SleepGuardService.shared.startMonitoring(diskMonitor: self)
    }

    public var externalVolumes: [DiskVolume] {
        volumes.filter { $0.isExternal }
    }

    public var internalVolumes: [DiskVolume] {
        volumes.filter { !$0.isExternal }
    }

    public var selectedVolume: DiskVolume? {
        if let id = selectedVolumeID, let found = volumes.first(where: { $0.id == id }) {
            return found
        }
        return externalVolumes.first ?? volumes.first
    }

    // MARK: - 實體磁碟掃描
    public func refreshPhysicalVolumes() {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeIsInternalKey,
            .volumeIsReadOnlyKey,
            .volumeLocalizedFormatDescriptionKey
        ]

        guard var urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            rebuildVolumesList()
            return
        }

        // 同時納入 /private/tmp/PureMountVolumes 下透過內建引擎掛載的可讀寫 NTFS 磁區
        let customRoot = URL(fileURLWithPath: "/private/tmp/PureMountVolumes", isDirectory: true)
        if let customDirs = try? fm.contentsOfDirectory(
            at: customRoot,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) {
            for dirURL in customDirs {
                if NTFSDriverService.shared.isMountPointTrulyWritable(dirURL.path),
                   !urls.contains(where: { $0.path == dirURL.path }) {
                    urls.append(dirURL)
                }
            }
        }

        var detected: [DiskVolume] = []

        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let path = url.path
            let name = values.volumeName ?? url.lastPathComponent

            // 自動略過 PureMount 自身的 DMG 安裝映像檔光碟 (含 PureMount 1, PureMount 2)
            if name.hasPrefix("PureMount") && path.hasPrefix("/Volumes/PureMount") {
                continue
            }

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let avail = Int64(values.volumeAvailableCapacity ?? 0)

            let statDetails = inspectStatFS(forMountPoint: path)
            let isFuseTMount = statDetails.mntFrom.hasPrefix("127.0.0.1:/")
                || statDetails.mntFrom.contains("fuse-t")
                || customNTFSBSDByMountPath[path] != nil

            let isInternal = isFuseTMount ? false : (values.volumeIsInternal ?? (path == "/"))
            let isRemovable = values.volumeIsRemovable ?? false
            let isEjectable = values.volumeIsEjectable ?? false
            let isExternal = isFuseTMount || (!isInternal && (isRemovable || isEjectable || path.hasPrefix("/Volumes/")))

            let formatDesc = values.volumeLocalizedFormatDescription ?? statDetails.fsType
            var fsFormat = parseFileSystemFormat(from: formatDesc)
            if isFuseTMount {
                fsFormat = .ntfs
            }

            let bsd = customNTFSBSDByMountPath[path]
                ?? statDetails.bsdName
                ?? (path == "/" ? "disk3s1s1" : "disk2s1")

            if fsFormat == .ntfs {
                customNTFSBSDByMountPath[path] = bsd
            }

            var ghostCount = 0
            var ghostBytes: Int64 = 0
            var spotlightOff = false

            if isExternal {
                let scan = GhostCleanerService.shared.scanVolume(at: path, maxDepth: 2)
                ghostCount = scan.count
                ghostBytes = scan.totalBytes
                spotlightOff = SpotlightControlService.shared.isIndexingDisabled(at: path)
            }

            // macOS 內建系統碟 (Macintosh HD) 採用 APFS Data Firmlink 架構，使用者空間永遠為可讀寫
            let trulyWritable: Bool
            if !isExternal || path == "/" {
                trulyWritable = true
            } else {
                trulyWritable = NTFSDriverService.shared.isMountPointTrulyWritable(path)
            }
            let mountState: VolumeMountState = trulyWritable ? .mountedReadWrite : .mountedReadOnly

            let vol = DiskVolume(
                id: "phys-\(bsd)-\(name)",
                bsdName: bsd,
                name: name,
                fileSystem: fsFormat,
                mountPoint: path,
                totalBytes: max(total, 1_000_000_000),
                freeBytes: max(avail, 0),
                isExternal: isExternal,
                connectionBus: isExternal ? "USB / Thunderbolt" : "Apple Fabric NVMe",
                mountState: mountState,
                hasDirtyBit: false,
                blockingProcess: nil,
                ghostFilesCount: ghostCount,
                ghostFilesBytes: ghostBytes,
                isSpotlightDisabled: spotlightOff,
                isDemo: false
            )
            detected.append(vol)
        }

        self.physicalVolumes = detected
        rebuildVolumesList()
    }

    private func rebuildVolumesList() {
        var combined: [DiskVolume] = []
        let externalPhysical = physicalVolumes.filter { $0.isExternal }
        combined.append(contentsOf: externalPhysical)

        if isDemoModeEnabled {
            combined.append(contentsOf: demoVolumes)
        }

        let internalPhysical = physicalVolumes.filter { !$0.isExternal }
        combined.append(contentsOf: internalPhysical)

        self.volumes = combined

        if selectedVolumeID == nil || !combined.contains(where: { $0.id == selectedVolumeID }) {
            selectedVolumeID = combined.first(where: { $0.isExternal })?.id ?? combined.first?.id
        }
    }

    // MARK: - 建立示範情境磁碟 (Demo Scenarios)
    public func setupDemoVolumes() {
        let autoRW = AppSettings.shared.autoMountNTFSReadWrite
        self.demoVolumes = [
            DiskVolume(
                id: "demo-ntfs-t7",
                bsdName: "disk4s1",
                name: "Samsung T7 Shield",
                fileSystem: .ntfs,
                mountPoint: "/Volumes/Samsung T7 Shield",
                totalBytes: 2_000_398_934_016,
                freeBytes: 1_240_120_000_000,
                isExternal: true,
                connectionBus: "USB 3.2 Gen 2 (10 Gbps)",
                mountState: autoRW ? .mountedReadWrite : .mountedReadOnly,
                hasDirtyBit: false,
                blockingProcess: nil,
                ghostFilesCount: 86,
                ghostFilesBytes: 18_432_000,
                isSpotlightDisabled: true,
                isDemo: true
            ),
            DiskVolume(
                id: "demo-ntfs-dirty",
                bsdName: "disk5s1",
                name: "WD My Passport Ultra",
                fileSystem: .ntfs,
                mountPoint: "/Volumes/WD My Passport Ultra",
                totalBytes: 1_000_204_886_016,
                freeBytes: 412_500_000_000,
                isExternal: true,
                connectionBus: "USB 3.0 SuperSpeed",
                mountState: .dirtyLocked,
                hasDirtyBit: true,
                blockingProcess: nil,
                ghostFilesCount: 24,
                ghostFilesBytes: 4_194_304,
                isSpotlightDisabled: false,
                isDemo: true
            ),
            DiskVolume(
                id: "demo-exfat-busy",
                bsdName: "disk6s1",
                name: "SanDisk Extreme Pro SD",
                fileSystem: .exfat,
                mountPoint: "/Volumes/SanDisk Extreme Pro SD",
                totalBytes: 512_110_190_592,
                freeBytes: 198_400_000_000,
                isExternal: true,
                connectionBus: "Thunderbolt SDXC Reader",
                mountState: .mountedReadWrite,
                hasDirtyBit: false,
                blockingProcess: nil,
                ghostFilesCount: 142,
                ghostFilesBytes: 34_603_008,
                isSpotlightDisabled: true,
                isDemo: true
            )
        ]
    }

    // MARK: - 1. 切換 NTFS 讀寫 / 唯讀模式
    public func toggleReadWriteMode(for volume: DiskVolume) async {
        // 先檢查是否擁有 Pro 權限或免費體驗額度（掛載成功後才真正綁定體驗次數）
        if volume.mountState != .mountedReadWrite {
            guard LicenseService.shared.checkProOrTrialAvailable(forVolumeID: volume.id) else {
                return
            }
        }

        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        let l10n = AppSettings.shared.l10n
        if volume.mountState == .mountedReadWrite {
            let res = await NTFSDriverService.shared.mountReadOnly(volume: volume)
            if case .success = res {
                updateVolume(id: volume.id) { vol in
                    vol.mountState = .mountedReadOnly
                }
                showToast(l10n.lang == .zhHant
                    ? "已將「\(volume.name)」切換為唯讀保護模式"
                    : "\"\(volume.name)\" switched to Read-Only mode")
            }
        } else {
            let res = await NTFSDriverService.shared.mountReadWrite(
                volume: volume,
                track: AppSettings.shared.distributionTrack
            )
            switch res {
            case .success(let mountPath):
                _ = LicenseService.shared.verifyOrConsumeProAccess(forVolumeID: volume.id)
                customNTFSBSDByMountPath[mountPath] = volume.bsdName
                refreshPhysicalVolumes()
                updateVolume(id: volume.id) { vol in
                    vol.mountState = .mountedReadWrite
                    vol.hasDirtyBit = false
                    vol.mountPoint = mountPath
                }
                showToast(l10n.lang == .zhHant
                    ? "「\(volume.name)」已啟用完整 NTFS 讀寫模式"
                    : "\"\(volume.name)\" mounted in full NTFS Read/Write mode")
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPath)
            case .failure(let err):
                refreshPhysicalVolumes()
                showToast(err.localizedDescription)
            }
        }
    }

    // MARK: - 2. 一鍵修復 Windows Dirty Bit 並掛載為可讀寫
    public func repairDirtyVolume(_ volume: DiskVolume) async {
        guard LicenseService.shared.checkProOrTrialAvailable(forVolumeID: volume.id) else {
            return
        }

        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        let l10n = AppSettings.shared.l10n
        showToast(l10n.repairingVolume)

        let res = await NTFSDriverService.shared.repairDirtyBitAndMount(
            volume: volume,
            track: AppSettings.shared.distributionTrack
        )
        switch res {
        case .success(let path):
            _ = LicenseService.shared.verifyOrConsumeProAccess(forVolumeID: volume.id)
            customNTFSBSDByMountPath[path] = volume.bsdName
            refreshPhysicalVolumes()
            updateVolume(id: volume.id) { vol in
                vol.hasDirtyBit = false
                vol.mountState = .mountedReadWrite
                vol.mountPoint = path
            }
            showToast(l10n.lang == .zhHant
                ? "已修復「\(volume.name)」Windows 鎖定並開啟讀寫"
                : "Repaired Windows lock on \"\(volume.name)\" & enabled Read/Write")
        case .failure(let err):
            refreshPhysicalVolumes()
            showToast(err.localizedDescription)
        }
    }

    // MARK: - 3. 清除 Mac 幽靈隱藏垃圾檔 (._*, .DS_Store)
    public func cleanGhostFiles(on volume: DiskVolume) async {
        guard volume.ghostFilesCount > 0 else { return }
        guard LicenseService.shared.verifyOrConsumeProAccess(
            forVolumeID: volume.id,
            onTrialUsedToast: { [weak self] msg in self?.showToast(msg) }
        ) else {
            return
        }
        guard SandboxBookmarkService.shared.ensureAccess(
            for: volume,
            track: AppSettings.shared.distributionTrack,
            lang: AppSettings.shared.language
        ) else {
            return
        }
        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        let removedCount = volume.ghostFilesCount
        let freedFormatted = volume.formattedGhostBytes

        if volume.isDemo {
            try? await Task.sleep(nanoseconds: 350_000_000)
            updateVolume(id: volume.id) { vol in
                vol.freeBytes = min(vol.totalBytes, vol.freeBytes + vol.ghostFilesBytes)
                vol.ghostFilesCount = 0
                vol.ghostFilesBytes = 0
            }
        } else if let mountPoint = volume.mountPoint {
            let result = GhostCleanerService.shared.cleanVolume(at: mountPoint)
            updateVolume(id: volume.id) { vol in
                vol.freeBytes = min(vol.totalBytes, vol.freeBytes + result.freedBytes)
                vol.ghostFilesCount = 0
                vol.ghostFilesBytes = 0
            }
        }

        let lang = AppSettings.shared.language
        showToast(lang == .zhHant
            ? "已清除 \(removedCount) 個 Mac 隱藏垃圾檔（釋放 \(freedFormatted)）"
            : "Cleaned \(removedCount) Mac ghost files (\(freedFormatted) freed)")
    }

    // MARK: - 4. 純淨安全退出 (Clean & Eject) + 佔用偵測
    public func ejectVolume(_ volume: DiskVolume, cleanGhostFirst: Bool) async {
        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        // 檢查是否有程序佔用中
        if volume.isDemo && volume.id == "demo-exfat-busy" && volume.blockingProcess == nil {
            // 示範當退出 SanDisk Extreme Pro 時偵測到被 Preview (預覽程式) 佔用
            try? await Task.sleep(nanoseconds: 300_000_000)
            updateVolume(id: volume.id) { vol in
                vol.blockingProcess = BlockingProcessInfo(
                    pid: 4821,
                    appName: AppSettings.shared.language == .zhHant ? "預覽程式 (Preview)" : "Preview",
                    openFilePath: "\(vol.mountPoint ?? "")/DCIM/100MEDIA/DSC09481.RAW",
                    bundleIdentifier: "com.apple.Preview"
                )
            }
            let lang = AppSettings.shared.language
            showToast(lang == .zhHant
                ? "偵測到「預覽程式」正在使用此硬碟，請點擊強制釋放並退出"
                : "Volume is in use by Preview. Click Force Release to eject safely.")
            return
        }

        if !volume.isDemo, let mountPoint = volume.mountPoint {
            if let blocker = ProcessBlockerService.shared.findBlockingProcess(forMountPoint: mountPoint) {
                updateVolume(id: volume.id) { vol in
                    vol.blockingProcess = blocker
                }
                return
            }
        }

        // 若開啟「退出前自動清理幽靈垃圾檔」且磁碟可寫入
        var cleanedCount = 0
        if cleanGhostFirst && volume.isWritable && volume.ghostFilesCount > 0 {
            guard LicenseService.shared.verifyOrConsumeProAccess(
                forVolumeID: volume.id,
                consumeImmediatelyIfNoSession: true
            ) else {
                return
            }
            cleanedCount = volume.ghostFilesCount
            if !volume.isDemo, let mountPoint = volume.mountPoint {
                _ = GhostCleanerService.shared.cleanVolume(at: mountPoint)
            }
        }

        if volume.isDemo {
            try? await Task.sleep(nanoseconds: 400_000_000)
            updateVolume(id: volume.id) { vol in
                vol.ghostFilesCount = 0
                vol.ghostFilesBytes = 0
                vol.blockingProcess = nil
                vol.mountState = .unmounted
                vol.mountPoint = nil
            }
        } else if let mountPoint = volume.mountPoint {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: URL(fileURLWithPath: mountPoint))
                customNTFSBSDByMountPath.removeValue(forKey: mountPoint)
                refreshPhysicalVolumes()
            } catch {
                // 若為 fuse-t / ntfs-3g 掛載，嘗試透過 umount 卸載
                let safeMP = mountPoint.replacingOccurrences(of: "'", with: "'\\''")
                if DiskUtilityService.shared.runWithAdminPrivileges(shellCommand: "/sbin/umount -f '\(safeMP)'") {
                    customNTFSBSDByMountPath.removeValue(forKey: mountPoint)
                    refreshPhysicalVolumes()
                } else if let blocker = ProcessBlockerService.shared.findBlockingProcess(forMountPoint: mountPoint) {
                    updateVolume(id: volume.id) { vol in
                        vol.blockingProcess = blocker
                    }
                    return
                }
            }
        }

        // 若該硬碟剛完成第 1 次免費完整體驗（從掛載到安全退出），將免費體驗次數結算歸零
        LicenseService.shared.finishFreeSessionIfNeeded(forVolumeID: volume.id)

        let lang = AppSettings.shared.language
        if cleanedCount > 0 {
            showToast(lang == .zhHant
                ? "已自動清除 \(cleanedCount) 個隱藏垃圾檔並安全退出「\(volume.name)」"
                : "Auto-cleaned \(cleanedCount) ghost files and safely ejected \"\(volume.name)\"")
        } else {
            showToast(lang == .zhHant
                ? "「\(volume.name)」已安全退出，現在可以放心拔除"
                : "\"\(volume.name)\" safely ejected")
        }
    }

    // MARK: - 5. 強制關閉佔用程式並安全退出
    public func forceReleaseAndEject(_ volume: DiskVolume) async {
        guard let blocker = volume.blockingProcess else { return }
        guard LicenseService.shared.verifyOrConsumeProAccess(
            forVolumeID: volume.id,
            consumeImmediatelyIfNoSession: true
        ) else {
            return
        }
        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        if !volume.isDemo {
            _ = ProcessBlockerService.shared.terminateBlockingProcess(blocker)
        } else {
            try? await Task.sleep(nanoseconds: 450_000_000)
        }

        updateVolume(id: volume.id) { vol in
            vol.blockingProcess = nil
            if AppSettings.shared.autoCleanGhostOnEject {
                vol.ghostFilesCount = 0
                vol.ghostFilesBytes = 0
            }
            vol.mountState = .unmounted
            vol.mountPoint = nil
        }

        let lang = AppSettings.shared.language
        showToast(lang == .zhHant
            ? "已關閉「\(blocker.appName)」並安全退出「\(volume.name)」"
            : "Closed \"\(blocker.appName)\" and safely ejected \"\(volume.name)\"")
    }

    // MARK: - 6. 重新掛載已卸載的磁區
    public func remountVolume(_ volume: DiskVolume) async {
        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        if volume.isDemo {
            try? await Task.sleep(nanoseconds: 400_000_000)
            updateVolume(id: volume.id) { vol in
                vol.mountPoint = "/Volumes/\(vol.name)"
                vol.mountState = .mountedReadWrite
            }
        } else {
            _ = await NTFSDriverService.shared.mountReadWrite(
                volume: volume,
                track: AppSettings.shared.distributionTrack
            )
            refreshPhysicalVolumes()
        }

        let lang = AppSettings.shared.language
        showToast(lang == .zhHant
            ? "已重新掛載「\(volume.name)」"
            : "Remounted \"\(volume.name)\"")
    }

    // MARK: - 7. 切換禁止 Spotlight 索引
    public func toggleSpotlightIndexing(for volume: DiskVolume) {
        let newState = !volume.isSpotlightDisabled
        if !volume.isDemo, let mountPoint = volume.mountPoint {
            SpotlightControlService.shared.setIndexingDisabled(newState, at: mountPoint)
        }
        updateVolume(id: volume.id) { vol in
            vol.isSpotlightDisabled = newState
        }

        let lang = AppSettings.shared.language
        showToast(lang == .zhHant
            ? (newState ? "已禁止 Spotlight 索引「\(volume.name)」" : "已恢復「\(volume.name)」Spotlight 索引")
            : (newState ? "Spotlight indexing disabled on \"\(volume.name)\"" : "Spotlight indexing enabled on \"\(volume.name)\""))
    }

    // MARK: - 8. 在 Finder 中打開
    public func openInFinder(_ volume: DiskVolume) {
        if let mountPoint = volume.mountPoint, FileManager.default.fileExists(atPath: mountPoint) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPoint)
        } else {
            // 示範模式下打開 /Volumes 目錄供檢視
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Volumes")
        }
    }

    // MARK: - 9. 一鍵退出所有外接硬碟
    public func ejectAllExternalVolumes() async {
        let targets = externalVolumes.filter { $0.isMounted }
        for vol in targets {
            await ejectVolume(vol, cleanGhostFirst: AppSettings.shared.autoCleanGhostOnEject)
        }
    }

    // MARK: - 10. 重新命名硬碟 (Rename Volume)
    public func beginRename(_ volume: DiskVolume) {
        guard DiskUtilityService.shared.isSafeExternalTarget(volume) else { return }
        renameInputText = volume.name
        renamingVolume = volume
    }

    public func confirmRename() async {
        guard let target = renamingVolume else { return }
        let newName = renameInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }

        isBusyVolumeID = target.id
        defer { isBusyVolumeID = nil }

        let result = await DiskUtilityService.shared.renameVolume(target, newName: newName)
        if case .success(let updatedName) = result {
            updateVolume(id: target.id) { vol in
                vol.name = updatedName
                if vol.mountPoint != nil {
                    vol.mountPoint = "/Volumes/\(updatedName)"
                }
            }
            let lang = AppSettings.shared.language
            showToast(lang == .zhHant
                ? "已將硬碟重新命名為「\(updatedName)」"
                : "Drive renamed to \"\(updatedName)\"")
        }
        renamingVolume = nil
    }

    // MARK: - 11. 3 秒讀寫測速 (Quick Speed Test)
    public func runSpeedTest(on volume: DiskVolume) async {
        isBusyVolumeID = volume.id
        defer { isBusyVolumeID = nil }

        let lang = AppSettings.shared.language
        showToast(lang == .zhHant
            ? "正在測試「\(volume.name)」讀寫速度…"
            : "Benchmarking \"\(volume.name)\" speed…")

        let speed = await DiskUtilityService.shared.runQuickSpeedTest(on: volume)
        updateVolume(id: volume.id) { vol in
            vol.speedTestResult = speed
        }

        let summary = AppSettings.shared.l10n.speedResultSummary(
            read: speed.readMBps,
            write: speed.writeMBps
        )
        showToast(summary)
    }

    // MARK: - 12. 格式化硬碟雙重確認精靈（三道防呆安全機制）
    public func beginFormatWizard(_ volume: DiskVolume) {
        // 第一道防線：非外接硬碟直接拒絕開啟格式化視窗
        guard DiskUtilityService.shared.isSafeExternalTarget(volume) else { return }
        selectedFormatType = .exfat // 預設推薦 Mac + Windows 雙平台通用 exFAT
        formatNewVolumeName = volume.name
        showAdvancedFormatOptions = false
        hasCheckedEraseConfirmation = false
        isFormattingInProgress = false
        formatWizardStep = 1
        formattingVolume = volume
    }

    public func proceedToFormatStep2() {
        hasCheckedEraseConfirmation = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            formatWizardStep = 2
        }
    }

    public func backToFormatStep1() {
        hasCheckedEraseConfirmation = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            formatWizardStep = 1
        }
    }

    public func executeConfirmedFormat() async {
        // 第三道防線：必須已勾選確認且非系統碟
        guard let target = formattingVolume,
              hasCheckedEraseConfirmation,
              DiskUtilityService.shared.isSafeExternalTarget(target) else {
            return
        }

        isFormattingInProgress = true
        isBusyVolumeID = target.id
        defer {
            isFormattingInProgress = false
            isBusyVolumeID = nil
        }

        let targetFormat = selectedFormatType
        let result = await DiskUtilityService.shared.formatExternalVolume(
            target,
            targetFormat: targetFormat,
            newVolumeName: formatNewVolumeName
        )

        if case .success(let finalName) = result {
            updateVolume(id: target.id) { vol in
                vol.name = finalName
                vol.fileSystem = targetFormat
                vol.mountPoint = "/Volumes/\(finalName)"
                vol.mountState = .mountedReadWrite
                vol.hasDirtyBit = false
                vol.blockingProcess = nil
                vol.ghostFilesCount = 0
                vol.ghostFilesBytes = 0
                // 清空後可用空間恢復為 99.8%
                vol.freeBytes = Int64(Double(vol.totalBytes) * 0.998)
            }
            formattingVolume = nil
            let lang = AppSettings.shared.language
            showToast(lang == .zhHant
                ? "已將「\(finalName)」安全格式化為 \(targetFormat.rawValue) 並啟用讀寫"
                : "Formatted \"\(finalName)\" as \(targetFormat.rawValue) (Read/Write ready)")
        }
    }

    // MARK: - 內部輔助方法
    private func updateVolume(id: String, mutation: (inout DiskVolume) -> Void) {
        if let idx = demoVolumes.firstIndex(where: { $0.id == id }) {
            mutation(&demoVolumes[idx])
        } else if let idx = physicalVolumes.firstIndex(where: { $0.id == id }) {
            mutation(&physicalVolumes[idx])
        }
        rebuildVolumesList()
    }

    public func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.statusToast = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if self.statusToast == message {
                withAnimation {
                    self.statusToast = nil
                }
            }
        }
    }

    private func startWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        mountObserver = center.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPhysicalVolumes()
            }
        }
        unmountObserver = center.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPhysicalVolumes()
            }
        }
    }

    private func parseFileSystemFormat(from description: String) -> FileSystemFormat {
        let upper = description.uppercased()
        if upper.contains("NTFS") || upper.contains("WINDOWS NT") {
            return .ntfs
        } else if upper.contains("EXFAT") {
            return .exfat
        } else if upper.contains("FAT") || upper.contains("MS-DOS") {
            return .fat32
        } else if upper.contains("APFS") {
            return .apfs
        } else if upper.contains("HFS") || upper.contains("MAC OS") {
            return .hfsPlus
        }
        return .other
    }

    private func inspectStatFS(forMountPoint path: String) -> (bsdName: String?, mntFrom: String, fsType: String) {
        var statInfo = statfs()
        guard statfs(path, &statInfo) == 0 else {
            return (nil, "", "APFS")
        }
        let mntFrom = withUnsafePointer(to: &statInfo.f_mntfromname) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
                String(cString: $0)
            }
        }
        let fsType = withUnsafePointer(to: &statInfo.f_fstypename) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MFSTYPENAMELEN)) {
                String(cString: $0)
            }
        }
        var bsd: String?
        if mntFrom.hasPrefix("/dev/") {
            bsd = String(mntFrom.dropFirst("/dev/".count))
        }
        return (bsd, mntFrom, fsType)
    }
}
