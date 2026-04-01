import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let selectedIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        // Pinned zone divider — thin separator, not a folder
                        if index > 0 && !item.pinned && items[index - 1].pinned {
                            Divider()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                        }

                        ClipboardItemView(
                            item: item,
                            index: index,
                            isSelected: index == selectedIndex
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                // Spring animation when items reorder (pin/unpin)
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: itemsIdentityDigest)
            }
            .onChange(of: selectedIndex) { newIndex in
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxHeight: 340)
    }

    private var itemsIdentityDigest: Int {
        var hasher = Hasher()
        for item in items { hasher.combine(item.id) }
        return hasher.finalize()
    }
}
