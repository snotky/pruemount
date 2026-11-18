# CLAUDE.md

本文件為 Claude Code 及其他 AI 協作工具在 `/Users/lucky/Documents/claude/A026-Mac NTFS` 工作區的開發與協作規範。完整的專案背景、架構、定價與品牌規劃請先閱讀 [PROJECT_HANDOFF.md](./PROJECT_HANDOFF.md)。

## 語言與視覺規範
- **語言**：所有回覆、程式碼註解、文件與 Commit 訊息說明均使用**繁體中文**，嚴禁使用簡體中文。
- **嚴禁 Emoji**：`Sources/PureMount/` 與 `docs/` 內的 App UI 與網頁介面禁止使用任何 Emoji，請統一使用 SF Symbols 或內嵌 SVG 圖示。
- **設計美學**：遵循 Keka 風格（大膽極簡、淺色調、單頁直覺）與 Dr.Buho 商業結構的純 CSS/HTML 視覺呈現，勿任意加入低質感的外部生成圖片。

## 雙軌發行規範（Direct vs. MAS）
- **Direct（官網直銷版）**：編譯旗標 `DISTRIBUTION_DIRECT`，支援官網試用與授權序號驗證。
- **MAS（Mac App Store 版）**：編譯旗標 `DISTRIBUTION_MAS`，嚴禁在 MAS 程式碼路徑中出現外部購買連結、「官網更便宜」等導購文案或繞過 IAP 的機制，以免違反 App Store 審核規範。
- 參考價格策略：
  - 官網直銷版：1 台 Mac `$2.99/年`、終身 `$9.99`；3 台 Mac `$4.99/年`、終身 `$14.99`。
  - Mac App Store 版：`$3.99/年`、終身 `$12.99`。

## 建置與打包指令
本機環境使用 Command Line Tools（無完整 Xcode），請直接透過腳本使用 `swiftc` 編譯（腳本內已設定 `-module-cache-path /tmp/puremount-module-cache`）：
- 建置官網直銷版 App：`./scripts/build_app.sh direct`
- 建置 Mac App Store 版 App：`./scripts/build_app.sh mas`
- 打包 DMG：`./scripts/build_dmg.sh`
- 公證 DMG：`./scripts/notarize_dmg.sh`

## Git 協作與同步規範
- 遠端儲存庫：`https://github.com/snotky/pruemount.git`（主分支 `main`，GitHub Pages 對應 `docs/` 目錄）。
- 開始任務前先確認 `git status` 與遠端同步狀態（`git pull --rebase origin main`）。
- 完成變更並驗證後，請以清楚的繁體中文或標準 Conventional Commits 格式提交並推送至 `origin main`，確保 Antigravity、Claude 與 ChatGPT 之間狀態一致。
