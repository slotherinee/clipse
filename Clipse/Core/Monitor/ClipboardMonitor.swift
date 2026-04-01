import AppKit

// Keywords that must appear at the START of the first line to qualify as code.
// Avoids false positives like "don't let me go" or "https://…" containing "//".
private let lineStartSignals = ["func ", "def ", "class ", "import ", "let ", "var ",
                                 "const ", "return ", "export ", "package "]
// Patterns that are unambiguous code regardless of position (rare in plain text)
private let codePatterns = ["() {", ") {\n", ";\n", " => {", " => \n"]
private let maxStringLength = 50_000 // ~50KB — пропускаем огромные логи/файлы

final class ClipboardMonitor {
    private let store: ClipboardStore
    private let settings: AppSettings
    private let queue = DispatchQueue(label: "com.clipse.monitor", qos: .utility)
    private var isRunning = false
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    init(store: ClipboardStore, settings: AppSettings = .shared) {
        self.store = store
        self.settings = settings
    }

    func start() {
        isRunning = true
        scheduleNextPoll()
    }

    func stop() {
        isRunning = false
    }

    private func scheduleNextPoll() {
        queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.isRunning else { return }
            self.poll()
            self.scheduleNextPoll()
        }
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let frontApp = NSWorkspace.shared.frontmostApplication
        if let id = frontApp?.bundleIdentifier, settings.excludedBundleIDs.contains(id) { return }

        let sourceApp = frontApp?.localizedName
        let sourceBundleID = frontApp?.bundleIdentifier

        if let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= maxStringLength else { return }
            let type = detectType(trimmed)
            PerformanceMonitor.clipboardCaptured(type: type.rawValue, contentLength: trimmed.count)
            let item = ClipboardItem(type: type, content: trimmed, sourceApp: sourceApp, sourceBundleID: sourceBundleID)
            DispatchQueue.main.async { self.store.add(item) }
            return
        }

        // Image file copied from Finder → store path only (no data, persists across restarts)
        if let urlData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.file-url")),
           let urlString = String(data: urlData, encoding: .utf8),
           let fileURL = URL(string: urlString), fileURL.isFileURL {
            let ext = fileURL.pathExtension.lowercased()
            let imageExts: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "svg"]
            if imageExts.contains(ext) {
                let path = fileURL.path
                PerformanceMonitor.clipboardCaptured(type: "image-file", contentLength: path.count)
                let item = ClipboardItem(type: .image, content: path, imageFilePath: path,
                                         sourceApp: sourceApp, sourceBundleID: sourceBundleID)
                DispatchQueue.main.async { self.store.add(item) }
                return
            }
        }

        // Raw image data (screenshot, web, etc.) — in-memory only, Pro feature
        if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            PerformanceMonitor.clipboardCaptured(type: "image", contentLength: data.count)
            let item = ClipboardItem(type: .image, content: "[Image]", imageData: data, sourceApp: sourceApp, sourceBundleID: sourceBundleID)
            DispatchQueue.main.async { self.store.add(item) }
        }
    }

    private func detectType(_ string: String) -> ClipType {
        if isURL(string) { return .url }
        if isCode(string) { return .code }
        return .text
    }

    // Простой prefix check — в 10x быстрее чем URL(string:)
    private func isURL(_ string: String) -> Bool {
        (string.hasPrefix("http://") || string.hasPrefix("https://")) && !string.contains(" ")
    }

    private func isCode(_ string: String) -> Bool {
        // Check first non-empty line starts with a code keyword
        let firstLine = string
            .prefix(while: { $0 != "\n" })
            .trimmingCharacters(in: .whitespaces)
        if lineStartSignals.contains(where: { firstLine.hasPrefix($0) }) { return true }
        // Unambiguous structural patterns (never appear in plain prose)
        return codePatterns.contains { string.contains($0) }
    }
}
