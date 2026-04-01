import SwiftUI
import AppKit

struct ClipboardItemView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onDoubleTap: ((ClipboardItem) -> Void)?
    let onSelect: ((Int) -> Void)?

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            typeIcon.frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                contentView
                metaRow
            }

            Spacer(minLength: 0)

            if item.pinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Text("\(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.quaternary)
                .frame(width: 14, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .opacity(isSelected ? 1.0 : 0.65)
        .shadow(color: .accentColor.opacity(isSelected ? 0.2 : 0), radius: 6, y: 2)
        .animation(.easeOut(duration: 0.08), value: isSelected)
        .onHover { isHovered = $0 }
        // Double-tap fires first (exclusively), then single-tap for select
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
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        case .code:
            Text(item.content)
                .lineLimit(2)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
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
        if let data = item.imageData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Text("[Image]").font(.system(size: 13)).foregroundStyle(.secondary)
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
                ? Color.accentColor.opacity(0.12)
                : isHovered ? Color.primary.opacity(0.05) : Color.clear)
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
        .foregroundStyle(.secondary)
    }

    // Strips scheme, returns bare domain — no URL(string:) allocation
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
