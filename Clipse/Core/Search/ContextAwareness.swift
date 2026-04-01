import Foundation

enum AppCategory {
    case browser
    case ide
    case messenger
    case other
}

private let browsers: Set<String> = [
    "com.apple.Safari",
    "com.google.Chrome",
    "company.thebrowser.Browser",   // Arc
    "org.mozilla.firefox",
    "com.brave.Browser",
    "com.microsoft.edgemac"
]

private let ides: Set<String> = [
    "com.apple.dt.Xcode",
    "com.microsoft.VSCode",
    "com.todesktop.230313mzl4w4u92", // Cursor
    "com.jetbrains.intellij",
    "com.jetbrains.AppCode",
    "com.sublimetext.4"
]

private let messengers: Set<String> = [
    "ru.keepcoder.Telegram",
    "com.tinyspeck.slackmacgap",
    "com.apple.MobileSMS",
    "net.whatsapp.WhatsApp",
    "com.hnc.Discord"
]

enum ContextAwareness {

    static func category(for bundleID: String?) -> AppCategory {
        guard let id = bundleID else { return .other }
        if browsers.contains(id) { return .browser }
        if ides.contains(id) { return .ide }
        if messengers.contains(id) { return .messenger }
        return .other
    }

    /// Pro: буст релевантных типов под активное приложение
    static func boost(for item: ClipboardItem, bundleID: String?) -> Int {
        switch category(for: bundleID) {
        case .browser:   return item.type == .url  ? 15 : 0
        case .ide:       return item.type == .code ? 15 : 0
        case .messenger: return item.type == .text ? 10 : 0
        case .other:     return 0
        }
    }
}
