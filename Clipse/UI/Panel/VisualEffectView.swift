import SwiftUI
import AppKit

/// NSVisualEffectView обёртка — создаётся один раз, не пересоздаётся при re-render.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        switch context.environment.colorScheme {
        case .dark:  nsView.appearance = NSAppearance(named: .vibrantDark)
        case .light: nsView.appearance = NSAppearance(named: .aqua)
        @unknown default: nsView.appearance = nil
        }
    }
}
