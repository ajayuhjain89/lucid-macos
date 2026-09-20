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
        HStack(spacing: LucidSpacing.xSmall) {
            Image(systemName: "doc.text")
                .foregroundColor(LucidColors.textSecondary)
                .font(.system(size: 11, weight: .regular))

            Text(documentName)
                .font(LucidTypography.caption)
                .foregroundColor(LucidColors.textSecondary)

            if let heading = activeHeading, !heading.text.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(LucidColors.textTertiary)

                Button(action: {
                    onSelectHeading(heading.id)
                }) {
                    Text(heading.text)
                        .font(LucidTypography.labelMedium)
                        .foregroundColor(LucidColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, LucidSpacing.large)
        .padding(.vertical, LucidSpacing.controlInnerPadding)
        .background(.ultraThinMaterial)
        .overlay(
            LucidDivider(),
            alignment: .bottom
        )
    }
}
