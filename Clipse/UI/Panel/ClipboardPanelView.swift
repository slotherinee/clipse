import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: PanelState
    @ObservedObject private var license = LicenseManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            VisualEffectView()

            if let item = state.detailItem {
                ClipboardDetailView(item: item, scrollCoordinator: state.detailScroll) {
                    state.detailItem = nil
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                listView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Glass border ring
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .preferredColorScheme(settings.panelTheme.colorScheme)
        .animation(.easeInOut(duration: 0.18), value: state.detailItem?.id)
        .onChange(of: state.query) { _ in state.selectedIndex = 0 }
        .onChange(of: state.focusTrigger) { _ in searchFocused = true }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            SearchBarView(query: $state.query, isFocused: $searchFocused)

            Divider().opacity(0.12)

            if state.filteredItems.isEmpty {
                EmptyStateView(isSearching: !state.query.isEmpty)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                ClipboardListView(
                    items: state.filteredItems,
                    selectedIndex: state.selectedIndex,
                    onDoubleTap: state.onDoubleTapPaste,
                    onSelect: state.onSelect,
                    onShowDetail: { state.detailItem = $0 }
                )
                .transition(.opacity)
            }

            if let reason = state.upgradeReason {
                Divider().opacity(0.12)
                UpgradePromptView(reason: reason) { state.upgradeReason = nil }
            }

            Divider().opacity(0.12)
            footerView
        }
        .animation(.easeInOut(duration: 0.18), value: state.filteredItems.isEmpty)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 0) {
            hint("↵", "Paste")
            hint("⇧↵", "Plain")
            hint("⌘C", "Copy")
            hint("⌘P", "Pin")
            hint("→", "Detail")
            Spacer()
            hint("⎋", "Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.55))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.primary.opacity(0.3))
        }
        .padding(.trailing, 12)
    }
}
