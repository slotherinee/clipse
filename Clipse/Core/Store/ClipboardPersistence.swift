import Foundation

/// Persists clipboard history to ~/Library/Application Support/Clipse/history.json.
/// Saves are atomic (write to tmp + rename) — no corruption on crash.
/// imageData is stripped before saving — images are transient, data can be MB-sized.
enum ClipboardPersistence {

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("Clipse", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    /// Save on a background queue — never blocks the main thread.
    static func save(_ items: [ClipboardItem]) {
        let stripped = items.map { item -> ClipboardItem in
            guard item.imageData != nil else { return item }
            var copy = item
            copy.imageData = nil
            return copy
        }
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? encoder.encode(stripped) else { return }
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    /// Load synchronously — called once at app start before UI appears.
    static func load() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: storageURL),
              let items = try? decoder.decode([ClipboardItem].self, from: data)
        else { return [] }
        return items
    }
}
