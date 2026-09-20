import SwiftUI

public struct OutlineSidebarView: View {
    let headings: [HeadingItem]
    let activeHeadingId: String?
    let onSelectHeading: (String) -> Void
    @ObservedObject var preferences: LucidPreferences
    @State private var searchText = ""
    @State private var isStatsPopoverPresented = false

    // Contextual stats
    var wordCount: Int = 0
    var charCount: Int = 0
    var readingTimeMinutes: Int = 1
    /// Space reserved above the sidebar header so its search field clears the
    /// floating glass toolbar, while the sidebar material runs continuously behind it.
    var topInset: CGFloat = 0

    public init(
        headings: [HeadingItem],
        activeHeadingId: String? = nil,
        preferences: LucidPreferences = .shared,
        wordCount: Int = 0,
        charCount: Int = 0,
        readingTimeMinutes: Int = 1,
        topInset: CGFloat = 0,
        onSelectHeading: @escaping (String) -> Void
    ) {
        self.headings = headings
        self.activeHeadingId = activeHeadingId
        self.preferences = preferences
        self.wordCount = wordCount
        self.charCount = charCount
        self.readingTimeMinutes = readingTimeMinutes
        self.topInset = topInset
        self.onSelectHeading = onSelectHeading
    }

    private var filteredHeadings: [HeadingItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return headings
        }
        return headings.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clearance for the floating glass toolbar; the recessed sidebar
            // material continues behind it for a single, layered surface.
            if topInset > 0 {
                Color.clear.frame(height: topInset)
            }

            // Search Bar & Contextual Stats Button
            HStack(spacing: LucidSpacing.xSmall) {
                LucidSearchField(
                    placeholder: "Filter outline…",
                    text: $searchText,
                    height: 26,
                    fontSize: 11
                )

                // Subtle contextual stats affordance
                LucidIconButton(
                    icon: "chart.bar",
                    size: 26,
                    iconSize: 11,
                    helpText: "Document Statistics"
                ) {
                    isStatsPopoverPresented.toggle()
                }
                .popover(isPresented: $isStatsPopoverPresented, arrowEdge: .bottom) {
                    LucidPopoverContainer {
                        VStack(alignment: .leading, spacing: LucidSpacing.small) {
                            Text("Document Statistics")
                                .font(LucidTypography.labelMedium)
                                .foregroundColor(LucidColors.textPrimary)

                            LucidDivider()

                            VStack(spacing: 5) {
                                HStack {
                                    Text("Words:").foregroundColor(LucidColors.textSecondary)
                                    Spacer()
                                    Text("\(wordCount.formatted())").monospacedDigit()
                                        .foregroundColor(LucidColors.textPrimary)
                                }
                                HStack {
                                    Text("Characters:").foregroundColor(LucidColors.textSecondary)
                                    Spacer()
                                    Text("\(charCount.formatted())").monospacedDigit()
                                        .foregroundColor(LucidColors.textPrimary)
                                }
                                HStack {
                                    Text("Reading Time:").foregroundColor(LucidColors.textSecondary)
                                    Spacer()
                                    Text("\(readingTimeMinutes) min")
                                        .foregroundColor(LucidColors.textPrimary)
                                }
                                HStack {
                                    Text("Headings:").foregroundColor(LucidColors.textSecondary)
                                    Spacer()
                                    Text("\(headings.count)").monospacedDigit()
                                        .foregroundColor(LucidColors.textPrimary)
                                }
                            }
                            .font(LucidTypography.metadata)
                        }
                        .frame(width: 190)
                    }
                }
            }
            .padding(.horizontal, LucidSpacing.medium)
            .padding(.vertical, LucidSpacing.small)

            LucidDivider()

            // Outline list
            if filteredHeadings.isEmpty {
                LucidEmptyState(
                    icon: "list.bullet.indent",
                    title: headings.isEmpty ? "No Headings" : "No Matches",
                    subtitle: headings.isEmpty ? "Headings will appear here as you write." : "Try a different search query."
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(filteredHeadings) { heading in
                        let isActive = heading.id == activeHeadingId
                        LucidSidebarRow(
                            title: heading.text,
                            level: heading.level,
                            isActive: isActive
                        ) {
                            onSelectHeading(heading.id)
                        }
                        .frame(height: preferences.density.sidebarRowHeight)
                        .id(heading.id)
                    }
                    .listStyle(.sidebar)
                    .onChange(of: activeHeadingId) { _, newId in
                        if let id = newId {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
        .background(
            LucidVisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
}
