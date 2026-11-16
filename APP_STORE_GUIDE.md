# PureMount — App Store 上架與官網 DMG 發佈完整指南

本指南整理了將 **PureMount** 上架至 **Mac App Store (MAS)** 以及在 **官方網站販售 DMG** 所需的所有設定、文案與審核說明。

---

## 一、 App Store Connect 內購商品設定 (StoreKit 2 Product IDs)

在 App Store Connect 後台的 **「App 內購買項目 (In-App Purchases)」** 中，請建立以下 2 個商品（ID 必須與程式碼 `LicenseService.swift` 完全一致）：

| 商品類型 | 產品 ID (Product ID) | 參考名稱 | 定價級距 |
| :--- | :--- | :--- | :--- |
| **非消耗型項目 (Non-Consumable)** | `com.puremount.pro.lifetime` | PureMount Lifetime Pro (終身買斷版) | **US$ 9.99** (約 NT$ 320) |
| **自動續訂訂閱 (Auto-Renewable Subscription)** | `com.puremount.pro.annual` | PureMount Annual Pro (年度輕量方案) | **US$ 2.99 / 年** (約 NT$ 90 / 年) |

> **記得申請 Apple Small Business Program（小型企業計畫）**：
> 年營收低於 100 萬美元的開發者帳號申請後，App Store 抽成直接從 30% 降至 **15%**。

---

## 二、 中英文商店文案與關鍵字 (ASO)

### 1. 繁體中文 (`zh-Hant`)
- **App 名稱**：PureMount - 純淨 NTFS 讀寫與硬碟管家
- **副標題**：跨平台外接硬碟讀寫、隱藏檔清理與安全退出
- **關鍵字 (Keywords)**：
  `NTFS,外接硬碟,隨身碟,exFAT,磁碟工具,讀寫,格式化,退出硬碟,清理,DS_Store,Windows,掛載,Mount`
- **介紹文案**：
  > PureMount 是專為 Mac 與 Windows 跨平台用戶打造的極簡外接硬碟管家。
  > 
  > 【核心功能】
  > • NTFS 讀寫與鎖定修復：輕鬆解除外接硬碟唯讀限制與 Windows 快速啟動造成的鎖定狀態。
  > • 純淨安全退出 (Clean & Eject)：退出硬碟前自動清除 .DS_Store、._ 資源分支檔與隱藏垃圾桶，插回 Windows、電視或車載音響不再出現滿滿亂碼隱藏檔。
  > • 誰佔用了硬碟：退出失敗時自動揪出背景佔用程式，一鍵釋放並安全退出。
  > • 筆電休眠自動保護：闔上 MacBook 休眠前自動安全卸載外接硬碟，喚醒時自動重新掛載，徹底告別「磁碟未正常退出」警告。
  > • 3 秒讀寫測速與防呆格式化：內建高速讀寫測試，以及專為雙平台設計的防誤刪安全格式化精靈。

### 2. 英文 (`en-US`)
- **App Name**: PureMount - NTFS & Drive Manager
- **Subtitle**: Clean Eject, Disk Speed & Cross-Platform Utility
- **Keywords**:
  `ntfs,external,drive,disk,mount,eject,exfat,usb,clean,ds_store,windows,format,unmount,speed,utility`
- **Description**:
  > PureMount is the minimalist external drive manager designed for seamless Mac & Windows workflows.
  > 
  > [Key Features]
  > • NTFS Read/Write & Dirty Bit Repair: Unlock read-only external drives and resolve Windows Fast Startup locks in one click.
  > • Clean & Eject: Automatically strips macOS ghost files (._*, .DS_Store, .Trashes, .fseventsd) right before unmounting so your drives stay spotless on Windows PCs, Smart TVs, and car audio systems.
  > • Open File Unblocker: Instantly identifies which app is preventing your drive from ejecting and safely releases it.
  > • MacBook Sleep Guard: Automatically unmounts external drives before sleep and remounts them on wake to prevent 'Disk Not Properly Ejected' warnings.
  > • 3-Second Speed Benchmark & Safe Format Wizard: Verify USB transfer speeds and format drives for Mac & Windows with multi-step erase protection.

---

## 三、 給 Apple 審核員的審核備註 (App Review Notes)

提交審核時，請將以下英文說明貼入 App Store Connect 的 **「App Review Information -> Notes」** 欄位，能幫助審核員在沒有實體 NTFS 隨身碟的情況下 1 分鐘內順利完成功能驗證：

```text
Dear App Review Team,

Thank you for reviewing PureMount!

1. Testing External Drive Features (No Physical NTFS USB Drive Required):
- PureMount automatically detects physical external drives connected to the Mac.
- For your convenience during review, we have included an interactive "Demo Mode" (enabled by default in the bottom-left corner of the sidebar) with 3 simulated external drives ("Samsung T7 Shield NTFS", "WD My Passport Ultra", and "SanDisk Extreme Pro SD").
- You can test all core features—including 1 Free Full Trial session, Ghost File Cleanup, Dirty Bit Repair, Open File Unblocker, 3-Second Speed Test, and the 2-Step Safe Format Wizard—directly on these simulated drives or on any physical USB drive.

2. Free Tier vs. Pro Upgrade:
- Users can monitor drives, run 3-second speed benchmarks, eject drives, and enjoy 1 full Pro session completely free without signing in.
- After the 1 free full session is completed, users can sign in and unlock unlimited access via Annual Pro ($2.99/yr) or Lifetime Pro ($9.99 one-time).
```
