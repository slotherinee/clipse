import Foundation

enum FuzzySearch {

    /// Фильтрует и сортирует items по query. Без debounce — вызывается на каждый keystroke.
    static func filter(
        _ items: [ClipboardItem],
        query: String,
        isPro: Bool = false,
        activeBundleID: String? = nil
    ) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }

        // Lowercase query один раз на весь вызов
        let lowQuery = query.lowercased()

        var results: [(item: ClipboardItem, score: Int)] = []
        results.reserveCapacity(items.count)

        for item in items {
            // contentLowercased хранится в модели — нет аллокации здесь
            let base = match(item.contentLowercased, query: lowQuery)
            guard base > 0 else { continue }

            var total = base
            if isPro {
                total += recencyBoost(item.timestamp)
                total += ContextAwareness.boost(for: item, bundleID: activeBundleID)
            }
            results.append((item, total))
        }

        // sort in-place — не создаём новый массив
        results.sort { $0.score > $1.score }
        return results.map { $0.item }
    }

    static func score(_ text: String, query: String) -> Int {
        match(text.lowercased(), query: query.lowercased())
    }

    // MARK: - Private

    /// unicodeScalars быстрее Character (нет grapheme cluster breaking)
    private static func match(_ text: String, query: String) -> Int {
        let textScalars = text.unicodeScalars
        let queryScalars = query.unicodeScalars

        var score = 0
        var qi = queryScalars.startIndex
        var lastMatchPos = -1
        var consecutive = 0
        var pos = 0

        for scalar in textScalars {
            guard qi < queryScalars.endIndex else { break }
            if scalar == queryScalars[qi] {
                score += 10
                if pos == lastMatchPos + 1 {
                    consecutive += 1
                    score += consecutive * 8
                } else {
                    consecutive = 0
                }
                if pos < 5 { score += 5 }
                lastMatchPos = pos
                qi = queryScalars.index(after: qi)
            }
            pos += 1
        }

        return qi == queryScalars.endIndex ? score : 0
    }

    private static func recencyBoost(_ timestamp: Date) -> Int {
        let age = -timestamp.timeIntervalSinceNow
        if age < 60    { return 20 }
        if age < 3600  { return 10 }
        if age < 86400 { return 5 }
        return 0
    }
}
