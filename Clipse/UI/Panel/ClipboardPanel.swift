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

    /// Compute ideal panel height based on visible item count
    static func idealHeight(itemCount: Int) -> CGFloat {
        let chrome: CGFloat = 92  // search bar + 2 dividers + footer
        let emptyState: CGFloat  = 90
        let perItem: CGFloat     = 52
        let maxVisible           = 7
        if itemCount == 0 { return chrome + emptyState }
        return chrome + CGFloat(min(itemCount, maxVisible)) * perItem
    }

    func centerOnActiveScreen(itemCount: Int = 0) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let sf = screen.visibleFrame
        let h  = ClipboardPanel.idealHeight(itemCount: itemCount)
        let x  = sf.midX - frame.width / 2
        let y  = sf.midY - h / 2 + 80
        setFrame(NSRect(x: x, y: y, width: frame.width, height: h), display: false)
    }

    /// Animate panel to new height, keeping horizontal center + vertical midpoint
    func animateToHeight(_ height: CGFloat) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let sf = screen.visibleFrame
        let x  = sf.midX - frame.width / 2
        let y  = sf.midY - height / 2 + 80
        let newFrame = NSRect(x: x, y: y, width: frame.width, height: height)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(newFrame, display: true)
        }
    }

    // MARK: - Key window

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
