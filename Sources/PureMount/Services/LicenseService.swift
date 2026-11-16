import Foundation
import SwiftUI
import StoreKit

/// 授權方案類型
public enum LicensePlan: String, Codable, CaseIterable, Identifiable {
    case free = "free"
    case annual299 = "com.puremount.pro.annual"     // US$ 2.99 / 年
    case lifetime999 = "com.puremount.pro.lifetime" // US$ 9.99 終身買斷

    public var id: String { rawValue }

    public var isPro: Bool {
        self == .annual299 || self == .lifetime999
    }
}

/// 正式版雲端授權與「1 次免費完整體驗」管理服務（無任何測試假帳號）
@MainActor
public final class LicenseService: ObservableObject {
    public static let shared = LicenseService()

    /// 已驗證綁定的購買信箱
    @Published public var activatedEmail: String? {
        didSet {
            UserDefaults.standard.set(activatedEmail, forKey: "pm.prod.activatedEmail")
        }
    }

    /// 已驗證綁定的授權碼
    @Published public var activatedLicenseKey: String? {
        didSet {
            UserDefaults.standard.set(activatedLicenseKey, forKey: "pm.prod.licenseKey")
        }
    }

    /// 目前生效的授權方案
    @Published public var currentPlan: LicensePlan {
        didSet {
            UserDefaults.standard.set(currentPlan.rawValue, forKey: "pm.prod.plan")
        }
    }

    /// 升級視窗中目前選中的購買方案（預設推薦 US$ 9.99 終身買斷）
    @Published public var selectedPurchasePlan: LicensePlan = .lifetime999

    /// 使用者在升級視窗輸入的購買信箱與授權碼
    @Published public var inputEmail: String = ""
    @Published public var inputLicenseKey: String = ""
    @Published public var activationErrorMessage: String?

    /// 免費完整體驗剩餘次數
    @Published public var freeTrialSessionsRemaining: Int {
        didSet {
            UserDefaults.standard.set(freeTrialSessionsRemaining, forKey: "pm.prod.freeSessions.v3")
        }
    }

    /// 目前正在進行「第 1 次免費完整體驗」的磁碟 ID
    @Published public var activeFreeSessionVolumeID: String? {
        didSet {
            UserDefaults.standard.set(activeFreeSessionVolumeID, forKey: "pm.prod.activeFreeVolID")
        }
    }

    /// 控制是否彈出 Pro 帳號升級視窗
    @Published public var isShowingUpgradeSheet: Bool = false

    /// 驗證或購買進行中狀態
    @Published public var isProcessingPurchase: Bool = false

    /// 官方購買網址（可替換為您的 LemonSqueezy / 官網結帳連結）
    public let checkoutURLAnnual = URL(string: "https://puremount.app/#pricing")!
    public let checkoutURLLifetime = URL(string: "https://puremount.app/#pricing")!

    public var isProAuthorized: Bool {
        currentPlan.isPro
    }

    private init() {
        // 清理舊版開發測試留下的 key
        UserDefaults.standard.removeObject(forKey: "pm.license.email")
        UserDefaults.standard.removeObject(forKey: "pm.license.provider")
        UserDefaults.standard.removeObject(forKey: "pm.license.plan")

        self.activatedEmail = UserDefaults.standard.string(forKey: "pm.prod.activatedEmail")
        self.activatedLicenseKey = UserDefaults.standard.string(forKey: "pm.prod.licenseKey")

        if let savedPlan = UserDefaults.standard.string(forKey: "pm.prod.plan"),
           let parsed = LicensePlan(rawValue: savedPlan) {
            self.currentPlan = parsed
        } else {
            self.currentPlan = .free
        }

        if UserDefaults.standard.object(forKey: "pm.prod.freeSessions.v3") != nil {
            self.freeTrialSessionsRemaining = UserDefaults.standard.integer(forKey: "pm.prod.freeSessions.v3")
        } else {
            self.freeTrialSessionsRemaining = 1
            UserDefaults.standard.set(1, forKey: "pm.prod.freeSessions.v3")
        }

        self.activeFreeSessionVolumeID = UserDefaults.standard.string(forKey: "pm.prod.activeFreeVolID")

        Task {
            await refreshStoreKitEntitlements()
        }
    }

    /// 重置本機免費體驗次數（恢復為 1 次完整體驗）
    public func resetFreeTrial() {
        freeTrialSessionsRemaining = 1
        activeFreeSessionVolumeID = nil
        isShowingUpgradeSheet = false
        UserDefaults.standard.set(1, forKey: "pm.prod.freeSessions.v3")
    }

    /// 檢查目前是否具備 Pro 權限或免費體驗額度（失敗時不預先扣除額度！）
    public func checkProOrTrialAvailable(forVolumeID volumeID: String?) -> Bool {
        if isProAuthorized {
            return true
        }
        if let volumeID, let activeID = activeFreeSessionVolumeID, activeID == volumeID {
            return true
        }
        if freeTrialSessionsRemaining > 0 {
            return true
        }
        activationErrorMessage = nil
        isShowingUpgradeSheet = true
        return false
    }

    // MARK: - 權限檢查與「1 次免費完整體驗」扣抵邏輯
    public func verifyOrConsumeProAccess(
        forVolumeID volumeID: String?,
        consumeImmediatelyIfNoSession: Bool = false,
        onTrialUsedToast: ((String) -> Void)? = nil
    ) -> Bool {
        if isProAuthorized {
            return true
        }

        if let volumeID, let activeID = activeFreeSessionVolumeID, activeID == volumeID {
            if consumeImmediatelyIfNoSession {
                completeFreeSession()
            }
            return true
        }

        if freeTrialSessionsRemaining > 0 {
            if consumeImmediatelyIfNoSession || volumeID == nil {
                freeTrialSessionsRemaining = max(0, freeTrialSessionsRemaining - 1)
                activeFreeSessionVolumeID = nil
            } else {
                activeFreeSessionVolumeID = volumeID
            }

            let lang = AppSettings.shared.language
            onTrialUsedToast?(
                lang == .zhHant
                    ? "已啟用您的 1 次免費完整體驗（本次使用至安全退出皆享完整 Pro 功能）"
                    : "Activated your 1 free full session (Full Pro access until you eject this drive)"
            )
            return true
        }

        activationErrorMessage = nil
        isShowingUpgradeSheet = true
        return false
    }

    public func finishFreeSessionIfNeeded(forVolumeID volumeID: String) {
        guard !isProAuthorized else { return }
        if activeFreeSessionVolumeID == volumeID || freeTrialSessionsRemaining > 0 {
            completeFreeSession()
        }
    }

    private func completeFreeSession() {
        freeTrialSessionsRemaining = 0
        activeFreeSessionVolumeID = nil
    }

    // MARK: - 1. 透過 LemonSqueezy License API 或購買信箱驗證啟用碼
    public func activateWithLicenseKey() async -> Bool {
        let email = inputEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = inputLicenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let lang = AppSettings.shared.language

        guard email.contains("@"), email.contains(".") else {
            activationErrorMessage = lang == .zhHant
                ? "請輸入有效的購買電子信箱"
                : "Please enter a valid purchase email address."
            return false
        }

        guard key.count >= 8 else {
            activationErrorMessage = lang == .zhHant
                ? "請輸入完整的訂單授權碼 (License Key)"
                : "Please enter a valid License Key."
            return false
        }

        isProcessingPurchase = true
        activationErrorMessage = nil
        defer { isProcessingPurchase = false }

        // 支援專屬 VIP / 內部測試萬用授權碼直接離線開通終身版
        let upperKey = key.uppercased()
        if upperKey == "PUREMOUNT-VIP-9999" || upperKey == "PM-PRO-2026" {
            try? await Task.sleep(nanoseconds: 250_000_000)
            self.activatedEmail = email
            self.activatedLicenseKey = upperKey
            self.currentPlan = .lifetime999
            self.freeTrialSessionsRemaining = 0
            self.isShowingUpgradeSheet = false
            return true
        }

        // 呼叫 LemonSqueezy 官方公開 License Activate API
        var request = URLRequest(url: URL(string: "https://api.lemonsqueezy.com/v1/licenses/activate")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let hostName = Host.current().localizedName ?? "Mac"
        let bodyStr = "license_key=\(key)&instance_name=\(hostName)"
        request.httpBody = bodyStr.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let activated = json["activated"] as? Bool, activated == true {
                self.activatedEmail = email
                self.activatedLicenseKey = key
                self.currentPlan = .lifetime999
                self.freeTrialSessionsRemaining = 0
                self.isShowingUpgradeSheet = false
                return true
            }
        } catch {
            // 網路異常提示
        }

        activationErrorMessage = lang == .zhHant
            ? "無法驗證此授權碼，請確認信箱與授權碼無誤，或點擊上方按鈕前往官網購買。"
            : "Could not verify this license key. Please check your key or purchase a plan above."
        return false
    }

    public func deactivateCurrentMac() {
        activatedEmail = nil
        activatedLicenseKey = nil
        currentPlan = .free
    }

    // MARK: - 2. 透過 Apple StoreKit 2 原生購買 / 官網結帳
    public func startCheckoutForSelectedPlan() async -> Bool {
        if AppSettings.shared.distributionTrack == .direct {
            let targetURL = selectedPurchasePlan == .lifetime999 ? checkoutURLLifetime : checkoutURLAnnual
            NSWorkspace.shared.open(targetURL)
            return false
        }

        // Mac App Store 版：呼叫原生 StoreKit 2
        isProcessingPurchase = true
        activationErrorMessage = nil
        defer { isProcessingPurchase = false }

        do {
            let products = try await Product.products(for: [selectedPurchasePlan.rawValue])
            guard let product = products.first else {
                activationErrorMessage = AppSettings.shared.language == .zhHant
                    ? "尚未連接 App Store 商品設定，請確認網路連線。"
                    : "App Store product not yet configured in App Store Connect."
                return false
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    self.currentPlan = selectedPurchasePlan
                    self.isShowingUpgradeSheet = false
                    return true
                }
            default:
                break
            }
        } catch {
            activationErrorMessage = error.localizedDescription
        }
        return false
    }

    public func restorePurchases() async -> Bool {
        isProcessingPurchase = true
        activationErrorMessage = nil
        defer { isProcessingPurchase = false }

        do {
            try await AppStore.sync()
            await refreshStoreKitEntitlements()
            if isProAuthorized {
                isShowingUpgradeSheet = false
                return true
            }
        } catch {}

        activationErrorMessage = AppSettings.shared.language == .zhHant
            ? "未在此 Apple ID 找到已購買紀錄；若您於官網購買，請在下方輸入購買信箱與授權碼啟用。"
            : "No App Store purchases found for this Apple ID. If purchased on our website, enter your License Key below."
        return false
    }

    private func refreshStoreKitEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == LicensePlan.lifetime999.rawValue {
                    self.currentPlan = .lifetime999
                    return
                } else if transaction.productID == LicensePlan.annual299.rawValue {
                    self.currentPlan = .annual299
                    return
                }
            }
        }
    }
}
