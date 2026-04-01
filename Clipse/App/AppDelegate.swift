import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardStore: ClipboardStore?
    private var clipboardMonitor: ClipboardMonitor?
    private var panelController: PanelController?
    private var hotkeyManager: HotkeyManager?
    private var menuBarController: MenuBarController?
    private var onboardingWindow: NSWindow?
    private let retentionTracker = RetentionTracker()

    private enum Defaults {
        static let onboardingDone = "onboardingCompleted"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardStore()
        store.isPro = { LicenseManager.shared.isPro }
        clipboardStore = store

        let panel = PanelController(store: store)
        panelController = panel

        let hotkey = HotkeyManager { [weak panel] in panel?.toggle() }
        hotkeyManager = hotkey

        let monitor = ClipboardMonitor(store: store, settings: .shared)
        clipboardMonitor = monitor

        menuBarController = MenuBarController(store: store, panelController: panel)
        panel.onPaste = { [weak self] in self?.retentionTracker.recordPaste() }

        monitor.start()
        hotkey.register()
        retentionTracker.start()

        if !UserDefaults.standard.bool(forKey: Defaults.onboardingDone) {
            showOnboarding()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        LicenseManager.shared.refresh()
        // Re-register hotkey if it failed earlier (accessibility not yet granted at launch)
        hotkeyManager?.registerIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        hotkeyManager?.unregister()
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        let view = OnboardingView(
            onAccessibilityGranted: { [weak self] in
                // Immediately try to register hotkey after permission granted
                self?.hotkeyManager?.registerIfNeeded()
            },
            onComplete: { [weak self] in
                UserDefaults.standard.set(true, forKey: Defaults.onboardingDone)
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 344),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Clipse"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
