import SwiftUI
import AppKit

struct ClipboardDetailView: View {
    let item: ClipboardItem
    let scrollCoordinator: DetailScrollCoordinator
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.12)
            contentArea
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            typeLabel

            Spacer()

            HStack(spacing: 6) {
                if let id = item.sourceBundleID { AppIconView(bundleID: id) }
                Text(fullTimestamp(item.timestamp))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder private var contentArea: some View {
        switch item.type {
        case .image:
            imageContent
        case .code:
            ScrollableTextView(
                attributedText: highlighted,
                coordinator: scrollCoordinator
            )
        default:
            ScrollableTextView(
                attributedText: plainText,
                coordinator: scrollCoordinator
            )
        }
    }

    private var highlighted: NSAttributedString {
        SyntaxHighlighter.highlightNS(item.content, dark: colorScheme == .dark, fontSize: 12)
    }

    private var plainText: NSAttributedString {
        NSAttributedString(
            string: item.content,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
        )
    }

    // MARK: - Image

    @ViewBuilder private var imageContent: some View {
        ScrollView {
            Group {
                if let path = item.imageFilePath, let img = NSImage(contentsOfFile: path) {
                    VStack(spacing: 8) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    .padding(14)
                } else if let data = item.imageData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(14)
                } else {
                    Text("Image not available")
                        .foregroundStyle(.secondary)
                        .padding(14)
                }
            }
        }
    }

    // MARK: - Helpers

    private var typeLabel: some View {
        let (icon, label): (String, String) = switch item.type {
        case .url:   ("link", "URL")
        case .code:  ("chevron.left.forwardslash.chevron.right", "Code")
        case .image: ("photo", item.imageFilePath != nil ? "Image (file)" : "Image")
        case .text:  ("doc.text", "Text")
        }
        return Label(label, systemImage: icon)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
    }

    private func fullTimestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}
