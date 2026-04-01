import AppKit
import SwiftUI

/// NSScrollView + NSTextView wrapper.
/// Exposes the inner NSScrollView to DetailScrollCoordinator for external scroll control.
struct ScrollableTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    let coordinator: DetailScrollCoordinator

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        configure(scrollView)
        coordinator.scrollView = scrollView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        // Only update storage if content changed — preserves scroll position
        if tv.attributedString() != attributedText {
            tv.textStorage?.setAttributedString(attributedText)
        }
        coordinator.scrollView = scrollView
    }

    private func configure(_ scrollView: NSScrollView) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 6, height: 6)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.scrollerStyle = .overlay
    }
}
