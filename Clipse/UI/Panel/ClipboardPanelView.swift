import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: PanelState
    @ObservedObject private var license = LicenseManager.shared
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            // Base glass layer
            VisualEffectView()

            // Pro glow ring — rendered behind content, blurred outward
            if license.isPro {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.teal.opacity(0.7), .indigo.opacity(0.5), .teal.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 4)
            }

            // Content
            VStack(spacing: 0) {
                SearchBarView(query: $state.query, isFocused: $searchFocused)

                Divider().opacity(0.15)

                if state.filteredItems.isEmpty {
                    EmptyStateView(isSearching: !state.query.isEmpty)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    ClipboardListView(
                        items: state.filteredItems,
                        selectedIndex: state.selectedIndex,
                        onDoubleTap: state.onDoubleTapPaste,
                        onSelect: state.onSelect
                    )
                    .transition(.opacity)
                }

                if let reason = state.upgradeReason {
                    Divider().opacity(0.15)
                    UpgradePromptView(reason: reason) { state.upgradeReason = nil }
                }

                Divider().opacity(0.15)

                footerView
            }

            // Glass border ring
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.28), .white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: state.query) { _ in state.selectedIndex = 0 }
        .onChange(of: state.focusTrigger) { _ in searchFocused = true }
        .animation(.easeInOut(duration: 0.18), value: state.filteredItems.isEmpty)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 14) {
            hint("↵", "Paste")
            hint("⇧↵", "Plain text")
            hint("⌘C", "Copy")
            hint("⌘P", "Pin")
            hint("⌘1…9", "Quick")
            hint("⎋", "Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
}
