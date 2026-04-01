import AppKit
import Carbon
import os.log

private let log = OSLog(subsystem: "com.clipse.app", category: "Hotkey")

final class HotkeyManager {
    private let onActivate: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    var isRegistered: Bool { hotKeyRef != nil }

    var statusDescription: String {
        isRegistered ? "✅ Hotkey registered (no AX needed)" : "❌ Hotkey not registered"
    }

    init(onActivate: @escaping () -> Void) {
        self.onActivate = onActivate
    }

    func register() {
        guard hotKeyRef == nil else { return }

        // Install Carbon event handler on the application event target
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))

        // Pass self as refcon via Unmanaged
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyCallback,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard status == noErr else {
            os_log("HotkeyManager: InstallEventHandler failed %{public}d", log: log, type: .error, status)
            return
        }

        // Cmd+Shift+V  (cmdKey | shiftKey, kVK_ANSI_V = 9)
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CLPS"), id: 1)
        let regStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if regStatus == noErr {
            os_log("HotkeyManager: Cmd+Shift+V registered via Carbon", log: log, type: .info)
        } else {
            os_log("HotkeyManager: RegisterEventHotKey failed %{public}d", log: log, type: .error, regStatus)
        }
    }

    func registerIfNeeded() {
        guard !isRegistered else { return }
        register()
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let handler = eventHandlerRef { RemoveEventHandler(handler); eventHandlerRef = nil }
    }

    // MARK: - Internal (called from C callback)

    fileprivate func handleHotkey() {
        os_log("HotkeyManager: Cmd+Shift+V fired", log: log, type: .info)
        PerformanceMonitor.hotkeyFired()
        DispatchQueue.main.async { [weak self] in self?.onActivate() }
    }
}

// MARK: - Helpers

private func fourCharCode(_ s: String) -> FourCharCode {
    var result: FourCharCode = 0
    for char in s.utf8.prefix(4) { result = result << 8 + FourCharCode(char) }
    return result
}

private func carbonHotkeyCallback(
    _: EventHandlerCallRef?,
    event: EventRef?,
    refcon: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let refcon else { return OSStatus(eventNotHandledErr) }
    Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue().handleHotkey()
    return noErr
}
