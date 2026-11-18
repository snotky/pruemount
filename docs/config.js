// PureMount 官網統一發佈設定檔（上線前只需修改此檔案中的網址即可全站套用）
window.PUREMOUNT_CONFIG = {
  // 1. GitHub Releases 的最新 .dmg 下載連結
  dmgDownloadUrl: "https://github.com/snotky/pruemount/releases/latest/download/PureMount-1.0.0.dmg",

  // 2. Mac App Store 連結（送審上架後填入 https://apps.apple.com/app/id...）
  macAppStoreUrl: "#pricing",

  // 3. Stripe 官網直購結帳連結（1 台 Mac vs 3 台 Mac）
  checkout: {
    "1mac": {
      lifetime: "#pricing", // US$ 9.99 一次付清
      annual: "#pricing"    // US$ 2.99 / 年
    },
    "3macs": {
      lifetime: "#pricing", // US$ 14.99 一次付清
      annual: "#pricing"    // US$ 4.99 / 年
    }
  }
};
