import SwiftUI

public struct BreadcrumbBarView: View {
    let documentName: String
    let activeHeading: HeadingItem?
    let onSelectHeading: (String) -> Void

    public init(documentName: String, activeHeading: HeadingItem?, onSelectHeading: @escaping (String) -> Void) {
        self.documentName = documentName
        self.activeHeading = activeHeading
        self.onSelectHeading = onSelectHeading
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
                .font(.caption)

            Text(documentName)
                .font(.caption)
                .foregroundColor(.secondary)

            if let heading = activeHeading, !heading.text.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))

                Button(action: {
                    onSelectHeading(heading.id)
                }) {
                    Text(heading.text)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}
