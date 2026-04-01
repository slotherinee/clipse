import SwiftUI

struct EmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isSearching ? "magnifyingglass" : "clipboard")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)

            Text(isSearching ? "No results" : "Nothing copied yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            if !isSearching {
                Text("Press Cmd+C to start")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}
