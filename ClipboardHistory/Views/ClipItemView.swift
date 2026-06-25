import SwiftUI

struct ClipItemView: View {
    let item: ClipItem
    let index: Int
    let isHovered: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                indexBadge
                itemContent
                Spacer(minLength: 4)
                if isHovered {
                    deleteButton
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                    .padding(.horizontal, 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var indexBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.controlBackgroundColor))
                .frame(width: 28, height: 22)
            Text(index < 9 ? "\(index + 1)" : "•")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var itemContent: some View {
        switch item.content {
        case .text(let text):
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .lineLimit(2)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                if text.count > 80 {
                    Text("\(text.count) karakter")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .image(let img):
            HStack(spacing: 10) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Görsel")
                        .font(.system(size: 13, weight: .medium))
                    Text("\(Int(img.size.width))×\(Int(img.size.height))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color(.controlBackgroundColor)))
        }
        .buttonStyle(.plain)
    }
}
