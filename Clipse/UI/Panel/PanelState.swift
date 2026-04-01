import Foundation

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

    func reset() {
        query = ""
        selectedIndex = 0
        filteredItems = []
        upgradeReason = nil
    }
}
