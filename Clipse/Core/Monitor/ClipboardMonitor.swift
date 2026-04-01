import AppKit

private let excludedBundleIDs: Set<String> = [
    "com.agilebits.onepassword7",
    "com.agilebits.onepassword-osx",
    "com.bitwarden.desktop",
    "com.apple.keychainaccess",
    "com.lastpass.lastpass",
    "com.dashlane.dashlane-osx",
    "com.1password.1password"
]

private let codeSignals = ["func ", "def ", "class ", "import ", "//", "=>", "->", "var ", "let ", "const "]

final class ClipboardMonitor {
    private let store: ClipboardStore
    private let queue = DispatchQueue(label: "com.clipse.monitor", qos: .utility)
    private var isRunning = false
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    init(store: ClipboardStore) {
        self.store = store
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
        if let id = frontApp?.bundleIdentifier, excludedBundleIDs.contains(id) { return }

        let sourceApp = frontApp?.localizedName
        let sourceBundleID = frontApp?.bundleIdentifier

        if let string = pasteboard.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ClipboardItem(type: detectType(string), content: string, sourceApp: sourceApp, sourceBundleID: sourceBundleID)
            DispatchQueue.main.async { self.store.add(item) }
            return
        }

        if let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let item = ClipboardItem(type: .image, content: "[Image]", imageData: data, sourceApp: sourceApp, sourceBundleID: sourceBundleID)
            DispatchQueue.main.async { self.store.add(item) }
        }
    }

    private func detectType(_ string: String) -> ClipType {
        if isURL(string) { return .url }
        if isCode(string) { return .code }
        return .text
    }

    private func isURL(_ string: String) -> Bool {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    private func isCode(_ string: String) -> Bool {
        codeSignals.contains { string.contains($0) }
    }
}
