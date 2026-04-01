import SwiftUI
import AppKit

// Module-level cache: bundle ID → NSImage? (nil = not found, avoids repeated lookups)
private var iconCache: [String: NSImage?] = [:]

struct AppIconView: View {
    let bundleID: String

    var body: some View {
        if let icon = resolvedIcon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 12, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }

    private var resolvedIcon: NSImage? {
        // Cache hit (including cached nil — app not found)
        if iconCache.keys.contains(bundleID) { return iconCache[bundleID] ?? nil }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            iconCache[bundleID] = .some(nil)
            return nil
        }
        let img = NSWorkspace.shared.icon(forFile: url.path)
        img.size = NSSize(width: 12, height: 12)
        iconCache[bundleID] = .some(img)
        return img
    }
}
