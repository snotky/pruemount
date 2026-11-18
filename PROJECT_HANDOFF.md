# PureMount — 跨 AI 協作專案交接文件 (Project Handoff)

> 本文件供 **Antigravity**、**ChatGPT** 與 **Claude** 協作使用。請在協助設計、撰寫文案或修改程式碼前先閱讀本文件，以確保架構、設計規範與商業規則一致。

---

## 1. 品牌與公司基本資料
- **公司名稱（法律與收款主體）**：Turbo Integration LLC
- **產品家族品牌**：PureApps（`PureMount` 為系列首發作品，未來將陸續推出其他 `Pure` 系列工具）
- **產品名稱**：PureMount — 純淨 NTFS 讀寫與外接硬碟管家
- **GitHub 儲存庫**：`https://github.com/snotky/pruemount`
- **官方網站 (GitHub Pages)**：`https://snotky.github.io/pruemount/`
- **系統支援**：macOS 13.0 (Ventura) 至 macOS 27（Apple Silicon & Intel Universal）
- **語系支援**：繁體中文 (`zh-Hant`)、英文 (`en`)，支援 App 內與官網一鍵即時切換

---

## 2. 產品設計哲學與視覺規範
1. **極簡零負擔（Contextual Minimalism）**：平時不堆砌複雜按鈕，只有當磁碟發生問題（如 Windows Dirty Bit 鎖定、背景程序佔用卡住退出）時，才自動浮現情境式解決橫幅。
2. **純淨無 Emoji 規範**：**App 與官網嚴禁使用任何彩色 Emoji（如 🌟、🪟、🧹 等）**，所有圖示統一使用 macOS 原生 SF Symbols（App 內）或純淨向量 SVG（官網）。
3. **官網設計風格**：融合 **Keka**（首屏居中大 App Icon ＋ 雙軌下載按鈕）與 **Dr.Buho**（亮白基底、柔和粉藍/青綠光暈、左圖右文交替 Showcase、Apple 認證卡與 4 格購買保障卡）。

---

## 3. 核心技術架構（雙軌制：Direct DMG vs Mac App Store）

### App 核心模組（`Sources/PureMount/`）
- **入口與生命週期**：`PureMountApp.swift`（支援 `WindowGroup` 主控台 + `MenuBarExtra` 狀態列彈窗）
- **多語系詞條**：`Localization/L10n.swift`
- **首次啟動權限閘門**：`Services/PermissionService.swift`、`Views/OnboardingPermissionView.swift`（Direct 版未開啟「完全取用磁碟」前擋在引導頁，開通後每 0.6 秒自動感應進入主控台；MAS 版自動略過）
- **NTFS 讀寫引擎**：`Services/NTFSDriverService.swift`
  - 內嵌免重開機引擎位於 `Resources/ntfs-engine/`（含 `ntfs-3g`、`ntfsfix`、`mkntfs`、`ntfslabel`、`go-nfsv4` 與 `libfuse-t.dylib`）
  - Direct 版透過 `sudo -S` 子程序執行（繼承 `PureMount.app` 的 Full Disk Access TCC 權限），掛載前自動偵測並修復 Dirty Bit，並檢查底層 `statfs` `MNT_RDONLY` 旗標確認真實可寫入
- **四大痛點自動化服務**：
  - `Services/GhostCleanerService.swift`：退出前自動清除 `._*`、`.DS_Store`、`.Trashes`、`.fseventsd`
  - `Services/ProcessBlockerService.swift`：透過 `lsof` 揪出佔用硬碟的程序並強制釋放退出
  - `Services/SleepGuardService.swift`：監聽 `NSWorkspace` 休眠/喚醒自動卸載與重掛載
  - `Services/SpotlightControlService.swift`：寫入 `.metadata_never_index` 防止 Spotlight 狂轉發燙
- **防呆磁碟工具**：`Services/DiskUtilityService.swift`、`Views/FormatVolumeWizardView.swift`、`Views/RenameVolumeSheetView.swift`
  - 格式化採用「Mac/Windows 雙平台 `exFAT` vs Windows 原生 `NTFS`」白話二選一（進階 `APFS`/`FAT32` 預設收合）
  - 具備系統碟實體硬鎖死＋兩步驟勾選確認防呆
- **授權與雙軌沙盒**：`Services/LicenseService.swift`、`Services/SandboxBookmarkService.swift`

---

## 4. 商業模式與定價規則
- **免費體驗規則**：免註冊贈送 **1 次有始有終的完整體驗**（從啟用 NTFS 讀寫到該硬碟安全退出算同 1 次）；掛載失敗絕不扣減次數。基本容量檢視、3 秒讀寫測速、一般退出永久免費。
- **官網 Direct 版（Stripe 金流）**：
  - **1 台 Mac**：`US$ 2.99 / 年` ｜ `US$ 9.99 終身買斷`
  - **3 台 Mac**：`US$ 4.99 / 年` ｜ `US$ 14.99 終身買斷`
- **Mac App Store 版（StoreKit 2 內購，不可包含外部官網購買連結）**：
  - `US$ 3.99 / 年` (`com.puremount.pro.annual`) ｜ `US$ 12.99 終身買斷` (`com.puremount.pro.lifetime`)

---

## 5. 官網與建置腳本位置
- **官網靜態檔案（GitHub Pages `/docs`）**：
  - `docs/index.html`、`docs/styles.css`、`docs/app.js`、`docs/config.js`（所有下載與 Stripe 結帳連結集中於 `docs/config.js`）
- **編譯與打包腳本**：
  - `./scripts/build_app.sh direct`（或 `mas`）：編譯並打包 `build/PureMount.app`
  - `./scripts/build_dmg.sh`：打包 `build/PureMount-1.0.0.dmg`
  - `./scripts/notarize_dmg.sh`：Developer ID 簽章與 Apple 公證

---

## 6. 協作分工建議
- **ChatGPT**：負責行銷文案、多語系翻譯潤飾、定價/轉換率策略、新品規劃。
- **Claude / Claude Code**：負責前端 HTML/CSS 視覺精修、Swift 程式碼審查與重構。
- **Antigravity**：負責 macOS 原生開發、本機 `swiftc` 編譯與除錯、`.dmg` 打包與 Git 同步推送。
