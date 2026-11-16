# PureMount 上線發佈操作手冊

這份清單整理了將 **PureMount** 正式對外公開販售的最後步驟，全部只需設定一次。

---

## 步驟 1：上線官方網站（GitHub Pages，免費 $0）

1. 在 GitHub 建立新的 Repository（例如 `puremount`），並推送本地程式碼：
   ```bash
   git remote add origin https://github.com/<你的帳號>/puremount.git
   git push -u origin main
   ```
2. 進入 GitHub Repository ➔ **Settings** ➔ **Pages**：
   - **Source** 選 `Deploy from a branch`
   - **Branch** 選 `main`，資料夾選 `/docs`，點擊 **Save**。
3. （選配）若要綁定 Hostinger 購買的網域：在 **Custom domain** 填入網域，並在 Hostinger DNS 新增一筆 CNAME 指向 `<你的帳號>.github.io`。

---

## 步驟 2：開通 LemonSqueezy 金流與授權（免月租費）

1. 註冊並登入 [LemonSqueezy](https://www.lemonsqueezy.com/) 建立商店，新增 2 個商品並**勾選 Generate License Key（Activation limit 設為 `3`）**：
   - **Lifetime Pro**：`US$ 9.99`（單次購買）
   - **Annual Pro**：`US$ 2.99 / year`（年度訂閱）
2. 將兩個商品的 Checkout 結帳網址填入：
   - 官網設定：[docs/config.js](docs/config.js) 中的 `lifetimeCheckoutUrl` 與 `annualCheckoutUrl`
   - App 內跳轉：[Sources/PureMount/Services/LicenseService.swift](Sources/PureMount/Services/LicenseService.swift) 中的 `checkoutURLAnnual` 與 `checkoutURLLifetime`

---

## 步驟 3：正式簽章、Apple 公證與上傳 DMG（官網 Direct 版）

1. 設定 `notarytool` 認證（只需執行一次）：
   ```bash
   xcrun notarytool store-credentials "puremount-notary" \
     --apple-id "your@email.com" \
     --team-id "YOUR_TEAM_ID" \
     --password "xxxx-xxxx-xxxx-xxxx"
   ```
2. 執行一鍵簽章＋公證＋打包腳本：
   ```bash
   chmod +x scripts/notarize_dmg.sh
   SIGN_IDENTITY="Developer ID Application: Your Name (YOUR_TEAM_ID)" \
   NOTARY_PROFILE="puremount-notary" \
   ./scripts/notarize_dmg.sh
   ```
3. 到 GitHub Repository ➔ **Releases** ➔ **Draft a new release**（Tag 填 `v1.0.0`），上傳 `build/PureMount-1.0.0.dmg`。
4. 更新 [docs/config.js](docs/config.js) 的 `dmgDownloadUrl` 為：
   ```js
   dmgDownloadUrl: "https://github.com/<你的帳號>/puremount/releases/latest/download/PureMount-1.0.0.dmg"
   ```
   推送至 GitHub 後官網下載按鈕即刻生效！

---

## 步驟 4：Mac App Store 送審（MAS 版）

- 請依 [APP_STORE_GUIDE.md](APP_STORE_GUIDE.md) 的商品 ID（`com.puremount.pro.lifetime` / `com.puremount.pro.annual`）、中英文商店文案與審核備註在 App Store Connect 完成建立並使用完整版 Xcode 以 `-DDISTRIBUTION_MAS` 編譯送審。
