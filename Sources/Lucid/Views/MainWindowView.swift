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
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Main Document Work Area
                HSplitView {
                    // Outline Sidebar
                    if preferences.showOutline {
                        OutlineSidebarView(
                            headings: headings,
                            activeHeadingId: activeHeading?.id
                        ) { id in
                            navigateToHeading(id)
                        }
                        .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)
                        .padding(.top, 28)
                    }

                    // Main Content Area (Clean edge-to-edge canvas)
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
                        .padding(.top, 28)

                        // Floating Find Bar
                        if isFindBarPresented {
                            FindBarView(
                                isPresented: $isFindBarPresented,
                                webView: webViewInstance
                            )
                            .padding([.top, .trailing], 36)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    // Inspector Sidebar
                    if preferences.showInspector {
                        InspectorView(preferences: preferences)
                            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
                            .padding(.top, 28)
                    }
                }

                // Sleek Typora-Style Bottom Status Bar (No Top Bar!)
                HStack(spacing: 12) {
                    // Left Controls: Outline & View Modes
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                preferences.showOutline.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 12))
                                .foregroundColor(preferences.showOutline ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle Outline (⌘⌥T)")

                        Divider()
                            .frame(height: 12)

                        // View Mode Switcher
                        HStack(spacing: 2) {
                            Button(action: { preferences.viewMode = .reader }) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(preferences.viewMode == .reader ? .accentColor : .secondary)
                                    .padding(4)
                                    .background(preferences.viewMode == .reader ? Color.accentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("Reader Mode (⌘1)")

                            Button(action: { preferences.viewMode = .split }) {
                                Image(systemName: "rectangle.split.2x1")
                                    .font(.system(size: 11))
                                    .foregroundColor(preferences.viewMode == .split ? .accentColor : .secondary)
                                    .padding(4)
                                    .background(preferences.viewMode == .split ? Color.accentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("Split Mode (⌘2)")

                            Button(action: { preferences.viewMode = .editor }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundColor(preferences.viewMode == .editor ? .accentColor : .secondary)
                                    .padding(4)
                                    .background(preferences.viewMode == .editor ? Color.accentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("Source Editor (⌘3)")
                        }

                        Divider()
                            .frame(height: 12)

                        // In-Place Edit Indicator & Toggle
                        Button(action: {
                            preferences.clickToEdit.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: preferences.clickToEdit ? "pencil.circle.fill" : "pencil.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(preferences.clickToEdit ? .accentColor : .secondary)
                                Text(preferences.clickToEdit ? "Live Edit" : "Read Only")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(preferences.clickToEdit ? .accentColor : .secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(preferences.clickToEdit ? Color.accentColor.opacity(0.12) : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle In-Place Editing (Click any text to edit)")

                        // Focus Mode
                        Button(action: { preferences.focusMode.toggle() }) {
                            Image(systemName: preferences.focusMode ? "scope" : "circle.dashed")
                                .font(.system(size: 11))
                                .foregroundColor(preferences.focusMode ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Focus Mode (⌘⇧D)")

                        // Typewriter Mode
                        Button(action: { preferences.typewriterMode.toggle() }) {
                            Image(systemName: preferences.typewriterMode ? "text.aligncenter" : "text.alignleft")
                                .font(.system(size: 11))
                                .foregroundColor(preferences.typewriterMode ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Typewriter Mode (⌘⇧T)")
                    }

                    Spacer()

                    // Right Controls: Document Stats & Quick Actions
                    HStack(spacing: 10) {
                        // Word Count & Reading Time Pill (Spacious, NEVER overflows)
                        HStack(spacing: 6) {
                            Text("\(wordCount.formatted()) words")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                            Text("·")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(readingTimeMinutes) min read")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .fixedSize(horizontal: true, vertical: false)

                        // Command Palette (⌘K)
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isCommandPalettePresented.toggle()
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "command")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("K")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Command Palette (⌘K)")

                        // Find (⌘F)
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isFindBarPresented.toggle()
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Find in Document (⌘F)")

                        // Settings (⌘,)
                        Button(action: {
                            SettingsWindowManager.shared.showSettings(preferences: preferences)
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Settings (⌘,)")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.92))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.white.opacity(0.08)),
                    alignment: .top
                )
            }

            // Command Palette Modal Overlay
            if isCommandPalettePresented {
                Color.black.opacity(0.4)
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
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }

            // Native Window Drag Area (Offset for traffic lights)
            WindowDragView()
                .frame(height: 28)
                .padding(.leading, 78)
                .edgesIgnoringSafeArea(.top)
        }
        // Keyboard Shortcuts
        .background(
            Group {
                Button("") {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isCommandPalettePresented.toggle()
                    }
                }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)

                Button("") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFindBarPresented.toggle()
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
            }
        )
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

// MARK: - Native Window Dragging Component
struct WindowDragView: NSViewRepresentable {
    func makeNSView(context: Context) -> DragNSView {
        DragNSView()
    }
    func updateNSView(_ nsView: DragNSView, context: Context) {}
}

final class DragNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.zoom(nil)
        } else {
            window?.performDrag(with: event)
        }
    }
}
