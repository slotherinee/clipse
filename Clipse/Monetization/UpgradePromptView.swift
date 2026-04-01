import SwiftUI

enum UpgradeReason {
    case historyLimit
    case pin
    case images

    var message: String {
        switch self {
        case .historyLimit: return "Clipboard limit reached. Unlock unlimited history."
        case .pin:          return "Pin items with Clipse Pro."
        case .images:       return "Image history requires Clipse Pro."
        }
    }
}

struct UpgradePromptView: View {
    let reason: UpgradeReason
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))

            Text(reason.message)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Button("Unlock Pro") {
                // StoreKit purchase — Stage 16
                LicenseManager.shared.unlock()
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.orange)

            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.08))
    }
}
