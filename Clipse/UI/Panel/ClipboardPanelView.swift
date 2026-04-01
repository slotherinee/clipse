import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var state: PanelState

    @FocusState private var searchFocused: Bool
    // displayItems обновляется через onChange — не пересчитывается при каждом рендере
    @State private var displayItems: [ClipboardItem] = []

    var body: some View {
        ZStack {
            VisualEffectView()

            VStack(spacing: 0) {
                SearchBarView(query: $state.query, isFocused: $searchFocused)

                Divider().opacity(0.2)

                if displayItems.isEmpty {
                    EmptyStateView(isSearching: !state.query.isEmpty)
                } else {
                    ClipboardListView(items: displayItems, selectedIndex: state.selectedIndex)
                }

                Divider().opacity(0.2)

                footerView
            }
        }
        .onAppear { refreshItems() }
        // Обновляем items только при изменении query или store.items
        .onChange(of: state.query)      { _, _ in refreshItems(); state.selectedIndex = 0 }
        .onChange(of: store.items)      { _, _ in refreshItems() }
        // Фокус устанавливается по триггеру из PanelController
        .onChange(of: state.focusTrigger) { _, _ in searchFocused = true }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 14) {
            hint("↵", "Paste")
            hint("⇧↵", "Plain text")
            hint("⌘P", "Pin")
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

    // MARK: - Helpers

    private func refreshItems() {
        displayItems = store.filteredItems(query: state.query)
    }
}
