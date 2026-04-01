import SwiftUI

struct OnboardingView: View {
    var onAccessibilityGranted: () -> Void
    var onComplete: () -> Void

    @State private var step = 0
    @State private var axGranted = PermissionsManager.isAccessibilityGranted
    @State private var pollTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            stepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)
        }
        .animation(.easeInOut(duration: 0.22), value: step)
        .frame(width: 460, height: 280)
        .padding(32)
    }

    @ViewBuilder private var stepView: some View {
        switch step {
        case 0:  welcomeStep
        case 1:  accessibilityStep
        case 2:  hotkeyStep
        default: doneStep
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Welcome to Clipse").font(.title.bold())
            Text("Everything you copy. Instantly.").foregroundStyle(.secondary)
            Spacer()
            primaryButton("Get Started") { step += 1 }
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 14) {
            Image(systemName: axGranted ? "checkmark.shield.fill" : "hand.raised.fill")
                .font(.system(size: 44))
                .foregroundStyle(axGranted ? .green : .orange)
                .animation(.easeInOut(duration: 0.25), value: axGranted)

            Text("Accessibility Access").font(.title2.bold())
            Text("Required so Clipse can paste into other apps.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if axGranted {
                Label("Access granted!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 13, weight: .medium))
                    .transition(.opacity.combined(with: .scale))
            } else {
                Text("Waiting for permission in System Settings…")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !axGranted {
                Button("Open System Settings") { PermissionsManager.requestAccessibility() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    private var hotkeyStep: some View {
        VStack(spacing: 14) {
            HotkeyDemoView()
            Text("Press Cmd+Shift+V anywhere").font(.title2.bold())
            Text("Opens Clipse instantly from any app.")
                .foregroundStyle(.secondary)
            Spacer()
            primaryButton("Let's go") { step += 1 }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("You're all set!").font(.title.bold())
            Text("Copy something and press Cmd+Shift+V.")
                .foregroundStyle(.secondary)
            Spacer()
            primaryButton("Start Using Clipse") { onComplete() }
        }
    }

    // MARK: - Polling

    private func startPolling() {
        guard !axGranted else { advance(); return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            if PermissionsManager.isAccessibilityGranted {
                stopPolling()
                withAnimation { axGranted = true }
                onAccessibilityGranted()
                // Short pause so user sees "Access granted!" then auto-advance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advance() }
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func advance() { step += 1 }

    // MARK: - Helpers

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

struct HotkeyDemoView: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            keyBadge("⌘"); keyBadge("⇧"); keyBadge("V")
        }
        .scaleEffect(pulse ? 1.08 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                pulse = true
            }
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
