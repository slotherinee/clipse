import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: PanelState

    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            VisualEffectView()

            VStack(spacing: 0) {
                SearchBarView(query: $state.query, isFocused: $searchFocused)

                Divider().opacity(0.2)

                if state.filteredItems.isEmpty {
                    EmptyStateView(isSearching: !state.query.isEmpty)
                } else {
                    ClipboardListView(items: state.filteredItems, selectedIndex: state.selectedIndex)
                }

                if let reason = state.upgradeReason {
                    Divider().opacity(0.2)
                    UpgradePromptView(reason: reason) { self.state.upgradeReason = nil }
                }

                Divider().opacity(0.2)

                footerView
            }
        }
        .onChange(of: state.query) { _ in state.selectedIndex = 0 }
        // Фокус устанавливается по триггеру из PanelController
        .onChange(of: state.focusTrigger) { _ in searchFocused = true }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 14) {
            hint("↵", "Paste")
            hint("⇧↵", "Plain text")
            hint("⌘C", "Copy")
            hint("⌘P", "Pin")
            hint("⌘1…9", "Quick paste")
            hint("⎋", "Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
            Text(label).font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }
}
