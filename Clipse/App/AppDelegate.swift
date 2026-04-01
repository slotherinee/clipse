import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardStore: ClipboardStore?
    private var clipboardMonitor: ClipboardMonitor?
    private var panelController: PanelController?
    private var hotkeyManager: HotkeyManager?
    private var menuBarController: MenuBarController?
    private let retentionTracker = RetentionTracker()

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
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        LicenseManager.shared.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        hotkeyManager?.unregister()
    }
}
