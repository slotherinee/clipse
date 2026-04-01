import AppKit
import Carbon

final class HotkeyManager {
    private let onActivate: () -> Void
    private var eventTap: CFMachPort?

    init(onActivate: @escaping () -> Void) {
        self.onActivate = onActivate
    }

    func register() {
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
            print("⚠️ CGEventTap failed — Accessibility permission required")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func unregister() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        eventTap = nil
    }

    // MARK: - Internal (вызывается из C callback)

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Система может отключить tap — реактивируем немедленно
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return nil
        }

        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        guard
            flags.contains(.maskCommand),
            flags.contains(.maskShift),
            keyCode == CGKeyCode(kVK_ANSI_V)
        else { return Unmanaged.passRetained(event) }

        // Dispatch async — не блокируем event tap callback
        PerformanceMonitor.hotkeyFired()
        DispatchQueue.main.async { [weak self] in self?.onActivate() }
        return nil // Поглощаем событие
    }
}

// MARK: - C callback (global function — единственный способ передать в CGEventTap)

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
