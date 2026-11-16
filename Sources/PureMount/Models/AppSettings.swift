import Foundation
import SwiftUI
import ServiceManagement

/// 全域偏好設定與狀態管理（支援 macOS 13+）
@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "pm.language")
        }
    }

    @Published public var distributionTrack: DistributionTrack {
        didSet {
            UserDefaults.standard.set(distributionTrack.rawValue, forKey: "pm.distributionTrack")
        }
    }

    /// 插入 NTFS 硬碟時自動以讀寫模式掛載
    @Published public var autoMountNTFSReadWrite: Bool {
        didSet {
            UserDefaults.standard.set(autoMountNTFSReadWrite, forKey: "pm.autoMountNTFSReadWrite")
        }
    }

    /// 退出硬碟時自動清除 Windows 看不懂的隱藏垃圾檔
    @Published public var autoCleanGhostOnEject: Bool {
        didSet {
            UserDefaults.standard.set(autoCleanGhostOnEject, forKey: "pm.autoCleanGhostOnEject")
        }
    }

    /// 筆電闔蓋休眠時自動安全卸載外接硬碟，喚醒時重掛載
    @Published public var sleepGuardEnabled: Bool {
        didSet {
            UserDefaults.standard.set(sleepGuardEnabled, forKey: "pm.sleepGuardEnabled")
        }
    }

    /// 開機自動啟動
    @Published public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "pm.launchAtLogin")
            updateLoginItem(enabled: launchAtLogin)
        }
    }

    /// 是否顯示內建系統磁碟
    @Published public var showInternalDrives: Bool {
        didSet {
            UserDefaults.standard.set(showInternalDrives, forKey: "pm.showInternalDrives")
        }
    }

    /// 控制偏好設定視窗顯示狀態
    @Published public var isShowingSettings: Bool = false

    public var l10n: L10n {
        L10n(language)
    }

    private init() {
        let savedLang = UserDefaults.standard.string(forKey: "pm.language")
        if let savedLang, let parsed = AppLanguage(rawValue: savedLang) {
            self.language = parsed
        } else {
            // 自動偵測系統語言，預設繁體中文
            let preferred = Locale.preferredLanguages.first ?? "zh-Hant"
            self.language = preferred.hasPrefix("en") ? .english : .zhHant
        }

        #if DISTRIBUTION_MAS
        let defaultTrack: DistributionTrack = .appStore
        #else
        let defaultTrack: DistributionTrack = .direct
        #endif

        if let savedTrack = UserDefaults.standard.string(forKey: "pm.distributionTrack"),
           let parsedTrack = DistributionTrack(rawValue: savedTrack) {
            self.distributionTrack = parsedTrack
        } else {
            self.distributionTrack = defaultTrack
        }

        self.autoMountNTFSReadWrite = UserDefaults.standard.object(forKey: "pm.autoMountNTFSReadWrite") as? Bool ?? true
        self.autoCleanGhostOnEject = UserDefaults.standard.object(forKey: "pm.autoCleanGhostOnEject") as? Bool ?? true
        self.sleepGuardEnabled = UserDefaults.standard.object(forKey: "pm.sleepGuardEnabled") as? Bool ?? true
        self.launchAtLogin = UserDefaults.standard.object(forKey: "pm.launchAtLogin") as? Bool ?? false
        self.showInternalDrives = UserDefaults.standard.object(forKey: "pm.showInternalDrives") as? Bool ?? true
    }

    public func toggleLanguage() {
        language = (language == .zhHant) ? .english : .zhHant
    }

    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // 在未簽章開發階段或沙盒預覽中忽略註冊錯誤
            }
        }
    }
}
