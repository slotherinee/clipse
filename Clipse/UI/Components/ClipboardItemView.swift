import SwiftUI
import AppKit

struct ClipboardItemView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onDoubleTap: ((ClipboardItem) -> Void)?
    let onSelect: ((Int) -> Void)?
    let onShowDetail: ((ClipboardItem) -> Void)?

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // Left accent bar for selected state (Raycast-style)
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 3, height: 28)
                .animation(.easeOut(duration: 0.1), value: isSelected)

            typeIcon.frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                contentView
                metaRow
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Text(index < 9 ? "\(index + 1)" : "")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(width: 14, alignment: .trailing)

                Button {
                    onShowDetail?(item)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isHovered || isSelected ? Color.secondary : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 7)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeOut(duration: 0.08), value: isSelected)
        .onHover { isHovered = $0 }
        .gesture(
            TapGesture(count: 2).onEnded { onDoubleTap?(item) }
                .exclusively(before: TapGesture(count: 1).onEnded { onSelect?(index) })
        )
    }

    // MARK: - Content

    @ViewBuilder private var contentView: some View {
        switch item.type {
        case .url:
            Text(domain(item.content))
                .lineLimit(1)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        case .code:
            Text(SyntaxHighlighter.highlight(item.content, dark: colorScheme == .dark, fontSize: 12))
                .lineLimit(2)
        case .image:
            imageThumbnail
        case .text:
            Text(item.content)
                .lineLimit(2)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder private var imageThumbnail: some View {
        let nsImage: NSImage? = {
            if let path = item.imageFilePath { return NSImage(contentsOfFile: path) }
            if let data = item.imageData     { return NSImage(data: data) }
            return nil
        }()
        if let img = nsImage {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Label(item.imageFilePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "[Image]",
                  systemImage: "photo")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 4) {
            if let id = item.sourceBundleID {
                AppIconView(bundleID: id)
            }
            Text(relativeTime(item.timestamp))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected
                ? Color.primary.opacity(0.08)
                : isHovered ? Color.primary.opacity(0.04) : Color.clear)
            .animation(.easeOut(duration: 0.05), value: isHovered)
    }

    private var typeIcon: some View {
        Group {
            switch item.type {
            case .url:   Image(systemName: "link")
            case .code:  Image(systemName: "chevron.left.forwardslash.chevron.right")
            case .image: Image(systemName: "photo")
            case .text:  Image(systemName: "doc.text")
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(isSelected ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.6))
    }

    private func domain(_ url: String) -> String {
        var s = url
        if s.hasPrefix("https://") { s = String(s.dropFirst(8)) }
        else if s.hasPrefix("http://") { s = String(s.dropFirst(7)) }
        return String(s.prefix(while: { $0 != "/" && $0 != "?" && $0 != "#" }))
    }

    private func relativeTime(_ date: Date) -> String {
        let s = -date.timeIntervalSinceNow
        if s < 60    { return "just now" }
        if s < 3600  { return "\(Int(s / 60))m ago" }
        if s < 86400 { return "\(Int(s / 3600))h ago" }
        return "\(Int(s / 86400))d ago"
    }
}
