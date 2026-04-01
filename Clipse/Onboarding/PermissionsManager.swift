import AppKit
import ApplicationServices

enum PermissionsManager {

    /// O(1) system call — safe to check on main thread
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Opens System Settings > Privacy & Security > Accessibility directly.
    static func requestAccessibility() {
        // Open System Settings > Privacy & Security > Accessibility directly
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
