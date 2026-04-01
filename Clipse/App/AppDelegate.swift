import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardStore: ClipboardStore?
    private var clipboardMonitor: ClipboardMonitor?
    private var panelController: PanelController?
    private var hotkeyManager: HotkeyManager?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardStore()
        clipboardStore = store

        let panel = PanelController(store: store)
        panelController = panel

        let hotkey = HotkeyManager { [weak panel] in panel?.toggle() }
        hotkeyManager = hotkey

        let monitor = ClipboardMonitor(store: store, settings: .shared)
        clipboardMonitor = monitor

        menuBarController = MenuBarController(store: store, panelController: panel)

        monitor.start()
        hotkey.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        hotkeyManager?.unregister()
    }
}
