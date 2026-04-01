import Foundation
import AppKit

/// Passed to ClipboardDetailView so PanelController can scroll it via arrow keys.
final class DetailScrollCoordinator {
    weak var scrollView: NSScrollView?

    func scroll(by delta: CGFloat) {
        guard let sv = scrollView, let doc = sv.documentView else { return }
        let cur = sv.documentVisibleRect.origin
        let maxY = max(0, doc.frame.height - sv.documentVisibleRect.height)
        let newY = max(0, min(maxY, cur.y + delta))
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            sv.contentView.animator().setBoundsOrigin(NSPoint(x: cur.x, y: newY))
        }
    }
}

/// Shared state между PanelController (keyboard) и ClipboardPanelView (render).
final class PanelState: ObservableObject {
    @Published var query: String = ""
    @Published var selectedIndex: Int = 0
    @Published var filteredItems: [ClipboardItem] = []
    /// Toggles каждый раз при show() — view реагирует и устанавливает фокус
    @Published var focusTrigger: Bool = false
    /// Non-nil when a Pro feature was blocked — drives inline UpgradePromptView
    @Published var upgradeReason: UpgradeReason?

    /// Called when the user double-taps an item to paste it immediately
    var onDoubleTapPaste: ((ClipboardItem) -> Void)?
    var onSelect: ((Int) -> Void)?

    /// Non-nil when detail view is open for an item
    @Published var detailItem: ClipboardItem?
    let detailScroll = DetailScrollCoordinator()

    func reset() {
        query = ""
        selectedIndex = 0
        upgradeReason = nil
        detailItem = nil
        // filteredItems intentionally NOT cleared — PanelController repopulates synchronously
    }
}
