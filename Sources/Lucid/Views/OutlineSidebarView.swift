import SwiftUI

public struct SidebarWidthPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 220
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    var trafficLightWidth: CGFloat = 77
    var onToggleSidebar: (() -> Void)? = nil

    public init(
        headings: [HeadingItem],
        activeHeadingId: String? = nil,
        preferences: LucidPreferences = .shared,
        wordCount: Int = 0,
        charCount: Int = 0,
        readingTimeMinutes: Int = 1,
        trafficLightWidth: CGFloat = 77,
        onToggleSidebar: (() -> Void)? = nil,
        onSelectHeading: @escaping (String) -> Void
    ) {
        self.headings = headings
        self.activeHeadingId = activeHeadingId
        self.preferences = preferences
        self.wordCount = wordCount
        self.charCount = charCount
        self.readingTimeMinutes = readingTimeMinutes
        self.trafficLightWidth = trafficLightWidth
        self.onToggleSidebar = onToggleSidebar
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
            // Top titlebar row: Aligned with the document top chrome
            HStack(spacing: LucidSpacing.small) {
                Color.clear
                    .frame(width: trafficLightWidth, height: 1)
                    .allowsHitTesting(false)

                if let onToggle = onToggleSidebar {
                    LucidIconButton(
                        icon: "sidebar.leading",
                        size: 26,
                        iconSize: 13,
                        isActive: true,
                        helpText: "Toggle Outline Sidebar",
                        shortcutText: "⌃⌘S"
                    ) {
                        onToggle()
                    }
                }

                LucidWindowDragArea()
            }
            .frame(height: LucidChrome.toolbarHeight)

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
                let hasContent = wordCount > 0 || charCount > 0
                let isSearching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let emptyTitle = isSearching ? "No Matches" : (hasContent ? "No Headings" : "No Content")
                let emptySubtitle = isSearching
                    ? "Try a different search query."
                    : (hasContent ? "No Markdown headings found in this document." : "Open or write Markdown to view outline.")

                LucidEmptyState(
                    icon: isSearching ? "magnifyingglass" : "list.bullet.indent",
                    title: emptyTitle,
                    subtitle: emptySubtitle
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
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 320)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: SidebarWidthPreferenceKey.self, value: geo.size.width)
            }
        )
        .background(
            ZStack {
                LucidVisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                Color(hex: preferences.theme.themeTokens.sidebarBackground).opacity(0.85)
            }
            .ignoresSafeArea()
        )
        .ignoresSafeArea()
    }
}
