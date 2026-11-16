import Foundation
import SwiftUI

/// 支援的語言選項
public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case zhHant = "zh-Hant"
    case english = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .zhHant: return "繁體中文"
        case .english: return "English"
        }
    }

    public var shortBadge: String {
        switch self {
        case .zhHant: return "中"
        case .english: return "EN"
        }
    }
}

/// 雙軌制發行通道（官網 DMG 完整版 vs Mac App Store 沙盒版）
public enum DistributionTrack: String, CaseIterable, Identifiable, Codable {
    case direct = "direct"
    case appStore = "mas"

    public var id: String { rawValue }

    public func title(in lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.direct, .zhHant): return "官網 DMG 專業版 (Direct)"
        case (.direct, .english): return "Direct Pro Edition (DMG)"
        case (.appStore, .zhHant): return "App Store 沙盒版 (MAS)"
        case (.appStore, .english): return "Mac App Store Edition (MAS)"
        }
    }

    public func badge(in lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.direct, .zhHant): return "官網完整版"
        case (.direct, .english): return "Direct Pro"
        case (.appStore, .zhHant): return "App Store 版"
        case (.appStore, .english): return "App Store"
        }
    }
}

/// 多語系詞條與即時翻譯輔助器
public struct L10n {
    public let lang: AppLanguage

    public init(_ lang: AppLanguage) {
        self.lang = lang
    }

    private func t(_ zh: String, _ en: String) -> String {
        lang == .zhHant ? zh : en
    }

    // MARK: - 品牌與標題
    public var appName: String { "PureMount" }
    public var appSubtitle: String {
        t("純淨 NTFS 讀寫與外接硬碟管家", "Pure NTFS Read/Write & Drive Manager")
    }

    // MARK: - 側邊欄與分類
    public var externalDrivesSection: String {
        t("外接儲存裝置", "External Drives")
    }
    public var systemDrivesSection: String {
        t("內建磁碟", "Internal Disks")
    }
    public var noExternalDrivesTitle: String {
        t("尚未偵測到外接硬碟", "No External Drives Detected")
    }
    public var noExternalDrivesDesc: String {
        t("請插入 NTFS、exFAT 或 USB 外接硬碟，或開啟右下角「示範模式」預覽完整情境。",
          "Plug in an NTFS, exFAT, or USB drive, or turn on 'Demo Mode' below to preview all scenarios.")
    }
    public var enableDemoDrives: String {
        t("載入模擬測試硬碟 (Demo)", "Load Demo Drives")
    }
    public var demoModeActive: String {
        t("示範模式", "Demo Mode")
    }
    public var refreshDrives: String {
        t("重新掃描磁碟", "Rescan Disks")
    }

    // MARK: - 讀寫與檔案系統狀態
    public var readWriteBadge: String {
        t("可讀寫", "Read & Write")
    }
    public var readOnlyBadge: String {
        t("唯讀模式", "Read-Only")
    }
    public var dirtyLockedBadge: String {
        t("Windows 鎖定 (需修復)", "Locked by Windows")
    }
    public var unmountedBadge: String {
        t("已安全卸載", "Unmounted")
    }

    // MARK: - 儲存空間描述
    public func storageSummary(used: String, total: String, free: String) -> String {
        t("已使用 \(used) / 共 \(total)（可用 \(free)）",
          "\(used) used of \(total) (\(free) available)")
    }
    public var freeSpaceLabel: String {
        t("可用空間", "Available")
    }
    public var usedSpaceLabel: String {
        t("已用空間", "Used")
    }

    // MARK: - 核心操作按鈕（極簡設計）
    public var openInFinder: String {
        t("在 Finder 打開", "Open in Finder")
    }
    public var enableReadWrite: String {
        t("啟用 NTFS 讀寫", "Enable NTFS Read/Write")
    }
    public var switchToReadOnly: String {
        t("轉為唯讀保護", "Switch to Read-Only")
    }
    public var cleanAndEject: String {
        t("純淨安全退出", "Clean & Eject")
    }
    public var simpleEject: String {
        t("安全退出", "Eject")
    }
    public var remountDrive: String {
        t("重新掛載硬碟", "Mount Drive")
    }
    public var ejectAllExternal: String {
        t("一鍵退出全部外接碟", "Eject All External Drives")
    }

    // MARK: - 情境式智慧卡片 1：Windows Dirty Bit 髒磁區修復
    public var dirtyBitAlertTitle: String {
        t("偵測到 Windows 未正常退出或快速啟動鎖定", "Windows Fast Startup / Improper Eject Detected")
    }
    public var dirtyBitAlertDesc: String {
        t("此 NTFS 硬碟帶有髒位元 (Dirty Bit) 標記，為保護資料目前被強制鎖定為唯讀。點擊右側按鈕即可免回 Windows 直接修復並開啟讀寫。",
          "This NTFS volume has a Dirty Bit flag from Windows and is locked to Read-Only. Click repair to fix the journal and enable Read/Write on Mac.")
    }
    public var oneClickRepairAndMount: String {
        t("一鍵修復並啟用讀寫", "One-Click Repair & Mount R/W")
    }
    public var repairingVolume: String {
        t("正在修復 NTFS 日誌並重新掛載…", "Repairing NTFS journal and remounting…")
    }

    // MARK: - 情境式智慧卡片 2：誰佔用了硬碟？(Process Blocker)
    public func blockerAlertTitle(appName: String) -> String {
        t("無法立即退出：正被「\(appName)」佔用中", "Cannot Eject: In use by \"\(appName)\"")
    }
    public func blockerAlertDesc(pid: Int32, path: String) -> String {
        t("程序 PID \(pid) 正在存取「\(path)」，直接拔除可能導致檔案損毀。",
          "Process PID \(pid) has open files on \"\(path)\". Force releasing it will safely close the handle and eject.")
    }
    public var forceReleaseAndEject: String {
        t("關閉佔用程式並安全退出", "Close App & Safe Eject")
    }
    public var checkBlockingProcesses: String {
        t("檢查誰在佔用此硬碟", "Check Open File Handles")
    }

    // MARK: - 幽靈垃圾檔清理 (Ghost Files Cleaner)
    public var ghostCleanCardTitle: String {
        t("跨平台純淨守護", "Cross-Platform Purity")
    }
    public func ghostFilesFoundBadge(count: Int, size: String) -> String {
        if count == 0 {
            return t("無隱藏垃圾檔", "No Ghost Files")
        }
        return t("發現 \(count) 個 Mac 隱藏垃圾檔 (\(size))", "\(count) Mac ghost files (\(size))")
    }
    public var cleanGhostFilesNow: String {
        t("立即掃描清除", "Clean Now")
    }
    public var ghostCleanTooltip: String {
        t("自動清除 ._ 檔案、.DS_Store、.Spotlight-V100 與 .Trashes，插回 Windows、電視或車機不再出現滿滿亂碼隱藏檔。",
          "Removes ._* AppleDouble files, .DS_Store, .Spotlight-V100, and .Trashes so Windows PCs, Smart TVs, and car players stay clean.")
    }

    // MARK: - 極簡自動化開關 (4 個白話文開關)
    public var automationSectionTitle: String {
        t("智慧自動化守護", "Smart Automation")
    }
    public var toggleAutoNTFSReadWrite: String {
        t("插入 NTFS 硬碟時自動以「可讀寫」模式掛載", "Automatically mount NTFS drives in Read/Write mode")
    }
    public var toggleAutoNTFSReadWriteSub: String {
        t("無須手動切換，插上即可在 Finder 直接拖拉、修改與刪除檔案",
          "Seamlessly read, write, rename, and delete files directly in macOS Finder")
    }
    public var toggleAutoCleanOnEject: String {
        t("退出硬碟時自動清除 Windows 看不懂的隱藏垃圾檔", "Auto-clean Mac ghost files (._*, .DS_Store) before ejecting")
    }
    public var toggleAutoCleanOnEjectSub: String {
        t("點擊「純淨安全退出」時，背景秒刪 .DS_Store 與 ._ 資源檔並釋放垃圾桶空間",
          "Silently strips macOS metadata clutter right before unmounting the volume")
    }
    public var toggleSleepGuard: String {
        t("筆電闔蓋休眠時自動保護外接硬碟 (防未正常退出警告)", "Sleep Guard: Auto-unmount on Mac sleep & remount on wake")
    }
    public var toggleSleepGuardSub: String {
        t("休眠前自動安全卸載外接磁區，喚醒後自動掛載回桌面，保護硬碟不壞軌",
          "Prevents 'Disk Not Properly Ejected' warnings and NTFS corruption when closing your MacBook lid")
    }
    public var toggleDisableSpotlight: String {
        t("禁止 Spotlight 索引此硬碟（防止 Mac 發燙與退出卡住）", "Disable Spotlight indexing on this drive (Prevents overheating & lockups)")
    }
    public var toggleDisableSpotlightSub: String {
        t("寫入 .metadata_never_index，避免每次插上大容量硬碟時背景狂轉耗電",
          "Creates .metadata_never_index so macOS mds_stores won't thrash your drive")
    }

    // MARK: - 磁碟詳細資訊欄位
    public var detailsSectionTitle: String {
        t("磁碟技術資訊", "Volume Specifications")
    }
    public var deviceNodeLabel: String {
        t("裝置節點 (BSD)", "Device Node")
    }
    public var mountPointLabel: String {
        t("掛載路徑", "Mount Path")
    }
    public var fileSystemLabel: String {
        t("檔案系統格式", "File System")
    }
    public var connectionBusLabel: String {
        t("傳輸介面", "Connection Bus")
    }

    // MARK: - 設定與雙軌制引擎資訊
    public var settingsTitle: String {
        t("偏好設定與驅動狀態", "Preferences & Driver Status")
    }
    public var distributionTrackLabel: String {
        t("執行版本架構（雙軌制切換預覽）", "Distribution Track (Dual-Track Mode)")
    }
    public var driverStatusTitle: String {
        t("NTFS 底層引擎環境檢測", "NTFS Engine Environment Status")
    }
    public var launchAtLoginLabel: String {
        t("開機時自動啟動 PureMount 狀態列守護", "Launch PureMount in Menu Bar at Login")
    }
    public var openMainWindow: String {
        t("打開主控台視窗", "Open PureMount Console")
    }
    public var quitApp: String {
        t("結束 PureMount", "Quit PureMount")
    }

    // MARK: - 進階選單 (⋯ More Tools)
    public var moreToolsTooltip: String {
        t("更多硬碟工具（改名、測速、格式化）", "More Drive Tools (Rename, Speed Test, Format)")
    }
    public var menuRenameVolume: String {
        t("重新命名硬碟…", "Rename Drive…")
    }
    public var menuQuickSpeedTest: String {
        t("3 秒讀寫測速", "Quick Speed Test (3s)")
    }
    public var menuFormatVolume: String {
        t("格式化此硬碟…", "Format Drive…")
    }

    // MARK: - 重新命名視窗
    public var renameSheetTitle: String {
        t("重新命名外接硬碟", "Rename External Drive")
    }
    public var renameFieldPlaceholder: String {
        t("輸入新的硬碟名稱", "Enter new volume name")
    }
    public var cancelAction: String {
        t("取消", "Cancel")
    }
    public var confirmRenameAction: String {
        t("儲存名稱", "Save Name")
    }

    // MARK: - 3 秒讀寫測速
    public func speedResultSummary(read: Double, write: Double) -> String {
        if write > 0 {
            return t(
                String(format: "讀取 %.0f MB/s · 寫入 %.0f MB/s", read, write),
                String(format: "Read %.0f MB/s · Write %.0f MB/s", read, write)
            )
        } else {
            return t(
                String(format: "讀取 %.0f MB/s（唯讀模式）", read),
                String(format: "Read %.0f MB/s (Read-Only)", read)
            )
        }
    }

    // MARK: - 格式化雙重確認精靈（情境式二選一 + 方案 1 勾選解鎖）
    public var formatWizardStep1Title: String {
        t("格式化外接硬碟 — 步驟 1 / 2：選擇使用情境", "Format External Drive — Step 1 of 2: Choose Usage")
    }
    public var formatWizardStep2Title: String {
        t("最終確認 — 步驟 2 / 2：即將清空整顆硬碟", "Final Confirmation — Step 2 of 2: About to Erase Drive")
    }
    public func formatRedWarningTitle(name: String) -> String {
        t("警告：格式化將永久清空「\(name)」上的所有資料！",
          "Warning: Formatting will permanently erase ALL data on \"\(name)\"!")
    }
    public func formatRedWarningDesc(usedSize: String) -> String {
        t("此硬碟目前存放的 \(usedSize) 檔案與資料夾將被徹底抹除且無法復原，請務必確認已備份重要資料。",
          "All \(usedSize) of files currently on this drive will be permanently destroyed and cannot be recovered.")
    }
    public var formatUsageQuestion: String {
        t("請問這顆硬碟接下來主要會在哪裡使用？", "How will you primarily use this drive?")
    }

    // 情境卡 1：exFAT（預設最推薦）
    public var formatOptionExfatTitle: String {
        t("Mac 與 Windows 雙電腦通用（推薦）", "Mac & Windows Universal (Recommended)")
    }
    public var formatOptionExfatBadge: String {
        t("exFAT · 免裝軟體直讀直寫", "exFAT · Plug & Play")
    }
    public var formatOptionExfatDesc: String {
        t("插上任何 Mac 或 Windows 電腦都能直接讀寫，支援大型 4K 影片與超過 4GB 的大檔案。",
          "Read and write natively on any Mac or Windows PC without extra software. Supports large 4K videos and files >4GB.")
    }

    // 情境卡 2：NTFS（Windows 原生）
    public var formatOptionNtfsTitle: String {
        t("Windows 系統原生格式", "Windows Native Format")
    }
    public var formatOptionNtfsBadge: String {
        t("NTFS · 搭配 PureMount 讀寫", "NTFS · Read/Write with PureMount")
    }
    public var formatOptionNtfsDesc: String {
        t("Windows 電腦最穩定安全的原生格式；在您的 Mac 上透過 PureMount 即可完整讀寫。",
          "The most reliable native format for Windows PCs; read and write seamlessly on your Mac via PureMount.")
    }

    // 底部可收合的進階/特殊設備格式
    public var showAdvancedFormatsToggle: String {
        t("顯示進階 / 特殊設備格式（純 Mac APFS / 電視車機 FAT32）",
          "Show Advanced / Legacy Formats (Mac-Only APFS / TV & Car FAT32)")
    }
    public var formatOptionApfsTitle: String {
        t("只在 Mac 電腦上使用（注意：Windows 電腦將無法讀取）",
          "Mac Computers Only (Note: Unreadable on Windows PCs)")
    }
    public var formatOptionFat32Title: String {
        t("電視 / 車用音響 / 舊設備專用（注意：單一檔案不可超過 4GB）",
          "Smart TV / Car Audio / Legacy Devices (Note: Max 4GB per file)")
    }

    public var formatNewVolumeNameLabel: String {
        t("格式化後的硬碟名稱：", "New Volume Name:")
    }
    public var formatNextStepButton: String {
        t("下一步：進入最終確認…", "Next: Final Confirmation…")
    }
    public var formatBackStepButton: String {
        t("返回上一步", "Back")
    }

    // 步驟 2：最終確認與必勾選防呆核取方塊
    public var formatSummaryTargetDrive: String {
        t("即將清空的目標硬碟", "Target Drive to Erase")
    }
    public var formatSummaryDataToDestroy: String {
        t("將被永久抹除的資料量", "Data to be Permanently Erased")
    }
    public var formatSummaryTargetFormat: String {
        t("格式化後的新格式與名稱", "New Format & Volume Name")
    }
    public var formatMandatoryCheckboxLabel: String {
        t("我已備份重要檔案，了解此操作將永久清空整個硬碟且無法復原",
          "I have backed up my important files and understand this will permanently erase the entire drive")
    }
    public var formatFinalDestructiveButton: String {
        t("確認清空並格式化硬碟", "Confirm Erase & Format Drive")
    }

    // MARK: - 階段 C：帳號授權與 Pro 升級系統（無 Emoji 純淨排版）
    public var proBadgeAuthorized: String {
        t("Pro 專業版已授權", "Pro Licensed")
    }
    public func freeTrialAvailableBadge(remaining: Int) -> String {
        if remaining > 0 {
            return t("免費完整體驗：剩餘 \(remaining) 次", "Free Full Trial: \(remaining) left")
        }
        return t("免費體驗已用完", "Free Trial Used")
    }
    public var upgradeToProButton: String {
        t("升級 Pro", "Upgrade to Pro")
    }
    public var accountAndLicenseTitle: String {
        t("帳號綁定與 Pro 專業版授權", "Account & Pro License")
    }
    public var accountAndLicenseSubtitle: String {
        t("授權綁定於您的雲端帳號，官網版與 App Store 版跨通路互通，換電腦登入即可恢復權限。",
          "Your license is tied to your account across Direct and App Store editions. Sign in on any Mac to restore Pro.")
    }
    public var freeTrialExhaustedBannerTitle: String {
        t("您已完成 1 次免費完整體驗", "You've Completed Your 1 Free Full Session")
    }
    public var freeTrialExhaustedBannerDesc: String {
        t("升級 Pro 即可無限次使用 NTFS 讀寫掛載、Windows 鎖定一鍵修復、退出自動清除隱藏垃圾檔與格式化工具。",
          "Upgrade to Pro for unlimited NTFS Read/Write mounting, Windows lock repair, auto ghost-file cleanup, and drive formatting.")
    }

    // 帳號登入區塊
    public var accountSectionHeader: String {
        t("步驟 1：登入要綁定授權的帳號", "Step 1: Sign In to Bind Your License")
    }
    public var signInWithGoogle: String {
        t("使用 Google 帳號登入", "Continue with Google")
    }
    public var signInWithGitHub: String {
        t("使用 GitHub 帳號登入", "Continue with GitHub")
    }
    public var signInWithApple: String {
        t("使用 Apple 帳號登入", "Sign in with Apple")
    }
    public func signedInAsLabel(email: String, provider: String) -> String {
        t("已登入帳號：\(email) (\(provider))", "Signed in as: \(email) (\(provider))")
    }
    public var signOutAction: String {
        t("切換帳號 / 登出", "Sign Out")
    }

    // 價格方案二選一（US$ 9.99 終身買斷 vs US$ 2.99 / 年）
    public var planSectionHeader: String {
        t("步驟 2：選擇授權方案", "Step 2: Choose Your Plan")
    }
    public var planLifetimeTitle: String {
        t("終身買斷版 (Lifetime Pro)", "Lifetime Pro (One-Time Purchase)")
    }
    public var planLifetimePriceBadge: String {
        t("US$ 9.99 一次付清（推薦）", "US$ 9.99 One-Time (Recommended)")
    }
    public var planLifetimeDesc: String {
        t("約 NT$ 320，一次付費永久擁有，無任何續訂費用。包含未來所有版本更新與最多 3 台 Mac 裝置同時授權。",
          "Pay once, own forever with zero recurring fees. Includes all future updates and license for up to 3 Macs.")
    }
    public var planAnnualTitle: String {
        t("年度輕量方案 (Annual Pro)", "Annual Pro Plan")
    }
    public var planAnnualPriceBadge: String {
        t("US$ 2.99 / 年", "US$ 2.99 / year")
    }
    public var planAnnualDesc: String {
        t("約 NT$ 90 / 年（平均每月不到 NT$ 8），完整享有所有 NTFS 讀寫與純淨守護功能，隨時可取消。",
          "Less than $0.25/month. Full access to all NTFS Read/Write and purity features. Cancel anytime.")
    }

    public var activateProAction: String {
        t("立即開通 Pro 授權", "Activate Pro License")
    }
    public var restorePurchasesAction: String {
        t("恢復已購買授權", "Restore Purchases")
    }
    public var licenseTestModeHeader: String {
        t("授權狀態快速測試切換（開發預覽專用）", "License State Quick Switcher (Dev Preview)")
    }
}
