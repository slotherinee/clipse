import AppKit
import Carbon

enum PasteEngine {

    /// Пишет item в pasteboard и симулирует Cmd+V.
    /// Вызывается ПОСЛЕ того как previousApp уже активирован.
    static func paste(_ item: ClipboardItem, asPlainText: Bool = false) {
        writeToPasteboard(item, asPlainText: asPlainText)
        simulateCmdV()
    }

    // MARK: - Private

    private static func writeToPasteboard(_ item: ClipboardItem, asPlainText: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()

        if item.type == .image, let data = item.imageData, !asPlainText {
            pb.setData(data, forType: .tiff)
        } else {
            // asPlainText: только .string тип — форматирование не попадёт в целевое приложение
            pb.setString(item.content, forType: .string)
        }
    }

    /// Симулирует нажатие Cmd+V через CGEvent.
    /// .hidSystemState — наиболее надёжный источник для симуляции пользовательского ввода.
    private static func simulateCmdV() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand

        // .cgAnnotatedSessionEventTap корректно атрибутирует event как user input
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
