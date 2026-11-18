import SwiftUI
import AppKit

/// 應用程式生命週期代理（支援常駐右上角選單列與自動隱藏 Dock 圖示）
public final class PureMountAppDelegate: NSObject, NSApplicationDelegate {
    private var windowCloseObserver: NSObjectProtocol?

    @MainActor
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let closedWindow = notification.object as? NSWindow else { return }
            Task { @MainActor in
                PureMountAppDelegate.handleWindowWillClose(closedWindow)
            }
        }
    }

    @MainActor
    private static func handleWindowWillClose(_ closedWindow: NSWindow) {
        guard AppSettings.shared.hideDockWhenClosed else { return }
        // 僅在一般主視窗關閉且無其他可見主視窗時隱藏 Dock 圖示，MenuBarExtra 不受影響
        let hasOtherVisibleMainWindow = NSApp.windows.contains { window in
            window !== closedWindow
                && window.isVisible
                && window.canBecomeMain
                && !window.className.contains("MenuBarExtra")
        }
        if !hasOtherVisibleMainWindow && closedWindow.canBecomeMain {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @MainActor
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        return true
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
