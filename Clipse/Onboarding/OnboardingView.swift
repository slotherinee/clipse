import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            stepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step) // forces transition on step change
        }
        .animation(.easeInOut(duration: 0.2), value: step)
        .frame(width: 460, height: 280)
        .padding(32)
    }

    @ViewBuilder private var stepView: some View {
        switch step {
        case 0: welcomeStep
        case 1: accessibilityStep
        case 2: hotkeyStep
        default: doneStep
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.on.clipboard").font(.system(size: 44)).foregroundStyle(Color.accentColor)
            Text("Welcome to Clipse").font(.title.bold())
            Text("Everything you copy. Instantly.").foregroundStyle(.secondary)
            Spacer()
            primaryButton("Get Started") { step += 1 }
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "hand.raised.fill").font(.system(size: 44)).foregroundStyle(.orange)
            Text("Grant Accessibility Access").font(.title2.bold())
            Text("Required to paste text into other apps.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 12) {
                Button("Open System Settings") { PermissionsManager.requestAccessibility() }
                    .buttonStyle(.borderedProminent)
                Button(PermissionsManager.isAccessibilityGranted ? "Continue ✓" : "Skip for now") { step += 1 }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var hotkeyStep: some View {
        VStack(spacing: 14) {
            HotkeyDemoView()
            Text("Press Cmd+Shift+V anywhere").font(.title2.bold())
            Text("Opens Clipse instantly from any app.").foregroundStyle(.secondary)
            Spacer()
            primaryButton("Let's go") { step += 1 }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(.green)
            Text("You're all set!").font(.title.bold())
            Text("Copy something and press Cmd+Shift+V.").foregroundStyle(.secondary)
            Spacer()
            primaryButton("Start Using Clipse") { onComplete() }
        }
    }

    // MARK: - Helpers

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

// Pulsing key badge animation — created once, no per-frame allocations
struct HotkeyDemoView: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            keyBadge("⌘"); keyBadge("⇧"); keyBadge("V")
        }
        .scaleEffect(pulse ? 1.08 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
