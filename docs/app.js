// PureMount Official Website — Bilingual High-Conversion Controller
(function () {
  const i18n = {
    "zh-Hant": {
      navFeatures: "核心優勢",
      navCompare: "競品比較",
      navPricing: "方案價格",
      navFaq: "常見問題",
      navLang: "中 / EN",
      navDownload: "免費下載",
      eyebrow: "專為 macOS 13 / 14 / 15+ 打造 · Apple Silicon 與 Intel 原生架構",
      heroTitle: "讓每一顆 Windows 硬碟，在 Mac 上如原生般自由讀寫。",
      heroLead:
        "告別繁瑣設定與雜亂介面。PureMount 結合「NTFS 無感讀寫」、「Windows 鎖定一鍵救援」、「退出自動清除 ._ 隱藏垃圾檔」與「筆電休眠自動保護」，重新定義 Mac 外接硬碟體驗。",
      ctaDownload: "免費下載 macOS 版 (.dmg)",
      ctaBuyPro: "立即購買終身買斷版 US$ 9.99",
      heroTrust: "免註冊免費贈送 1 次完整讀寫與淨化體驗 · 確認您的硬碟 100% 相容再購買",
      painSectionTitle: "為什麼一般 Mac 用戶插上外接硬碟總是崩潰？",
      painSectionSub: "我們把跨平台傳檔案最惱人的四大痛點，變成全自動的無感守護。",
      beforeTitle: "過去沒有 PureMount 時的困擾",
      before1: "插上 Windows 的 NTFS 硬碟，Mac 只能唯讀觀看，無法拉入或刪除任何檔案。",
      before2: "隨身碟拔去插 Windows、電視或車載音響，裡面多出滿滿的 ._檔案 與 .DS_Store 亂碼垃圾。",
      before3: "硬碟在 Windows 沒按安全退出，插上 Mac 直接被 Dirty Bit 鎖死連掛載都失敗。",
      before4: "MacBook 闔上螢幕放進包包，醒來跳出刺眼的「磁碟未正常退出」警告甚至傷硬碟。",
      afterTitle: "使用 PureMount 後的純淨體驗",
      after1: "插上 NTFS 硬碟自動轉為「可讀寫模式」，直接在 macOS Finder 新增、改名與管理檔案。",
      after2: "點擊「純淨安全退出」，背景 0.5 秒自動清空所有 Mac 隱藏垃圾檔並釋放垃圾桶空間。",
      after3: "自動偵測 Windows 快速啟動鎖定，免回 Windows 跑 chkdsk，在 Mac 一鍵修復日誌。",
      after4: "內建「休眠自動保護」與「佔用程序強制釋放」，闔蓋自動安全卸載、喚醒自動重掛載。",
      bentoTitle: "六大專業能力，收斂於極簡純白介面",
      bentoSub: "平時不堆砌複雜按鈕，只有當硬碟需要處理時，才自動浮現對應的智慧解決方案。",
      b1Title: "NTFS 原生級讀寫掛載",
      b1Desc: "插上即用，無須進恢復模式降低系統安全性，與 macOS Finder 完美整合。",
      b2Title: "Clean & Eject 幽靈檔淨化",
      b2Desc: "退出前自動抹除 ._*、.DS_Store、.Spotlight-V100 與 .Trashes，保持跨平台硬碟絕對乾淨。",
      b3Title: "Windows 鎖定 (Dirty Bit) 修復",
      b3Desc: "針對未正常退出的 NTFS 硬碟提供一鍵日誌重置，當場解除唯讀鎖死狀態。",
      b4Title: "佔用程序偵測與強制釋放",
      b4Desc: "退出被卡住時，直接列出正在咬住硬碟的 App 名稱，一鍵關閉佔用程式並安全退出。",
      b5Title: "筆電休眠保護 & Spotlight 防發燙",
      b5Desc: "等同直接省下一套 US$ 15 的 Jettison 休眠卸載軟體，還能禁止 Spotlight 索引防止 Mac 發燙。",
      b6Title: "雙平台白話防呆格式化與 3 秒測速",
      b6Desc: "內建 3 秒讀寫測速驗證線材速度；格式化採用「白話用途二選一」與三道防呆鎖，絕不誤刪系統碟。",
      compareTitle: "價格只有大廠的 1/3，功能卻更全面",
      compareSub: "買一套 PureMount，同時擁有 NTFS 讀寫驅動 + CleanMyDrive 垃圾清理 + Jettison 休眠保護。",
      tableCaption: "主流 macOS 外接硬碟與 NTFS 工具規格比較表",
      colFeature: "功能與比較項目",
      rowPrice: "終身買斷價格",
      rowNtfs: "NTFS 完整讀寫與 Dirty Bit 修復",
      rowClean: "退出自動清除 ._ / .DS_Store 垃圾檔",
      rowSleep: "筆電闔蓋休眠自動卸載保護",
      rowUnblock: "佔用硬碟程序偵測與一鍵釋放",
      rowSpeed: "3 秒硬碟讀寫測速 & 防呆格式化",
      pricingTitle: "簡單透明的定價，一次投資永久省心",
      pricingSub: "您可以先免費下載測試您的硬碟，滿意後再選擇最適合您的授權方案。",
      lifetimeBadge: "最受歡迎 · 省下 70% 費用",
      lifetimeTitle: "終身買斷版 (Lifetime Pro)",
      lifetimeDesc: "一次付費永久擁有，無任何續訂費用",
      lifetimeF1: "無限次 NTFS 高速讀寫掛載與髒磁區修復",
      lifetimeF2: "無限次退出自動清除 Mac 隱藏垃圾檔",
      lifetimeF3: "完整包含休眠自動保護、佔用釋放與防呆格式化",
      lifetimeF4: "同一個購買信箱可同時綁定最多 3 台 Mac 電腦",
      lifetimeF5: "永久免費享有未來所有版本升級",
      lifetimeBtn: "立即購買終身買斷版 — US$ 9.99",
      annualBadge: "輕量入門方案",
      annualTitle: "年度授權版 (Annual Pro)",
      annualDesc: "約 NT$ 90 / 年（平均每月不到 NT$ 8），隨時可取消",
      annualF1: "完整包含所有 Pro 專業版讀寫與純淨功能",
      annualF2: "支援綁定最多 3 台 Mac 電腦",
      annualF3: "訂閱期間享有所有版本更新與技術支援",
      annualBtn: "訂閱年度方案 — US$ 2.99 / 年",
      faqTitle: "購買前常見問題",
      faq1Q: "我的硬碟一定能用嗎？可以先試用再買嗎？",
      faq1A: "完全可以！點擊上方免費下載安裝後，免註冊即可享有「1 次有始有終的完整體驗」（從啟用 NTFS 讀寫到純淨安全退出），親眼確認您的硬碟 100% 順暢讀寫再決定是否升級。",
      faq2Q: "支援最新的 Apple Silicon (M1 / M2 / M3 / M4) 與舊款 Intel Mac 嗎？",
      faq2A: "支援！PureMount 採用 Universal 原生雙架構編譯，支援 macOS 13 Ventura、macOS 14 Sonoma 與最新 macOS 15 Sequoia 以上的所有 Mac 機型。",
      faq3Q: "以後換新 Mac 電腦或重灌系統，需要重新購買嗎？",
      faq3A: "不需要！您的授權綁定於您的購買信箱（官網版最多可綁 3 台 Mac；App Store 版直接跟隨您的 Apple ID），換新電腦只需輸入信箱與授權碼即可 1 秒恢復 Pro 權限。"
    },
    en: {
      navFeatures: "Features",
      navCompare: "Compare",
      navPricing: "Pricing",
      navFaq: "FAQ",
      navLang: "EN / 中",
      navDownload: "Free Download",
      eyebrow: "Built for macOS 13 / 14 / 15+ · Native Apple Silicon & Intel Universal",
      heroTitle: "Make Every Windows Drive Feel Native on Your Mac.",
      heroLead:
        "No kernel security downgrades. No bloated background daemons. PureMount unites seamless NTFS Read/Write, 1-click Windows lock repair, automatic ghost-file cleanup on eject, and MacBook Sleep Guard in one minimalist app.",
      ctaDownload: "Free Download for macOS (.dmg)",
      ctaBuyPro: "Buy Lifetime Pro — US$ 9.99",
      heroTrust: "Includes 1 full mount-to-eject session free without sign-up · Verify your drive before buying",
      painSectionTitle: "Why External Drives Frustrate Mac Users—And How PureMount Fixes It",
      painSectionSub: "We turned the 4 biggest cross-platform storage headaches into effortless automation.",
      beforeTitle: "Before PureMount",
      before1: "Windows NTFS drives mount as Read-Only on macOS—you can view files, but can't copy, rename, or delete anything.",
      before2: "Every USB drive used on a Mac gets cluttered with hundreds of hidden ._ files and .DS_Store junk on Windows and Smart TVs.",
      before3: "Drives unplugged from Windows with Fast Startup enabled get locked by a Dirty Bit and refuse to mount.",
      before4: "Closing your MacBook lid with a drive plugged in triggers scary 'Disk Not Properly Ejected' warnings.",
      afterTitle: "With PureMount",
      after1: "NTFS drives mount in full Read/Write mode automatically—drag, drop, edit, and delete directly in Finder.",
      after2: "'Clean & Eject' silently wipes all ._* AppleDouble files, .DS_Store, and .Trashes in 0.5s right before unmounting.",
      after3: "Detects Windows Fast Startup locks automatically and repairs the NTFS journal in one click without needing a PC.",
      after4: "Built-in Sleep Guard safely unmounts drives before sleep and remounts on wake, plus 1-click process unblocking.",
      bentoTitle: "6 Pro Capabilities in a Pure Minimalist Interface",
      bentoSub: "Zero button clutter. Smart contextual banners appear only when your drive needs attention.",
      b1Title: "Seamless NTFS Read & Write",
      b1Desc: "Plug and play directly in macOS Finder without booting into Recovery Mode or disabling SIP.",
      b2Title: "Clean & Eject Ghost File Eraser",
      b2Desc: "Automatically strips ._* files, .DS_Store, .Spotlight-V100, and .Trashes so Windows PCs and TVs stay spotless.",
      b3Title: "One-Click Windows Lock Repair",
      b3Desc: "Clears NTFS Dirty Bit flags caused by Windows Fast Startup or improper removal in seconds.",
      b4Title: "Open File Unblocker",
      b4Desc: "Instantly identifies which background app is holding your drive hostage and closes it safely to eject.",
      b5Title: "Sleep Guard & Spotlight Control",
      b5Desc: "Replaces a standalone $15 sleep-eject utility and stops Spotlight mds from overheating your Mac.",
      b6Title: "Safe Format Wizard & 3s Speed Test",
      b6Desc: "Benchmark real USB transfer speeds in 3 seconds, and format drives safely with plain-language choices and triple erase locks.",
      compareTitle: "1/3 the Price of Legacy Drivers. Twice as Useful.",
      compareSub: "One lightweight app replaces an NTFS driver + a ghost-file cleaner + a sleep auto-ejector.",
      tableCaption: "Comparison of macOS NTFS & External Drive Utilities",
      colFeature: "Capability",
      rowPrice: "Lifetime License Price",
      rowNtfs: "Full NTFS Read/Write & Dirty Bit Repair",
      rowClean: "Auto-Clean ._ & .DS_Store on Eject",
      rowSleep: "MacBook Sleep Auto-Unmount Guard",
      rowUnblock: "Blocking Process Detector & Force Eject",
      rowSpeed: "3s Speed Benchmark & Safe Format Wizard",
      pricingTitle: "Simple, Transparent Pricing",
      pricingSub: "Download and test with your own drive first. Upgrade to Pro for unlimited peace of mind.",
      lifetimeBadge: "Most Popular · Save 70%",
      lifetimeTitle: "Lifetime Pro (One-Time)",
      lifetimeDesc: "Pay once, own forever with zero recurring subscription fees",
      lifetimeF1: "Unlimited NTFS Read/Write mounting & Dirty Bit repair",
      lifetimeF2: "Unlimited automatic ghost-file cleanup on eject",
      lifetimeF3: "Includes Sleep Guard, Unblocker & Safe Format Wizard",
      lifetimeF4: "Activate on up to 3 Macs with your purchase email",
      lifetimeF5: "Includes all future macOS updates for life",
      lifetimeBtn: "Buy Lifetime Pro — US$ 9.99",
      annualBadge: "Flexible Annual Plan",
      annualTitle: "Annual Pro",
      annualDesc: "Less than $0.25 / month, cancel anytime",
      annualF1: "Full access to all Pro NTFS & drive purity features",
      annualF2: "Activate on up to 3 Macs",
      annualF3: "Includes all updates during your subscription",
      annualBtn: "Subscribe Annual Pro — US$ 2.99 / yr",
      faqTitle: "Frequently Asked Questions",
      faq1Q: "Can I test PureMount with my own drive before paying?",
      faq1A: "Yes! Download the app for free and enjoy 1 complete mount-to-eject session with full Pro features unlocked—no account or credit card required.",
      faq2Q: "Does it support Apple Silicon (M1/M2/M3/M4) and Intel Macs?",
      faq2A: "Yes. PureMount is compiled as a Universal macOS binary supporting macOS 13 Ventura, macOS 14 Sonoma, and macOS 15 Sequoia+.",
      faq3Q: "What happens if I get a new Mac or reinstall macOS?",
      faq3A: "Your license is tied to your purchase email (up to 3 Macs on Direct edition, or tied to your Apple ID on the Mac App Store). You can transfer or restore it anytime in 1 click."
    }
  };

  let lang = "zh-Hant";

  function applyLang() {
    const dict = i18n[lang];
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (dict[key]) {
        el.textContent = dict[key];
      }
    });
  }

  function applyConfigLinks() {
    const cfg = window.PUREMOUNT_CONFIG || {};
    if (cfg.dmgDownloadUrl) {
      document.querySelectorAll('[data-link="dmg"]').forEach((el) => {
        el.setAttribute("href", cfg.dmgDownloadUrl);
      });
    }
    if (cfg.lifetimeCheckoutUrl && cfg.lifetimeCheckoutUrl !== "#pricing") {
      document.querySelectorAll('[data-link="checkout-lifetime"]').forEach((el) => {
        el.setAttribute("href", cfg.lifetimeCheckoutUrl);
        el.setAttribute("target", "_blank");
        el.setAttribute("rel", "noopener noreferrer");
      });
    }
    if (cfg.annualCheckoutUrl && cfg.annualCheckoutUrl !== "#pricing") {
      document.querySelectorAll('[data-link="checkout-annual"]').forEach((el) => {
        el.setAttribute("href", cfg.annualCheckoutUrl);
        el.setAttribute("target", "_blank");
        el.setAttribute("rel", "noopener noreferrer");
      });
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    const btn = document.getElementById("lang-switch");
    if (btn) {
      btn.addEventListener("click", () => {
        lang = lang === "zh-Hant" ? "en" : "zh-Hant";
        applyLang();
      });
    }
    applyLang();
    applyConfigLinks();
  });
})();
