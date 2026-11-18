// PureMount Official Website — Bilingual & Seat Switcher Controller
(function () {
  const i18n = {
    "zh-Hant": {
      navFeatures: "核心優勢",
      navCompare: "競品比較",
      navPricing: "方案價格",
      navFaq: "常見問題",
      navLang: "中 / EN",
      navDownload: "免費下載",
      eyebrow: "v1.0.0 · 支援 macOS 13 – 27 · Apple Silicon 與 Intel 原生架構",
      heroTitle: "讓每一顆 Windows 硬碟，在 Mac 上如原生般自由讀寫。",
      heroLead:
        "告別繁瑣設定與雜亂介面。PureMount 結合「NTFS 無感讀寫」、「Windows 鎖定一鍵救援」、「退出自動清除 ._ 隱藏垃圾檔」與「筆電休眠自動保護」，重新定義 Mac 外接硬碟體驗。",
      ctaDownload: "免費下載 macOS 版 (.dmg)",
      ctaBuyPro: "立即購買終身買斷版 US$ 9.99",
      heroTrust: "免註冊免費贈送 1 次完整讀寫與淨化體驗 · 確認您的硬碟 100% 相容再購買",
      after1: "插上 NTFS 硬碟自動轉為「可讀寫模式」，直接在 macOS Finder 新增、改名與管理檔案。",
      after2: "點擊「純淨安全退出」，背景 0.5 秒自動清空所有 Mac 隱藏垃圾檔並釋放垃圾桶空間。",
      after3: "自動偵測 Windows 快速啟動鎖定，免回 Windows 跑 chkdsk，在 Mac 一鍵修復日誌。",
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
      pricingSub: "官網直購享專屬優惠價（比 Mac App Store 更划算），先免費試用滿意再購買。",
      seat1Mac: "1 台 Mac（個人版）",
      seat3Macs: "3 台 Mac（多機 / 工作室推薦）",
      lifetimeBadge: "官網直購優惠 · 省下 App Store 抽成",
      lifetimeTitle: "終身買斷版 (Lifetime Pro)",
      lifetimeF1: "無限次 NTFS 高速讀寫掛載與髒磁區修復",
      lifetimeF2: "無限次退出自動清除 Mac 隱藏垃圾檔",
      lifetimeF3: "完整包含休眠自動保護、佔用釋放與防呆格式化",
      lifetimeF5: "永久免費享有未來所有版本升級",
      annualBadge: "輕量入門方案",
      annualTitle: "年度授權版 (Annual Pro)",
      annualF1: "完整包含所有 Pro 專業版讀寫與純淨功能",
      annualF3: "訂閱期間享有所有版本更新與技術支援",
      masNotePrefix: "習慣透過 Apple 帳號付款？",
      masNoteLink: "前往 Mac App Store 下載（US$ 3.99/年 · US$ 12.99 買斷）›",
      faqTitle: "購買前常見問題",
      faq1Q: "我的硬碟一定能用嗎？可以先試用再買嗎？",
      faq1A: "完全可以！點擊上方免費下載安裝後，免註冊即可享有「1 次有始有終的完整體驗」（從啟用 NTFS 讀寫到純淨安全退出），親眼確認您的硬碟 100% 順暢讀寫再決定是否升級。",
      faq2Q: "支援最新的 Apple Silicon (M 系列) 與 Intel Mac 嗎？",
      faq2A: "支援！PureMount 採用原生雙架構編譯，完整相容 macOS 13 Ventura 至最新 macOS 27 的所有 Apple Silicon 與 Intel Mac 機型。",
      faq3Q: "以後換新 Mac 電腦或重灌系統，需要重新購買嗎？",
      faq3A: "不需要！您的授權綁定於您的購買信箱（官網版可依方案綁定 1 台或 3 台 Mac；App Store 版直接跟隨您的 Apple ID），換新電腦只需輸入信箱與授權碼即可 1 秒恢復 Pro 權限。",
      trustBadge1: "符合 Apple 安全標準",
      trustBadge2: "支援 macOS 13 – 27",
      trustBadge3: "Apple Silicon & Intel 執行",
      trustBadge4: "確保硬碟資料安全",
      menuBarTitle: "使用「PureMount 選單列」立即管理所有 NTFS 硬碟",
      menuBarDesc: "無需打開主視窗！點擊 macOS 右上角選單列圖示，即可即時查看所有外接硬碟容量、切換可讀寫模式、在 Finder 中開啟，或一鍵「純淨安全退出」。",
      menuBarB1: "插入硬碟自動於狀態列顯示數量與讀寫綠燈",
      menuBarB2: "支援一鍵「全退」，同時淨化並卸載所有外接儲存裝置",
      gTaxTitle: "價格透明",
      gTaxDesc: "清楚標示實付金額，無任何隱藏訂閱陷阱",
      gRefundTitle: "30 天退款保證",
      gRefundDesc: "先享 1 次免費完整體驗，購買後 30 天內皆可安心退款",
      gSupportTitle: "24/7 支援",
      gSupportDesc: "提供 Turbo Integration LLC 專屬電子郵件技術支援",
      gPayTitle: "安全支付"
    },
    en: {
      navFeatures: "Features",
      navCompare: "Compare",
      navPricing: "Pricing",
      navFaq: "FAQ",
      navLang: "EN / 中",
      navDownload: "Free Download",
      eyebrow: "v1.0.0 · macOS 13 – 27 Ready · Native Apple Silicon & Intel Universal",
      heroTitle: "Make Every Windows Drive Feel Native on Your Mac.",
      heroLead:
        "No kernel security downgrades. No bloated background daemons. PureMount unites seamless NTFS Read/Write, 1-click Windows lock repair, automatic ghost-file cleanup on eject, and MacBook Sleep Guard in one minimalist app.",
      ctaDownload: "Free Download for macOS (.dmg)",
      ctaBuyPro: "Buy Lifetime Pro — US$ 9.99",
      heroTrust: "Includes 1 full mount-to-eject session free without sign-up · Verify your drive before buying",
      after1: "NTFS drives mount in full Read/Write mode automatically—drag, drop, edit, and delete directly in Finder.",
      after2: "'Clean & Eject' silently wipes all ._* AppleDouble files, .DS_Store, and .Trashes in 0.5s right before unmounting.",
      after3: "Detects Windows Fast Startup locks automatically and repairs the NTFS journal in one click without needing a PC.",
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
      pricingSub: "Direct website pricing saves up to 23% vs. the Mac App Store. Try it free with your own drive first.",
      seat1Mac: "1 Mac (Personal)",
      seat3Macs: "3 Macs (Multi-Mac / Studio)",
      lifetimeBadge: "Direct Website Deal · Best Value",
      lifetimeTitle: "Lifetime Pro (One-Time)",
      lifetimeF1: "Unlimited NTFS Read/Write mounting & Dirty Bit repair",
      lifetimeF2: "Unlimited automatic ghost-file cleanup on eject",
      lifetimeF3: "Includes Sleep Guard, Unblocker & Safe Format Wizard",
      lifetimeF5: "Includes all future macOS updates for life",
      annualBadge: "Flexible Annual Plan",
      annualTitle: "Annual Pro",
      annualF1: "Full access to all Pro NTFS & drive purity features",
      annualF3: "Includes all updates during your subscription",
      masNotePrefix: "Prefer paying with your Apple ID?",
      masNoteLink: "Download on Mac App Store (US$ 3.99/yr · US$ 12.99 Lifetime) ›",
      faqTitle: "Frequently Asked Questions",
      faq1Q: "Can I test PureMount with my own drive before paying?",
      faq1A: "Yes! Download the app for free and enjoy 1 complete mount-to-eject session with full Pro features unlocked—no account or credit card required.",
      faq2Q: "Does it support Apple Silicon (M-series) and Intel Macs?",
      faq2A: "Yes. PureMount is compiled as a Universal macOS binary supporting macOS 13 Ventura through macOS 27 on both Apple Silicon and Intel Macs.",
      faq3Q: "What happens if I get a new Mac or reinstall macOS?",
      faq3A: "Your license is tied to your purchase email (1 or 3 Macs on Direct edition, or tied to your Apple ID on the Mac App Store). You can transfer or restore it anytime.",
      trustBadge1: "Apple Security Ready",
      trustBadge2: "Supports macOS 13 – 27",
      trustBadge3: "Apple Silicon & Intel",
      trustBadge4: "Data Safety Guaranteed",
      menuBarTitle: "Manage NTFS Drives Instantly via PureMount Menu Bar",
      menuBarDesc: "No need to open the main console! Click the Menu Bar icon at the top-right of your Mac to check drive space, toggle Read/Write, open in Finder, or Clean & Eject in one click.",
      menuBarB1: "Automatically shows mounted drive count and status indicator",
      menuBarB2: "One-click 'Eject All' to clean and unmount every external drive",
      gTaxTitle: "Transparent Pricing",
      gTaxDesc: "No hidden fees or surprise renewal traps",
      gRefundTitle: "30-Day Money-Back",
      gRefundDesc: "Includes 1 free full session plus a 30-day refund guarantee",
      gSupportTitle: "24/7 Support",
      gSupportDesc: "Dedicated email support by Turbo Integration LLC",
      gPayTitle: "Secure Checkout"
    }
  };

  const pricingMatrix = {
    "1mac": {
      lifetimePrice: "US$ 9.99",
      annualPrice: "US$ 2.99",
      "zh-Hant": {
        lifetimeDesc: "一次付費永久擁有（1 台 Mac 授權），無任何續訂費用",
        lifetimeSeat: "購買信箱自動綁定 1 台 Mac（換機可線上解綁轉移）",
        lifetimeBtn: "立即購買終身買斷版 — US$ 9.99",
        annualDesc: "約 NT$ 90 / 年（平均每月不到 NT$ 8），隨時可取消",
        annualSeat: "支援綁定 1 台 Mac 電腦",
        annualBtn: "訂閱年度方案 — US$ 2.99 / 年"
      },
      en: {
        lifetimeDesc: "Pay once, own forever (1 Mac license) with zero recurring fees",
        lifetimeSeat: "Bound to 1 Mac via purchase email (transferable anytime)",
        lifetimeBtn: "Buy Lifetime Pro — US$ 9.99",
        annualDesc: "Less than $0.25 / month, cancel anytime",
        annualSeat: "Activate on 1 Mac",
        annualBtn: "Subscribe Annual Pro — US$ 2.99 / yr"
      }
    },
    "3macs": {
      lifetimePrice: "US$ 14.99",
      annualPrice: "US$ 4.99",
      "zh-Hant": {
        lifetimeDesc: "一次付費永久擁有（最多 3 台 Mac 授權，平均每台不到 US$ 5）",
        lifetimeSeat: "同一個購買信箱可同時啟用最多 3 台 Mac 電腦",
        lifetimeBtn: "立即購買 3 台終身版 — US$ 14.99",
        annualDesc: "約 NT$ 155 / 年（3 台共用，平均每台每月 NT$ 4），隨時可取消",
        annualSeat: "支援同時綁定最多 3 台 Mac 電腦",
        annualBtn: "訂閱 3 台年度方案 — US$ 4.99 / 年"
      },
      en: {
        lifetimeDesc: "Pay once, own forever (up to 3 Macs — under $5 per Mac)",
        lifetimeSeat: "Activate on up to 3 Macs with your purchase email",
        lifetimeBtn: "Buy 3-Mac Lifetime Pro — US$ 14.99",
        annualDesc: "Multi-Mac annual plan for 3 computers, cancel anytime",
        annualSeat: "Activate on up to 3 Macs",
        annualBtn: "Subscribe 3-Mac Annual — US$ 4.99 / yr"
      }
    }
  };

  let lang = "zh-Hant";
  let currentSeat = "1mac";

  function applyLang() {
    const dict = i18n[lang];
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (dict[key]) {
        el.textContent = dict[key];
      }
    });
    applyPricingSeat();
  }

  function applyPricingSeat() {
    const data = pricingMatrix[currentSeat];
    const copy = data[lang];
    const cfg = window.PUREMOUNT_CONFIG || {};
    const checkoutSet = (cfg.checkout && cfg.checkout[currentSeat]) || {};

    const ltPrice = document.getElementById("price-lifetime");
    const anPrice = document.getElementById("price-annual");
    const ltDesc = document.getElementById("desc-lifetime");
    const anDesc = document.getElementById("desc-annual");
    const ltSeat = document.getElementById("seat-feature-lifetime");
    const anSeat = document.getElementById("seat-feature-annual");
    const ltBtn = document.getElementById("btn-checkout-lifetime");
    const anBtn = document.getElementById("btn-checkout-annual");

    if (ltPrice) ltPrice.textContent = data.lifetimePrice;
    if (anPrice) {
      anPrice.innerHTML = data.annualPrice + ' <small style="font-size: 1rem; font-weight: 600;">/ yr</small>';
    }
    if (ltDesc) ltDesc.textContent = copy.lifetimeDesc;
    if (anDesc) anDesc.textContent = copy.annualDesc;
    if (ltSeat) ltSeat.textContent = copy.lifetimeSeat;
    if (anSeat) anSeat.textContent = copy.annualSeat;
    if (ltBtn) {
      ltBtn.textContent = copy.lifetimeBtn;
      if (checkoutSet.lifetime && checkoutSet.lifetime !== "#pricing") {
        ltBtn.setAttribute("href", checkoutSet.lifetime);
        ltBtn.setAttribute("target", "_blank");
        ltBtn.setAttribute("rel", "noopener noreferrer");
      } else {
        ltBtn.setAttribute("href", "#pricing");
      }
    }
    if (anBtn) {
      anBtn.textContent = copy.annualBtn;
      if (checkoutSet.annual && checkoutSet.annual !== "#pricing") {
        anBtn.setAttribute("href", checkoutSet.annual);
        anBtn.setAttribute("target", "_blank");
        anBtn.setAttribute("rel", "noopener noreferrer");
      } else {
        anBtn.setAttribute("href", "#pricing");
      }
    }
  }

  function applyConfigLinks() {
    const cfg = window.PUREMOUNT_CONFIG || {};
    if (cfg.dmgDownloadUrl) {
      document.querySelectorAll('[data-link="dmg"]').forEach((el) => {
        el.setAttribute("href", cfg.dmgDownloadUrl);
      });
    }
    if (cfg.macAppStoreUrl && cfg.macAppStoreUrl !== "#pricing") {
      document.querySelectorAll('[data-link="mas"]').forEach((el) => {
        el.setAttribute("href", cfg.macAppStoreUrl);
        el.setAttribute("target", "_blank");
        el.setAttribute("rel", "noopener noreferrer");
      });
    }
    const heroBuyBtn = document.querySelector('[data-link="checkout-lifetime"]');
    const checkout1Mac = cfg.checkout && cfg.checkout["1mac"] && cfg.checkout["1mac"].lifetime;
    if (heroBuyBtn && checkout1Mac && checkout1Mac !== "#pricing") {
      heroBuyBtn.setAttribute("href", checkout1Mac);
      heroBuyBtn.setAttribute("target", "_blank");
      heroBuyBtn.setAttribute("rel", "noopener noreferrer");
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    const langBtn = document.getElementById("lang-switch");
    if (langBtn) {
      langBtn.addEventListener("click", () => {
        lang = lang === "zh-Hant" ? "en" : "zh-Hant";
        applyLang();
      });
    }

    document.querySelectorAll(".seat-toggle-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document.querySelectorAll(".seat-toggle-btn").forEach((b) => b.classList.remove("active"));
        btn.classList.add("active");
        currentSeat = btn.getAttribute("data-seat") || "1mac";
        applyPricingSeat();
      });
    });

    applyConfigLinks();
    applyLang();
  });
})();
