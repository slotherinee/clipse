import SwiftUI

struct SearchBarView: View {
    @Binding var query: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 14, weight: .medium))

            TextField("Search clipboard…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isFocused)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
