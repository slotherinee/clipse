import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let selectedIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
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
            }
            // Magnetic selection: selected item центрируется при навигации
            .onChange(of: selectedIndex) { newIndex in
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxHeight: 340)
    }
}
