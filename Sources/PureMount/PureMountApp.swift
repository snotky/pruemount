import SwiftUI
import AppKit

/// 應用程式生命週期代理（確保啟動時正常顯示視窗與狀態列圖示）
public final class PureMountAppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 關閉主視窗後仍保留右上角 Menu Bar 常駐小工具運作
        return false
    }
}

@main
public struct PureMountApp: App {
    @NSApplicationDelegateAdaptor(PureMountAppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var monitor = DiskMonitorService()

    public init() {}

    public var body: some Scene {
        // 1. 主控台視窗
        WindowGroup("PureMount — \(settings.l10n.appSubtitle)", id: "main-console") {
            MainWindowView(monitor: monitor, settings: settings)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // 2. 右上角狀態列常駐視窗 (macOS 13.0+ 原生 MenuBarExtra)
        MenuBarExtra {
            MenuBarPopupView(monitor: monitor, settings: settings)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "externaldrive.fill.badge.checkmark")
                let extCount = monitor.externalVolumes.filter { $0.isMounted }.count
                if extCount > 0 {
                    Text("\(extCount)")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
