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
        store.onUpgradeNeeded = { [weak self] reason in
            self?.state.upgradeReason = reason
        }
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
                let lastIndex = self.currentItems.count - 1
                if self.state.selectedIndex > lastIndex { self.state.selectedIndex = max(0, lastIndex) }
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

    // Cmd+1…9: key codes → item indices. Dictionary создаётся один раз — O(1) lookup
    private let numKeyMap: [Int: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
    ]

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        let cmd = event.modifierFlags.contains(.command)

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
        case kVK_ANSI_C where cmd:
            // Re-copy: записываем в pasteboard без вставки, панель остаётся открытой
            guard state.selectedIndex < currentItems.count else { return nil }
            recopy(currentItems[state.selectedIndex]); return nil
        case kVK_ANSI_P where cmd:
            guard state.selectedIndex < currentItems.count else { return nil }
            store.togglePin(currentItems[state.selectedIndex]); return nil
        default:
            // Cmd+1…9: быстрый выбор + мгновенная вставка
            if cmd, let index = numKeyMap[Int(event.keyCode)], index < currentItems.count {
                paste(currentItems[index], asPlainText: false)
                return nil
            }
            return event
        }
    }

    private func paste(_ item: ClipboardItem, asPlainText: Bool) {
        hide()
        // Activate ПЕРЕД asyncAfter — даём системе начать переключение фокуса
        previousApp?.activate(options: .activateIgnoringOtherApps)
        // 100ms — стандартная задержка для надёжного переключения фокуса на macOS.
        // Меньше → paste попадает в неактивное окно. Больше → ощутимая задержка.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PasteEngine.paste(item, asPlainText: asPlainText)
        }
    }

    private func recopy(_ item: ClipboardItem) {
        // Пишем в pasteboard — без симуляции Cmd+V, без закрытия панели
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content, forType: .string)
    }
}
