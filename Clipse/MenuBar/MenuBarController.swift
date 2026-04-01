import AppKit
import SwiftUI

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store: ClipboardStore
    private let panelController: PanelController
    private weak var hotkeyManager: HotkeyManager?
    // Settings window created once, reused — avoids re-allocating NSHostingView
    private var settingsWindow: NSWindow?
    // Captured in menuWillOpen — before menu activates our app
    private var previousApp: NSRunningApplication?

    init(store: ClipboardStore, panelController: PanelController, hotkeyManager: HotkeyManager? = nil) {
        self.store = store
        self.panelController = panelController
        self.hotkeyManager = hotkeyManager
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = MenuBarController.menuBarIcon()
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    /// Build menu lazily — not on every store.items change
    func menuWillOpen(_ menu: NSMenu) {
        previousApp = NSWorkspace.shared.frontmostApplication
        menu.removeAllItems()

        addItem(menu, title: "Open Clipse", action: #selector(openClipse), key: "")
        menu.addItem(.separator())

        appendRecentItems(to: menu)

        addItem(menu, title: "Settings…", action: #selector(openSettings), key: ",")
        addItem(menu, title: "Clear History", action: #selector(clearHistory), key: "")
        menu.addItem(.separator())

        // Debug: hotkey tap status
        let status = hotkeyManager?.statusDescription ?? "HotkeyManager not set"
        let statusItem = NSMenuItem(title: status, action: #selector(retryHotkey), keyEquivalent: "")
        statusItem.target = self
        menu.addItem(statusItem)

        // Debug: open panel directly (bypasses hotkey)
        addItem(menu, title: "Open Panel (debug)", action: #selector(openClipse), key: "")

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Clipse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func appendRecentItems(to menu: NSMenu) {
        let recent = store.items.prefix(5)
        guard !recent.isEmpty else { return }
        for (index, item) in recent.enumerated() {
            let title = String(item.content.prefix(50)).replacingOccurrences(of: "\n", with: " ")
            let menuItem = NSMenuItem(title: title, action: #selector(pasteFromMenu(_:)), keyEquivalent: "")
            menuItem.tag = index
            menuItem.target = self
            menu.addItem(menuItem)
        }
        menu.addItem(.separator())
    }

    @discardableResult
    private func addItem(_ menu: NSMenu, title: String, action: Selector, key: String) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Actions

    @objc private func openClipse() { panelController.show() }

    @objc private func pasteFromMenu(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index < store.items.count else { return }
        let item = store.items[index]
        previousApp?.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PasteEngine.paste(item, asPlainText: false)
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView(settings: AppSettings.shared)
            let hosting = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Clipse Settings"
            window.contentView = hosting
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func clearHistory() { store.clear() }

    @objc private func retryHotkey() {
        hotkeyManager?.registerIfNeeded()
        // Show updated status via NSAlert
        let alert = NSAlert()
        alert.messageText = "Hotkey Status"
        alert.informativeText = hotkeyManager?.statusDescription ?? "HotkeyManager not set"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Icon

    /// Programmatic clipboard icon that mirrors the app logo shape.
    /// isTemplate = true → system applies dark/light mode tinting automatically.
    private static func menuBarIcon() -> NSImage {
        let pt: CGFloat = 18
        let img = NSImage(size: NSSize(width: pt, height: pt), flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // Clipboard body
            let body = CGRect(x: 2, y: 1, width: 14, height: 16)
            ctx.addPath(CGPath(roundedRect: body, cornerWidth: 3, cornerHeight: 3, transform: nil))
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.fillPath()

            // White clip tab (top center)
            let tab = CGRect(x: 5.5, y: 13.5, width: 7, height: 4)
            ctx.addPath(CGPath(roundedRect: tab, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            ctx.setFillColor(CGColor(gray: 1, alpha: 1))
            ctx.fillPath()

            // White content lines — 3 rows
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.9))
            for (y, w): (CGFloat, CGFloat) in [(10, 10), (7.5, 8), (5, 9)] {
                ctx.addPath(CGPath(roundedRect: CGRect(x: 4, y: y, width: w, height: 1.5),
                                   cornerWidth: 0.75, cornerHeight: 0.75, transform: nil))
                ctx.fillPath()
            }

            // Small accent dot on first row (mirrors app icon highlight)
            ctx.setFillColor(CGColor(gray: 1, alpha: 0.5))
            ctx.addPath(CGPath(ellipseIn: CGRect(x: 12.5, y: 10, width: 2.5, height: 2.5), transform: nil))
            ctx.fillPath()

            return true
        }
        img.isTemplate = true
        return img
    }
}
