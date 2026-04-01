import Foundation

/// Shared state между PanelController (keyboard) и ClipboardPanelView (render).
final class PanelState: ObservableObject {
    @Published var query: String = ""
    @Published var selectedIndex: Int = 0
    /// Toggles каждый раз при show() — view реагирует и устанавливает фокус
    @Published var focusTrigger: Bool = false

    func reset() {
        query = ""
        selectedIndex = 0
    }
}
