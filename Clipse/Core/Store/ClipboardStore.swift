import Foundation

final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    // Injected from LicenseManager (Этап 11)
    var isPro: () -> Bool = { true }

    private var maxItems: Int { isPro() ? 100 : 30 }

    // Инвариант: pinned items всегда в начале массива
    func add(_ item: ClipboardItem) {
        if item.type == .image && !isPro() { return }

        if let index = items.firstIndex(where: { $0.content == item.content && $0.type == item.type }) {
            var updated = items[index]
            updated.timestamp = item.timestamp
            items.remove(at: index)
            insertAfterPinned(updated)
        } else {
            insertAfterPinned(item)
            trim()
        }
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinned.toggle()
        reorder()
    }

    func clear() {
        items.removeAll { !$0.pinned }
    }

    // Инвариант соблюдён — sort не нужен, O(1) вместо O(n log n)
    func filteredItems(query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    // Вставляем сразу после последнего pinned — O(n) один проход
    private func insertAfterPinned(_ item: ClipboardItem) {
        let insertIndex = items.firstIndex(where: { !$0.pinned }) ?? items.endIndex
        items.insert(item, at: insertIndex)
    }

    // Удаляем лишние unpinned с конца — O(n) один проход
    private func trim() {
        guard items.count > maxItems else { return }
        let excess = items.count - maxItems
        let unpinnedIndices = items.indices.filter { !items[$0].pinned }.suffix(excess)
        items.remove(atOffsets: IndexSet(unpinnedIndices))
    }

    private func reorder() {
        let pinned = items.filter { $0.pinned }
        let unpinned = items.filter { !$0.pinned }
        items = pinned + unpinned
    }
}
