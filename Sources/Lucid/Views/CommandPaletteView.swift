import SwiftUI
import WebKit

public struct CommandPaletteItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let shortcut: String?
    public let category: String
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String,
        icon: String,
        shortcut: String? = nil,
        category: String = "Actions",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
        self.category = category
        self.action = action
    }
}

public struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @ObservedObject var preferences: LucidPreferences
    @ObservedObject var viewState: WindowViewState
    var webView: WKWebView?
    var onInsertSnippet: (String) -> Void
    var onExportPDF: () -> Void
    var onExportHTML: () -> Void
    var onCopyRichText: () -> Void

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var items: [CommandPaletteItem] {
        var list: [CommandPaletteItem] = []
        let reg = LucidCommandRegistry.shared

        func sc(_ id: LucidCommandID) -> String? {
            reg.metadata(for: id)?.shortcutDisplayString
        }

        // 1. Canonical View & Mode commands
        list.append(CommandPaletteItem(
            title: "Reader Mode",
            subtitle: "Clean, distraction-free reading canvas",
            icon: "book",
            shortcut: sc(.viewModeReader),
            category: "View"
        ) { viewState.viewMode = .reader })

        list.append(CommandPaletteItem(
            title: "Split Mode",
            subtitle: "Side-by-side Markdown source and rendered preview",
            icon: "rectangle.split.2x1",
            shortcut: sc(.viewModeSplit),
            category: "View"
        ) { viewState.viewMode = .split })

        list.append(CommandPaletteItem(
            title: "Editor Mode",
            subtitle: "Focused source text editor",
            icon: "pencil",
            shortcut: sc(.viewModeEditor),
            category: "View"
        ) { viewState.viewMode = .editor })

        list.append(CommandPaletteItem(
            title: "Toggle Focus Mode",
            subtitle: "Dim inactive paragraphs to concentrate on the active block",
            icon: "scope",
            shortcut: sc(.toggleFocusMode),
            category: "View"
        ) { viewState.focusMode.toggle() })

        list.append(CommandPaletteItem(
            title: "Toggle Typewriter Mode",
            subtitle: "Keep active typing line vertically centered",
            icon: "text.aligncenter",
            shortcut: sc(.toggleTypewriterMode),
            category: "View"
        ) { preferences.typewriterMode.toggle() })

        list.append(CommandPaletteItem(
            title: "Toggle Sidebar",
            subtitle: "Show or hide the outline navigation sidebar",
            icon: "sidebar.leading",
            shortcut: sc(.toggleSidebar),
            category: "View"
        ) { viewState.showOutline.toggle() })

        list.append(CommandPaletteItem(
            title: "Toggle Status Bar",
            subtitle: "Show or hide bottom document metrics",
            icon: "menubar.dock.rectangle",
            shortcut: sc(.toggleStatusBar),
            category: "View"
        ) { preferences.showStatusBar.toggle() })

        // 2. Find & Edit commands
        list.append(CommandPaletteItem(
            title: "Find in Document…",
            subtitle: "Search text within the current document",
            icon: "magnifyingglass",
            shortcut: sc(.findInDocument),
            category: "Edit"
        ) { NotificationCenter.default.post(name: NSNotification.Name("LucidToggleFind"), object: nil) })

        list.append(CommandPaletteItem(
            title: "Find Next",
            subtitle: "Jump to the next search match",
            icon: "chevron.down",
            shortcut: sc(.findNext),
            category: "Edit"
        ) { NotificationCenter.default.post(name: NSNotification.Name("LucidFindNext"), object: nil) })

        list.append(CommandPaletteItem(
            title: "Find Previous",
            subtitle: "Jump to the previous search match",
            icon: "chevron.up",
            shortcut: sc(.findPrevious),
            category: "Edit"
        ) { NotificationCenter.default.post(name: NSNotification.Name("LucidFindPrevious"), object: nil) })

        // 3. Presets
        for preset in LucidPreset.allCases {
            list.append(CommandPaletteItem(
                title: "Apply Preset: \(preset.displayName)",
                subtitle: preset.description,
                icon: "slider.horizontal.3",
                category: "Presets"
            ) { preferences.applyPreset(preset) })
        }

        // 4. Curated Themes
        for theme in ThemeMode.curatedThemes {
            list.append(CommandPaletteItem(
                title: "Theme: \(theme.displayName)",
                subtitle: "Switch color appearance",
                icon: "paintpalette",
                category: "Theme"
            ) { preferences.theme = theme })
        }

        // 5. Insert Templates
        list.append(CommandPaletteItem(
            title: "Insert Table",
            subtitle: "Insert formatted 3-column Markdown table",
            icon: "tablecells",
            category: "Insert"
        ) { onInsertSnippet("table") })

        list.append(CommandPaletteItem(
            title: "Insert Math Equation",
            subtitle: "Insert KaTeX display formula block",
            icon: "function",
            category: "Insert"
        ) { onInsertSnippet("math") })

        list.append(CommandPaletteItem(
            title: "Insert Chemistry Reaction",
            subtitle: "Insert mhchem reaction formula",
            icon: "atom",
            category: "Insert"
        ) { onInsertSnippet("chemistry") })

        list.append(CommandPaletteItem(
            title: "Insert Mermaid Diagram",
            subtitle: "Insert flowchart architecture diagram",
            icon: "chart.bar.doc.horizontal",
            category: "Insert"
        ) { onInsertSnippet("mermaid") })

        // 6. File & Export
        list.append(CommandPaletteItem(
            title: "Export as PDF…",
            subtitle: "Paginated vector PDF document",
            icon: "arrow.down.doc",
            shortcut: sc(.exportPDF),
            category: "File & Export"
        ) { onExportPDF() })

        list.append(CommandPaletteItem(
            title: "Export as Standalone HTML…",
            subtitle: "Self-contained HTML file with embedded styles",
            icon: "chevron.left.forwardslash.chevron.right",
            shortcut: sc(.exportHTML),
            category: "File & Export"
        ) { onExportHTML() })

        list.append(CommandPaletteItem(
            title: "Copy Formatted Rich Text",
            subtitle: "Copy formatted content to system clipboard",
            icon: "doc.on.doc",
            shortcut: sc(.copyRichText),
            category: "File & Export"
        ) { onCopyRichText() })

        // 7. Application
        list.append(CommandPaletteItem(
            title: "Settings…",
            subtitle: "Open Lucid Preferences",
            icon: "gearshape",
            shortcut: sc(.openSettings),
            category: "Application"
        ) { SettingsWindowManager.shared.showSettings(preferences: preferences) })

        return list
    }

    private var filteredItems: [CommandPaletteItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        }
        let query = searchText.lowercased()
        return items.filter {
            $0.title.lowercased().contains(query) ||
            $0.subtitle.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Bar
            HStack(spacing: LucidSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(LucidColors.textSecondary)
                    .font(.system(size: 14, weight: .medium))

                TextField("Type a command or search…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isSearchFocused)
                    .onSubmit {
                        executeSelected()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(LucidColors.textSecondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, LucidSpacing.large)
            .padding(.vertical, LucidSpacing.medium)
            .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.6))

            LucidDivider()

            // Results List
            if filteredItems.isEmpty {
                LucidEmptyState(
                    icon: "magnifyingglass",
                    title: "No Matching Commands",
                    subtitle: "Try searching with a different keyword."
                )
                .padding(.vertical, LucidSpacing.large)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                let isSelected = index == selectedIndex
                                Button(action: {
                                    item.action()
                                    isPresented = false
                                }) {
                                    HStack(spacing: LucidSpacing.medium) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(isSelected ? Color.accentColor : LucidColors.textSecondary)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(LucidTypography.labelMedium)
                                                .foregroundColor(LucidColors.textPrimary)
                                                .lineLimit(1)

                                            Text(item.subtitle)
                                                .font(LucidTypography.caption)
                                                .foregroundColor(LucidColors.textSecondary)
                                                .lineLimit(1)
                                        }

                                        Spacer(minLength: LucidSpacing.small)

                                        if let shortcut = item.shortcut {
                                            LucidShortcutBadge(shortcut, isSelected: isSelected)
                                        }
                                    }
                                    .padding(.horizontal, LucidSpacing.medium)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: LucidRadius.small)
                                            .fill(isSelected ? LucidColors.softSelection : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                                    .animation(LucidMotion.hover, value: isSelected)
                                }
                                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.98))
                                .id(index)
                                .onHover { hovering in
                                    if hovering { selectedIndex = index }
                                }
                            }
                        }
                        .padding(LucidSpacing.small)
                    }
                    .frame(maxHeight: 330)
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation(LucidMotion.hover) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 560)
        .background(
            LucidVisualEffectView(material: .menu, blendingMode: .withinWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: LucidRadius.surface))
        .overlay(
            RoundedRectangle(cornerRadius: LucidRadius.surface)
                .stroke(LucidColors.subtleBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private func moveSelection(by delta: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func executeSelected() {
        guard !filteredItems.isEmpty, selectedIndex < filteredItems.count else { return }
        filteredItems[selectedIndex].action()
        isPresented = false
    }
}
