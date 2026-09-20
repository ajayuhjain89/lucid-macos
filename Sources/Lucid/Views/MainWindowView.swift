import SwiftUI
import WebKit

public struct MainWindowView: View {
    @Binding var document: LucidDocument
    var fileURL: URL?

    @StateObject private var preferences = LucidPreferences.shared
    @State private var headings: [HeadingItem] = []
    @State private var activeHeading: HeadingItem?
    @State private var scrollToHeadingId: String?
    @State private var editorScrollFraction: Double = 0
    @State private var previewTargetFraction: Double?
    @State private var webViewInstance: WKWebView?
    @State private var fileWatcher: FileWatcher?

    // Find & Command Palette
    @State private var isFindBarPresented: Bool = false
    @State private var isCommandPalettePresented: Bool = false
    @State private var findMatchCount: Int = 0
    @State private var findCurrentIndex: Int = 0
    @State private var navigationHistory: [String] = []
    @State private var historyIndex: Int = -1

    private var wordCount: Int {
        let words = document.text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    private var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    public init(document: Binding<LucidDocument>, fileURL: URL? = nil) {
        self._document = document
        self.fileURL = fileURL
    }

    public var body: some View {
        ZStack {
            HSplitView {
                // Outline Sidebar
                if preferences.showOutline {
                    OutlineSidebarView(
                        headings: headings,
                        activeHeadingId: activeHeading?.id
                    ) { id in
                        navigateToHeading(id)
                    }
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
                }

                // Main Content Area (Clean edge-to-edge)
                ZStack(alignment: .topTrailing) {
                    Group {
                        switch preferences.viewMode {
                        case .reader:
                            PreviewWebView(
                                preferences: preferences,
                                markdown: document.text,
                                headings: $headings,
                                activeHeading: $activeHeading,
                                onScrollFractionChanged: nil,
                                onFindMatchesChanged: { count, index in
                                    findMatchCount = count
                                    findCurrentIndex = index
                                },
                                onContentEdited: { newMarkdown in
                                    document.text = newMarkdown
                                },
                                scrollToHeadingId: scrollToHeadingId,
                                webViewInstance: $webViewInstance
                            )
                        case .split:
                            HSplitView {
                                EditorView(
                                    text: $document.text,
                                    onScrollFractionChanged: { fraction in
                                        previewTargetFraction = fraction
                                    }
                                )
                                .frame(minWidth: 260)

                                PreviewWebView(
                                    preferences: preferences,
                                    markdown: document.text,
                                    headings: $headings,
                                    activeHeading: $activeHeading,
                                    onScrollFractionChanged: nil,
                                    onFindMatchesChanged: { count, index in
                                        findMatchCount = count
                                        findCurrentIndex = index
                                    },
                                    onContentEdited: { newMarkdown in
                                        document.text = newMarkdown
                                    },
                                    scrollToHeadingId: scrollToHeadingId,
                                    targetScrollFraction: previewTargetFraction,
                                    webViewInstance: $webViewInstance
                                )
                                .frame(minWidth: 260)
                            }
                        case .editor:
                            EditorView(text: $document.text)
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

                    // Floating Find Bar
                    if isFindBarPresented {
                        FindBarView(
                            isPresented: $isFindBarPresented,
                            webView: webViewInstance
                        )
                        .padding([.top, .trailing], 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                // Inspector Sidebar
                if preferences.showInspector {
                    InspectorView(preferences: preferences)
                        .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
                }
            }

            // Command Palette Modal Overlay
            if isCommandPalettePresented {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isCommandPalettePresented = false
                    }

                CommandPaletteView(
                    isPresented: $isCommandPalettePresented,
                    preferences: preferences,
                    webView: webViewInstance,
                    onExportPDF: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportPDF(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    },
                    onExportHTML: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportHTML(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    },
                    onCopyRichText: {
                        if let webView = webViewInstance {
                            ExportService.shared.copyRichText(webView: webView)
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .toolbar {
            // Outline Toggle
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation { preferences.showOutline.toggle() }
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Outline (⌘⌥T)")
            }

            // History Navigation
            ToolbarItemGroup(placement: .navigation) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(historyIndex <= 0)
                .help("Back (⌘[)")
                .keyboardShortcut("[", modifiers: .command)

                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                }
                .disabled(historyIndex >= navigationHistory.count - 1)
                .help("Forward (⌘])")
                .keyboardShortcut("]", modifiers: .command)
            }

            // View Mode Selector
            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $preferences.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Document Stats
            ToolbarItem(placement: .status) {
                Text("\(wordCount) words · \(readingTimeMinutes) min read")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Primary Actions Group
            ToolbarItemGroup(placement: .primaryAction) {
                // Command Palette Button (⌘K)
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isCommandPalettePresented.toggle()
                    }
                }) {
                    Image(systemName: "command")
                }
                .help("Command Palette (⌘K)")
                .keyboardShortcut("k", modifiers: .command)

                // Focus Mode Toggle (⌘⇧D)
                Button(action: {
                    preferences.focusMode.toggle()
                }) {
                    Image(systemName: preferences.focusMode ? "scope" : "circle.dashed")
                        .foregroundColor(preferences.focusMode ? .accentColor : .secondary)
                }
                .help("Toggle Focus Mode (⌘⇧D)")
                .keyboardShortcut("d", modifiers: [.command, .shift])

                // Typewriter Mode Toggle (⌘⇧T)
                Button(action: {
                    preferences.typewriterMode.toggle()
                }) {
                    Image(systemName: preferences.typewriterMode ? "text.aligncenter" : "text.alignleft")
                        .foregroundColor(preferences.typewriterMode ? .accentColor : .secondary)
                }
                .help("Toggle Typewriter Mode (⌘⇧T)")
                .keyboardShortcut("t", modifiers: [.command, .shift])

                // Click-to-Edit Mode Indicator & Toggle
                Button(action: {
                    preferences.clickToEdit.toggle()
                }) {
                    Image(systemName: preferences.clickToEdit ? "pencil.circle.fill" : "pencil.circle")
                        .foregroundColor(preferences.clickToEdit ? .accentColor : .secondary)
                }
                .help(preferences.clickToEdit ? "In-Place Live Editing Enabled (Click any text to edit)" : "Click to Enable In-Place Editing")

                // Find in Document (⌘F)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFindBarPresented.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                }
                .help("Find in Document (⌘F)")
                .keyboardShortcut("f", modifiers: .command)

                // Export Menu
                Menu {
                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportPDF(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    }) {
                        Label("Export as PDF…", systemImage: "arrow.down.doc")
                    }

                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportHTML(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    }) {
                        Label("Export Standalone HTML…", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Divider()

                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.copyRichText(webView: webView)
                        }
                    }) {
                        Label("Copy Formatted Rich Text", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export Document")

                // Settings Button (⌘,)
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gearshape")
                }
                .help("Settings (⌘,)")
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .onAppear {
            setupFileWatcher()
        }
    }

    private func navigateToHeading(_ id: String) {
        scrollToHeadingId = id
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(historyIndex + 1))
        }
        navigationHistory.append(id)
        historyIndex = navigationHistory.count - 1
    }

    private func goBack() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        scrollToHeadingId = navigationHistory[historyIndex]
    }

    private func goForward() {
        guard historyIndex < navigationHistory.count - 1 else { return }
        historyIndex += 1
        scrollToHeadingId = navigationHistory[historyIndex]
    }

    private func setupFileWatcher() {
        guard let url = fileURL else { return }
        fileWatcher = FileWatcher(url: url) {
            if let updatedText = try? String(contentsOf: url, encoding: .utf8),
               updatedText != document.text {
                DispatchQueue.main.async {
                    self.document.text = updatedText
                }
            }
        }
    }
}
