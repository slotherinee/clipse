import AppKit

final class ClipboardPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: true  // defer=true: не создаёт backing store до первого показа
        )
        configure()
    }

    // MARK: - Configuration (один раз при init)

    private func configure() {
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        alphaValue = 0
    }

    // MARK: - Position

    func centerOnActiveScreen() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - frame.width / 2
        let y = sf.midY - frame.height / 2 + 80
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Key window

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
