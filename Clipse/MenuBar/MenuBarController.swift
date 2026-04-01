import AppKit
import SwiftUI

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store: ClipboardStore
    private let panelController: PanelController
    // Settings window created once, reused — avoids re-allocating NSHostingView
    private var settingsWindow: NSWindow?
    // Captured in menuWillOpen — before menu activates our app
    private var previousApp: NSRunningApplication?

    init(store: ClipboardStore, panelController: PanelController) {
        self.store = store
        self.panelController = panelController
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipse")
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
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
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
}
