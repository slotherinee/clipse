import AppKit
import SwiftUI
import Combine
import Carbon

final class PanelController {
    private let panel: ClipboardPanel
    let store: ClipboardStore
    let state: PanelState = PanelState()

    private(set) var isVisible = false
    private(set) var previousApp: NSRunningApplication?
    private var keyMonitor: Any?
    // Кэш отфильтрованных items для keyboard handler — синхронизируется через Combine
    private var currentItems: [ClipboardItem] = []
    private var cancellables = Set<AnyCancellable>()

    init(store: ClipboardStore) {
        self.store = store
        self.panel = ClipboardPanel()
        preload()
        subscribeToState()
    }

    // MARK: - Setup

    private func preload() {
        let view = ClipboardPanelView(store: store, state: state)
        let hosting = NSHostingView(rootView: view)
        hosting.wantsLayer = true
        panel.contentView = hosting
    }

    private func subscribeToState() {
        Publishers.CombineLatest(store.$items, state.$query)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, query in
                guard let self else { return }
                self.currentItems = self.store.filteredItems(query: query)
                let max = self.currentItems.count - 1
                if self.state.selectedIndex > max { self.state.selectedIndex = max(0, max) }
            }
            .store(in: &cancellables)
    }

    // MARK: - Show / Hide / Toggle

    func toggle() { isVisible ? hide() : show() }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        state.reset()
        panel.centerOnActiveScreen()
        panel.alphaValue = 0
        panel.orderFront(nil)
        panel.makeKey()
        isVisible = true
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.06
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            self?.handleKey($0) ?? $0
        }
        DispatchQueue.main.async { self.state.focusTrigger.toggle() }
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        panel.orderOut(nil)
        panel.alphaValue = 0
    }

    // MARK: - Keyboard

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        switch Int(event.keyCode) {
        case kVK_DownArrow:
            if state.selectedIndex < currentItems.count - 1 { state.selectedIndex += 1 }
            return nil
        case kVK_UpArrow:
            if state.selectedIndex > 0 { state.selectedIndex -= 1 }
            return nil
        case kVK_Return:
            guard state.selectedIndex < currentItems.count else { return nil }
            paste(currentItems[state.selectedIndex], asPlainText: event.modifierFlags.contains(.shift))
            return nil
        case kVK_Escape:
            hide(); return nil
        case kVK_ANSI_P where event.modifierFlags.contains(.command):
            guard state.selectedIndex < currentItems.count else { return nil }
            store.togglePin(currentItems[state.selectedIndex]); return nil
        default: return event
        }
    }

    private func paste(_ item: ClipboardItem, asPlainText: Bool) {
        hide()
        previousApp?.activate(options: .activateIgnoringOtherApps)
        // PasteEngine подключается в Этапе 9
    }
}
