import Foundation

final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    // Injected from LicenseManager (Этап 11)
    var isPro: () -> Bool = { true }

    private var maxItems: Int { isPro() ? 100 : 30 }

    func add(_ item: ClipboardItem) {
        if item.type == .image && !isPro() { return }

        if let index = items.firstIndex(where: { $0.content == item.content && $0.type == item.type }) {
            var updated = items[index]
            updated.timestamp = item.timestamp
            items.remove(at: index)
            items.insert(updated, at: 0)
        } else {
            items.insert(item, at: 0)
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

    // Базовая выборка — поиск подключается в Этапе 4
    func filteredItems(query: String) -> [ClipboardItem] {
        let sorted = items.sorted { $0.pinned && !$1.pinned }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    private func trim() {
        guard items.count > maxItems else { return }
        let pinned = items.filter { $0.pinned }
        var unpinned = items.filter { !$0.pinned }
        while pinned.count + unpinned.count > maxItems, !unpinned.isEmpty {
            unpinned.removeLast()
        }
        items = pinned + unpinned
    }

    private func reorder() {
        let pinned = items.filter { $0.pinned }
        let unpinned = items.filter { !$0.pinned }
        items = pinned + unpinned
    }
}
