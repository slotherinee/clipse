import Foundation

enum ClipType: String, Equatable, Codable {
    case text
    case url
    case code
    case image
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    var type: ClipType
    var content: String
    /// Хранится один раз — не пересчитывается при каждом поиске
    let contentLowercased: String
    var imageData: Data?
    /// Absolute path to the original image file (Finder copy). Persisted. nil for data-only images.
    var imageFilePath: String?
    var timestamp: Date
    var pinned: Bool
    var sourceApp: String?
    var sourceBundleID: String?

    init(
        id: UUID = UUID(),
        type: ClipType,
        content: String,
        imageData: Data? = nil,
        imageFilePath: String? = nil,
        timestamp: Date = Date(),
        pinned: Bool = false,
        sourceApp: String? = nil,
        sourceBundleID: String? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.contentLowercased = content.lowercased()
        self.imageData = imageData
        self.imageFilePath = imageFilePath
        self.timestamp = timestamp
        self.pinned = pinned
        self.sourceApp = sourceApp
        self.sourceBundleID = sourceBundleID
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
