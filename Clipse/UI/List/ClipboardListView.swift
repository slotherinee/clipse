import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let selectedIndex: Int
    let onDoubleTap: ((ClipboardItem) -> Void)?
    let onSelect: ((Int) -> Void)?
    let onShowDetail: ((ClipboardItem) -> Void)?

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
                            isSelected: index == selectedIndex,
                            onDoubleTap: onDoubleTap,
                            onSelect: onSelect,
                            onShowDetail: onShowDetail
                        )
                        .id(item.id)  // UUID — не индекс, иначе LazyVStack кэширует устаревший контент
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: itemsIdentityDigest)
            }
            .onChange(of: selectedIndex) { newIndex in
                guard newIndex < items.count else { return }
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo(items[newIndex].id, anchor: .center)
                }
            }
        }
        .frame(maxHeight: 340)
    }

    private var itemsIdentityDigest: Int {
        var hasher = Hasher()
        for item in items { hasher.combine(item.id); hasher.combine(item.pinned) }
        return hasher.finalize()
    }
}
