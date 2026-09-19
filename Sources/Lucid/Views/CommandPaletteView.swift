import SwiftUI
import WebKit

public struct CommandAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let shortcut: String?
    public let action: () -> Void

    public init(title: String, subtitle: String, icon: String, shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
        self.action = action
    }
}

public struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @ObservedObject var preferences: LucidPreferences
    var webView: WKWebView?
    var onExportPDF: () -> Void
    var onExportHTML: () -> Void
    var onCopyRichText: () -> Void

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var actions: [CommandAction] {
        [
            // Modes
            CommandAction(title: "Toggle Focus Mode", subtitle: "Dim all paragraphs except the active one", icon: "scope", shortcut: "⌘⇧D") {
                preferences.focusMode.toggle()
            },
            CommandAction(title: "Toggle Typewriter Mode", subtitle: "Keep active typing line vertically centered", icon: "text.aligncenter", shortcut: "⌘⇧T") {
                preferences.typewriterMode.toggle()
            },
            CommandAction(title: "Toggle In-Place Live Editing", subtitle: "Click and edit anywhere while reading", icon: "pencil.circle") {
                preferences.clickToEdit.toggle()
            },
            CommandAction(title: "Reader Mode", subtitle: "Zero-chrome reading canvas", icon: "book", shortcut: "⌘1") {
                preferences.viewMode = .reader
            },
            CommandAction(title: "Split Mode", subtitle: "Side-by-side Markdown editor and preview", icon: "rectangle.split.2x1", shortcut: "⌘2") {
                preferences.viewMode = .split
            },
            CommandAction(title: "Editor Mode", subtitle: "Focused raw markdown editing", icon: "square.and.pencil", shortcut: "⌘3") {
                preferences.viewMode = .editor
            },
            CommandAction(title: "Toggle Table of Contents", subtitle: "Show or hide outline sidebar", icon: "sidebar.left", shortcut: "⌘⌥T") {
                preferences.showOutline.toggle()
            },

            // Insert Templates
            CommandAction(title: "Insert Table", subtitle: "Insert 3-column markdown table", icon: "tablecells") {
                webView?.evaluateJavaScript("window.lucid.insertTemplate('table')")
            },
            CommandAction(title: "Insert Math Equation", subtitle: "Insert KaTeX block formula", icon: "function") {
                webView?.evaluateJavaScript("window.lucid.insertTemplate('math')")
            },
            CommandAction(title: "Insert Chemistry Formula", subtitle: "Insert mhchem reaction formula", icon: "atom") {
                webView?.evaluateJavaScript("window.lucid.insertTemplate('chemistry')")
            },
            CommandAction(title: "Insert Mermaid Diagram", subtitle: "Insert flowchart template", icon: "chart.bar.doc.horizontal") {
                webView?.evaluateJavaScript("window.lucid.insertTemplate('mermaid')")
            },

            // Themes
            CommandAction(title: "Theme: Lucid Studio Dark", subtitle: "Signature #171717 calibrated graphite", icon: "circle.lefthalf.filled") {
                preferences.theme = .dark
            },
            CommandAction(title: "Theme: Pure White", subtitle: "Clean, high-contrast daylight theme", icon: "sun.max") {
                preferences.theme = .light
            },
            CommandAction(title: "Theme: Warm Book Sepia", subtitle: "Relaxing paper tone for long reading sessions", icon: "book.closed") {
                preferences.theme = .sepia
            },
            CommandAction(title: "Theme: OLED Pure Black", subtitle: "True zero-emission deep black", icon: "moon.stars") {
                preferences.theme = .oled
            },
            CommandAction(title: "Theme: Nord Arctic", subtitle: "Elegant cool frost palette", icon: "snowflake") {
                preferences.theme = .nord
            },
            CommandAction(title: "Theme: Dracula", subtitle: "Vibrant developer dark theme", icon: "flame") {
                preferences.theme = .dracula
            },

            // Export
            CommandAction(title: "Export as PDF…", subtitle: "Vector paginated PDF document", icon: "arrow.down.doc", shortcut: "⌘P") {
                onExportPDF()
            },
            CommandAction(title: "Export Standalone HTML…", subtitle: "Self-contained offline webpage", icon: "chevron.left.forwardslash.chevron.right", shortcut: "⌘E") {
                onExportHTML()
            },
            CommandAction(title: "Copy Formatted Rich Text", subtitle: "Copy formatted text to clipboard", icon: "doc.on.doc", shortcut: "⌥⌘C") {
                onCopyRichText()
            },

            // Settings
            CommandAction(title: "Preferences / Settings…", subtitle: "Open Lucid Settings window", icon: "gearshape", shortcut: "⌘,") {
                SettingsWindowManager.shared.showSettings(preferences: preferences)
            }
        ]
    }

    private var filteredActions: [CommandAction] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return actions
        }
        return actions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.title3)

                TextField("Type a command or search…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular))
                    .focused($isSearchFocused)
                    .onSubmit {
                        executeSelected()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))

            Divider()

            // Action list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                            let isSelected = index == selectedIndex
                            HStack(spacing: 12) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(isSelected ? .white : .accentColor)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(isSelected ? .white : .primary)

                                    Text(action.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : .secondary)
                                }

                                Spacer()

                                if let shortcut = action.shortcut {
                                    Text(shortcut)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : .secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(isSelected ? Color.white.opacity(0.2) : Color(NSColor.separatorColor).opacity(0.3))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.accentColor : Color.clear)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                action.action()
                                isPresented = false
                            }
                            .id(index)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 340)
            }
        }
        .frame(width: 540)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
    }

    private func executeSelected() {
        guard !filteredActions.isEmpty, selectedIndex < filteredActions.count else { return }
        filteredActions[selectedIndex].action()
        isPresented = false
    }
}
