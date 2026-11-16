# PureMount — 純淨 NTFS 讀寫與外接硬碟管家

**PureMount** 是一款對標 Tuxera NTFS 與 Paragon NTFS、專為現代 macOS（支援 **macOS 13.0 Ventura / 14 Sonoma / 15 Sequoia+**）打造的極簡跨平台外接硬碟管理工具，支援**繁體中文 / 英文**即時切換，並採用**雙軌制（官網 DMG 專業版 + Mac App Store 沙盒合規版）**架構設計。

---

## ✨ 五大核心功能（極簡零負擔設計）

1. **🟢 NTFS 原生讀寫切換 (`NTFSDriverService`)**
   - 插入 NTFS 硬碟自動偵測，支援一鍵在「可讀寫 (Read-Write)」與「唯讀保護 (Read-Only)」模式間無縫切換。
2. **🧹 跨平台「Mac 幽靈垃圾檔」自動淨化 (`GhostCleanerService`)**
   - 點擊「純淨安全退出 (Clean & Eject)」時，自動秒刪 Windows、智慧電視與車用音響看不懂的 `._*` (AppleDouble)、`.DS_Store`、`.Trashes`、`.fseventsd` 隱藏檔案並釋放空間。
3. **🛠️ Windows 快速啟動 / 髒位元 (Dirty Bit) 一鍵修復 (`NTFSDriverService`)**
   - 平時隱藏不佔畫面；當偵測到 NTFS 硬碟因 Windows 未正常退出或休眠鎖死時，自動浮現**「一鍵修復並啟用讀寫」**橫幅，免回 Windows 跑 `chkdsk`。
4. **🔒「誰佔用了硬碟？」退出卡住偵測與強制釋放 (`ProcessBlockerService`)**
   - 當退出硬碟被背景程序（如預覽程式、Spotlight `mds`）卡住時，自動透過 `lsof` 與 `NSWorkspace` 揪出佔用 App，一鍵關閉佔用程式並安全退出。
5. **💤 筆電闔蓋休眠保護 (`SleepGuardService`) & 🚫 Spotlight 防發燙 (`SpotlightControlService`)**
   - 偵測 MacBook 即將休眠時自動安全卸載外接硬碟、喚醒時自動重新掛載；並支援一鍵寫入 `.metadata_never_index` 禁止 Spotlight 狂轉發燙。

---

## 🏗️ 雙軌制打包與編譯方式

### 1. 編譯官網 DMG 專業版 (`Direct Edition`)
```bash
./scripts/build_app.sh direct
```

### 2. 編譯 Mac App Store 沙盒版 (`MAS Edition`)
```bash
./scripts/build_app.sh mas
```

編譯完成後，應用程式位於：
- `build/PureMount.app`

可直接執行啟動：
```bash
open build/PureMount.app
```
