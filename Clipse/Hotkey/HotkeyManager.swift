import AppKit
import Carbon

final class HotkeyManager {
    private let onActivate: () -> Void
    private var eventTap: CFMachPort?

    /// True if CGEventTap was successfully created and is active
    var isRegistered: Bool { eventTap != nil }

    init(onActivate: @escaping () -> Void) {
        self.onActivate = onActivate
    }

    func register() {
        // Don't double-register
        if let existing = eventTap {
            CGEvent.tapEnable(tap: existing, enable: true)
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyEventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            // Accessibility not yet granted — will retry via registerIfNeeded()
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// Call after accessibility is granted — re-creates tap if it previously failed
    func registerIfNeeded() {
        guard !isRegistered else { return }
        register()
    }

    func unregister() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        eventTap = nil
    }

    // MARK: - Internal (called from C callback)

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return nil
        }

        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        let flags   = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        guard
            flags.contains(.maskCommand),
            flags.contains(.maskShift),
            keyCode == CGKeyCode(kVK_ANSI_V)
        else { return Unmanaged.passRetained(event) }

        PerformanceMonitor.hotkeyFired()
        DispatchQueue.main.async { [weak self] in self?.onActivate() }
        return nil
    }
}

private func hotkeyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passRetained(event) }
    return Unmanaged<HotkeyManager>
        .fromOpaque(refcon)
        .takeUnretainedValue()
        .handle(type: type, event: event)
}
