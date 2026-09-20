import SwiftUI
import WebKit
import AppKit

public struct MainWindowView: View {
    @Binding var document: LucidDocument
    var fileURL: URL?

    @StateObject private var preferences = LucidPreferences.shared
    @State private var headings: [HeadingItem] = []
    @State private var activeHeading: HeadingItem?
    @State private var scrollToHeadingId: String?
    @State private var previewTargetFraction: Double?
    @State private var webViewInstance: WKWebView?
    @State private var editorTextView: NSTextView?
    @State private var fileWatcher: FileWatcher?
    /// Graduated 0…1 depth of the content beneath the toolbar, driving the
    /// scroll-responsive glass almost subconsciously.
    @State private var scrollIntensity: Double = 0
    @Namespace private var modeSelectorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // Find & Command Palette
    @State private var isFindBarPresented: Bool = false
    @State private var isCommandPalettePresented: Bool = false
    @State private var findMatchCount: Int = 0
    @State private var findCurrentIndex: Int = 0

    // Cursor position for status bar
    @State private var cursorLine: Int = 1
    @State private var cursorCol: Int = 1

    // Whether the pointer is over the top chrome (used to gently reveal controls
    // when Focus Mode has quieted them).
    @State private var isToolbarHovered: Bool = false

    private var wordCount: Int {
        let words = document.text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    private var charCount: Int {
        document.text.count
    }

    private var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    private var documentTitle: String {
        fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
    }

    public init(document: Binding<LucidDocument>, fileURL: URL? = nil) {
        self._document = document
        self.fileURL = fileURL
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Content plane fills the whole window, edge to edge, so the document
            // scrolls beneath the floating glass toolbar rather than starting below
            // a reserved opaque band.
            VStack(spacing: 0) {
                HSplitView {
                    // Outline Sidebar — recessed material, content inset below the toolbar.
                    if preferences.showOutline {
                        OutlineSidebarView(
                            headings: headings,
                            activeHeadingId: activeHeading?.id,
                            preferences: preferences,
                            wordCount: wordCount,
                            charCount: charCount,
                            readingTimeMinutes: readingTimeMinutes,
                            topInset: LucidChrome.toolbarHeight
                        ) { id in
                            scrollToHeadingId = id
                        }
                        .frame(minWidth: 180, idealWidth: 220, maxWidth: 320)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Content Canvas
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
                                    scrollToHeadingId: scrollToHeadingId,
                                    webViewInstance: $webViewInstance,
                                    documentFileURL: fileURL,
                                    onScrollIntensityChanged: { scrollIntensity = $0 }
                                )
                                .transition(.opacity)
                            case .split:
                                HSplitView {
                                    EditorView(
                                        text: $document.text,
                                        preferences: preferences,
                                        onScrollFractionChanged: { fraction in
                                            previewTargetFraction = fraction
                                        },
                                        onCursorPositionChanged: { line, col in
                                            cursorLine = line
                                            cursorCol = col
                                        },
                                        onTextViewCreated: { editorTextView = $0 },
                                        onScrollIntensityChanged: { scrollIntensity = $0 }
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
                                        scrollToHeadingId: scrollToHeadingId,
                                        targetScrollFraction: previewTargetFraction,
                                        webViewInstance: $webViewInstance,
                                        documentFileURL: fileURL,
                                        onScrollIntensityChanged: { scrollIntensity = $0 }
                                    )
                                    .frame(minWidth: 260)
                                }
                                .transition(.opacity)
                            case .editor:
                                EditorView(
                                    text: $document.text,
                                    preferences: preferences,
                                    onCursorPositionChanged: { line, col in
                                        cursorLine = line
                                        cursorCol = col
                                    },
                                    onTextViewCreated: { editorTextView = $0 },
                                    onScrollIntensityChanged: { scrollIntensity = $0 }
                                )
                                .transition(.opacity)
                            }
                        }
                        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.viewMode)

                        // Floating Find Bar — aligned just below the glass toolbar.
                        if isFindBarPresented {
                            FindBarView(
                                isPresented: $isFindBarPresented,
                                webView: webViewInstance
                            )
                            .padding(.top, LucidChrome.toolbarHeight + LucidSpacing.small)
                            .padding(.trailing, LucidSpacing.large)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }

                // Minimal, Serene Status Bar
                if preferences.showStatusBar {
                    StatusBarView(
                        preferences: preferences,
                        wordCount: wordCount,
                        charCount: charCount,
                        readingTimeMinutes: readingTimeMinutes,
                        cursorLine: cursorLine,
                        cursorCol: cursorCol,
                        onOpenSettings: {
                            SettingsWindowManager.shared.showSettings(preferences: preferences)
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Floating glass top chrome, layered above the scrolling content.
            topBar

            // Command Palette Modal Overlay — a barely-there dim, not a heavy scrim.
            if isCommandPalettePresented {
                Color.black.opacity(0.05)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        dismissCommandPalette()
                    }

                CommandPaletteView(
                    isPresented: $isCommandPalettePresented,
                    preferences: preferences,
                    webView: webViewInstance,
                    onInsertSnippet: { type in
                        insertSnippet(type)
                    },
                    onExportPDF: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportPDF(
                                webView: webView,
                                defaultFilename: documentTitle
                            )
                        }
                    },
                    onExportHTML: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportHTML(
                                webView: webView,
                                defaultFilename: documentTitle
                            )
                        }
                    },
                    onCopyRichText: {
                        if let webView = webViewInstance {
                            ExportService.shared.copyRichText(webView: webView)
                        }
                    }
                )
                .padding(.top, LucidChrome.toolbarHeight + LucidSpacing.xxLarge)
                .transition(
                    reduceMotion
                        ? AnyTransition.opacity
                        : AnyTransition.opacity.combined(with: .offset(y: -6))
                )
            }
        }
        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.showOutline)
        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.showStatusBar)
        // Configure the window: hide the native title bar so our custom top bar
        // sits flush at the top, and keep it draggable.
        .background(WindowConfigurator())
        // Keyboard Shortcuts
        .background(
            Group {
                Button("") {
                    if isCommandPalettePresented { dismissCommandPalette() }
                    else { presentCommandPalette() }
                }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)

                Button("") {
                    withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
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

    private func presentCommandPalette() {
        withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
            isCommandPalettePresented = true
        }
    }

    private func dismissCommandPalette() {
        withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
            isCommandPalettePresented = false
        }
    }

    // MARK: - Custom Top Bar

    private var topBar: some View {
        ZStack {
            // Glass layer sits behind everything.
            topBarBackground

            // Empty regions of the bar drag the window.
            WindowDragArea()

            HStack(spacing: LucidSpacing.small) {
                // Leave room for the traffic lights.
                Color.clear.frame(width: 68, height: 1)

                LucidIconButton(
                    icon: "sidebar.leading",
                    size: 28,
                    iconSize: 13,
                    isActive: preferences.showOutline,
                    helpText: "Toggle Outline Sidebar",
                    shortcutText: "⌃⌘S"
                ) {
                    withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.panel)) {
                        preferences.showOutline.toggle()
                    }
                }

                Text(documentTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(LucidColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.leading, LucidSpacing.xxSmall)
                    .allowsHitTesting(false)

                Spacer(minLength: LucidSpacing.medium)

                modeSelector

                moreMenu
            }
            .padding(.horizontal, LucidSpacing.medium)
            .opacity(toolbarControlsOpacity)
            .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: isToolbarHovered)
            .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.focusMode)
        }
        .frame(height: LucidChrome.toolbarHeight)
        .frame(maxWidth: .infinity)
        .onHover { isToolbarHovered = $0 }
    }

    /// In Focus Mode the toolbar controls recede to keep the document dominant,
    /// then gently return to full presence when the pointer approaches the top.
    private var toolbarControlsOpacity: Double {
        guard preferences.focusMode else { return 1 }
        return isToolbarHovered ? 1 : 0.4
    }

    /// Near-transparent at the top of the document; as content travels beneath the
    /// controls a native vibrancy layer, a faint hairline, and a soft shadow fade
    /// in together for depth — the effect is meant to be felt, not noticed.
    private var topBarBackground: some View {
        ZStack(alignment: .bottom) {
            // `.withinWindow` so the glass frosts the document scrolling beneath it
            // (this same window), not the desktop behind the window.
            LucidVisualEffectView(material: .headerView, blendingMode: .withinWindow)
                .opacity(0.12 + 0.88 * scrollIntensity)

            Rectangle()
                .fill(LucidColors.subtleSeparator)
                .frame(height: 0.5)
                .opacity(scrollIntensity)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.10 * scrollIntensity), radius: 7, x: 0, y: 2)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.08), value: scrollIntensity)
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            ForEach([ViewMode.reader, ViewMode.split, ViewMode.editor], id: \.self) { mode in
                let isSelected = preferences.viewMode == mode
                Button(action: {
                    withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.state)) {
                        preferences.viewMode = mode
                    }
                }) {
                    Image(systemName: modeIcon(mode))
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .accentColor : LucidColors.textSecondary)
                        .frame(width: 34, height: 24)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.accentColor.opacity(0.16))
                                        .matchedGeometryEffect(id: "modePill", in: modeSelectorNamespace)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.9))
                .help(modeHelp(mode))
            }
        }
    }

    private var moreMenu: some View {
        Menu {
            Section("Focus & Modes") {
                Toggle("Focus Mode", isOn: $preferences.focusMode)
                Toggle("Typewriter Mode", isOn: $preferences.typewriterMode)
            }

            Section("Presets") {
                ForEach(LucidPreset.allCases) { preset in
                    Button(preset.displayName) {
                        preferences.applyPreset(preset)
                    }
                }
            }

            Section("Actions") {
                Button("Command Palette…") {
                    presentCommandPalette()
                }
                Button("Find in Document…") {
                    withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
                        isFindBarPresented = true
                    }
                }
                Button("Export as PDF…") {
                    if let webView = webViewInstance {
                        ExportService.shared.exportPDF(webView: webView, defaultFilename: documentTitle)
                    }
                }
                Button("Export as Standalone HTML…") {
                    if let webView = webViewInstance {
                        ExportService.shared.exportHTML(webView: webView, defaultFilename: documentTitle)
                    }
                }
            }

            Section {
                Button("Preferences…") {
                    SettingsWindowManager.shared.showSettings(preferences: preferences)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LucidColors.textSecondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More Actions")
    }

    private func modeIcon(_ mode: ViewMode) -> String {
        switch mode {
        case .reader: return "book"
        case .split: return "rectangle.split.2x1"
        case .editor: return "pencil"
        }
    }

    private func modeHelp(_ mode: ViewMode) -> String {
        switch mode {
        case .reader: return "Reader Mode (⌘1)"
        case .split: return "Split Mode (⌘2)"
        case .editor: return "Editor Mode (⌘3)"
        }
    }

    // MARK: - Insert Template Snippets (into the source editor)

    private func snippetText(_ type: String) -> String {
        switch type {
        case "table":
            return "\n\n| Column 1 | Column 2 | Column 3 |\n| :--- | :---: | ---: |\n| Item 1 | Value 1 | $10.00 |\n| Item 2 | Value 2 | $20.00 |\n\n"
        case "math":
            return "\n\n$$\n\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\n$$\n\n"
        case "chemistry":
            return "\n\n$$\n\\ce{2H2 + O2 -> 2H2O}\n$$\n\n"
        case "mermaid":
            return "\n\n```mermaid\nflowchart TD\n    A[\"Input\"] --> B[\"Processing\"]\n    B --> C[\"Output\"]\n```\n\n"
        default:
            return ""
        }
    }

    /// Inserts a template into the Markdown source at the editor's cursor.
    /// Editing only ever happens in the source editor, so Reader mode switches
    /// to Split first to reveal the insertion.
    private func insertSnippet(_ type: String) {
        let template = snippetText(type)
        guard !template.isEmpty else { return }

        if preferences.viewMode == .reader {
            preferences.viewMode = .split
        }

        if let textView = editorTextView {
            let ns = textView.string as NSString
            let location = min(textView.selectedRange().location, ns.length)
            let updated = ns.replacingCharacters(in: NSRange(location: location, length: 0), with: template)
            document.text = updated
            DispatchQueue.main.async {
                let caret = min(location + (template as NSString).length, (textView.string as NSString).length)
                textView.setSelectedRange(NSRange(location: caret, length: 0))
            }
        } else {
            // No live editor yet (e.g. just switched modes): append safely.
            document.text += (document.text.hasSuffix("\n") ? "" : "\n") + template
        }
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

// MARK: - Window Chrome Helpers

/// Hides the native title bar so the custom top bar sits flush at the top,
/// while keeping the traffic lights, resizing, and standard window behavior.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = false
            if let toolbar = window.toolbar {
                toolbar.isVisible = false
            }
            // Keep the traffic lights vertically centered in the custom bar.
            window.standardWindowButton(.closeButton)?.superview?.superview?.needsLayout = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// A transparent drag region: dragging empty areas of the top bar moves the window.
private struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        override func mouseDragged(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
