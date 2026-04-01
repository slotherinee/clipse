import Foundation

enum FuzzySearch {

    /// Фильтрует и сортирует items по query. O(n) при пустом query, O(n*m) при поиске.
    static func filter(
        _ items: [ClipboardItem],
        query: String,
        isPro: Bool = false,
        activeBundleID: String? = nil
    ) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }

        let lowQuery = query.lowercased()

        return items
            .compactMap { item -> (ClipboardItem, Int)? in
                let base = score(item.content.lowercased(), query: lowQuery)
                guard base > 0 else { return nil }

                var total = base
                if isPro {
                    total += recencyBoost(item.timestamp)
                    total += ContextAwareness.boost(for: item, bundleID: activeBundleID)
                }
                return (item, total)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    /// Возвращает score > 0 если query — subsequence text, иначе 0.
    static func score(_ text: String, query: String) -> Int {
        match(text, query: query)
    }

    // MARK: - Private

    private static func match(_ text: String, query: String) -> Int {
        var score = 0
        var qi = query.startIndex
        var lastMatchPos = -1
        var consecutive = 0

        for (pos, char) in text.enumerated() {
            guard qi < query.endIndex else { break }
            if char == query[qi] {
                score += 10
                if pos == lastMatchPos + 1 {
                    consecutive += 1
                    score += consecutive * 8  // бонус за последовательные символы
                } else {
                    consecutive = 0
                }
                // бонус за раннее совпадение
                if pos < 5 { score += 5 }
                lastMatchPos = pos
                qi = query.index(after: qi)
            }
        }

        return qi == query.endIndex ? score : 0
    }

    /// Pro: свежие items получают небольшой буст
    private static func recencyBoost(_ timestamp: Date) -> Int {
        let age = -timestamp.timeIntervalSinceNow
        if age < 60 { return 20 }       // < 1 мин
        if age < 3600 { return 10 }     // < 1 час
        if age < 86400 { return 5 }     // < 1 день
        return 0
    }
}
