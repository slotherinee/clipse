import Foundation

final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    // Injected from LicenseManager (Stage 11)
    var isPro: () -> Bool = { true }
    /// Fired on main thread when a Pro feature is needed. Set by PanelController.
    var onUpgradeNeeded: ((UpgradeReason) -> Void)?

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
        guard isPro() else { onUpgradeNeeded?(.pin); return }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinned.toggle()
        reorder()
    }

    func clear() {
        items.removeAll { !$0.pinned }
    }

    // Fuzzy search подключён в Этапе 4. activeBundleID для context awareness (Pro).
    func filteredItems(query: String, activeBundleID: String? = nil) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        return FuzzySearch.filter(items, query: query, isPro: isPro(), activeBundleID: activeBundleID)
    }

    // Вставляем сразу после последнего pinned — O(n) один проход
    private func insertAfterPinned(_ item: ClipboardItem) {
        let insertIndex = items.firstIndex(where: { !$0.pinned }) ?? items.endIndex
        items.insert(item, at: insertIndex)
    }

    // Удаляем лишние unpinned с конца — O(n) один проход
    private func trim() {
        guard items.count > maxItems else { return }
        if !isPro() { onUpgradeNeeded?(.historyLimit) }
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
