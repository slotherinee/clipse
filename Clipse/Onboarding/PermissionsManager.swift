import AppKit
import ApplicationServices

enum PermissionsManager {

    /// O(1) system call — safe to check on main thread
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Triggers the system accessibility prompt dialog.
    /// If already granted, this is a no-op.
    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}
