import AppKit
import SwiftUI

final class PanelController {
    private let panel: ClipboardPanel
    private let store: ClipboardStore
    private(set) var isVisible = false
    private(set) var previousApp: NSRunningApplication?

    init(store: ClipboardStore) {
        self.store = store
        self.panel = ClipboardPanel()
        preload()
    }

    // MARK: - Preload (вызывается один раз при старте)

    private func preload() {
        // Placeholder — SwiftUI content подключается в Этапе 6
        let placeholder = NSHostingView(rootView: Color.clear)
        placeholder.wantsLayer = true
        panel.contentView = placeholder
    }

    // MARK: - Show / Hide / Toggle

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        // Сохраняем activeApp ДО показа панели
        previousApp = NSWorkspace.shared.frontmostApplication

        panel.centerOnActiveScreen()
        panel.alphaValue = 0
        panel.orderFront(nil)
        panel.makeKey()
        isVisible = true

        // 60ms fade — CABasicAnimation не блокирует main thread
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.06
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        // Скрываем мгновенно — ничто не должно мешать возврату фокуса
        panel.orderOut(nil)
        panel.alphaValue = 0
    }
}
