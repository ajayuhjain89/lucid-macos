import SwiftUI
import WebKit
import AppKit

public struct MainWindowView: View {
    @Binding var document: LucidDocument
    var fileURL: URL?

    @StateObject private var preferences = LucidPreferences.shared
    /// This window's own view mode, sidebar and Focus Mode.
    @StateObject private var viewState = WindowViewState()
    /// Off-main, coalesced document analysis (metrics + outline). Keeps the
    /// synchronous typing path free of the O(n) scan/parse.
    @StateObject private var analyzer = DocumentAnalyzer()
    @State private var activeHeading: HeadingItem?
    @State private var scrollToHeadingId: String?
    @State private var webViewInstance: WKWebView?
    /// Where the Split divider sits, as a fraction of the canvas (per window).
    @State private var splitFraction: CGFloat = 0.5
    /// Bookkeeping for mode switches and the split sync, kept out of view state
    /// so scroll events don't re-render the window.
    @State private var paneSync = PaneSyncState()
    /// The window hosting this document, held weakly. App-wide commands (Find,
    /// Command Palette) are posted without an object; only the key window acts.
    @State private var hostWindow = WeakWindowRef()
    @State private var editorTextView: NSTextView?
    @State private var fileWatcher: FileWatcher?
    /// The document text as of the last point buffer and disk were known to
    /// agree (initial load or a save). Used to tell an innocent external change
    /// apart from a genuine conflict with unsaved edits.
    @State private var lastSyncedText: String = ""
    /// Graduated 0…1 depth of the content beneath the toolbar, driving the
    /// scroll-responsive glass almost subconsciously.
    @State private var scrollIntensity: Double = 0
    /// Dynamic clearance for the native traffic-light cluster, derived from NSWindow geometry.
    @State private var trafficLightReservedWidth: CGFloat = 77
    @AppStorage("lucid.sidebarWidth") private var sidebarWidth: Double = 220
    @State private var isSidebarTransitioning: Bool = false
    @State private var sidebarTransitionToken: UUID? = nil
    @State private var sidebarTransitionTask: Task<Void, Never>? = nil
    @Namespace private var modeSelectorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    enum ActiveSurface {
        case reader
        case editor
    }

    // Find & Command Palette
    @State private var isFindBarPresented: Bool = false
    @State private var isCommandPalettePresented: Bool = false
    @State private var findQuery: String = ""
    @State private var findMatchCount: Int = 0
    @State private var findCurrentIndex: Int = 0
    @State private var editorMatches: [NSRange] = []
    @State private var editorMatchIndex: Int = 0
    @State private var lastActiveSurface: ActiveSurface = .reader
    @State private var previousFirstResponder: NSResponder? = nil

    // Cursor position for status bar
    @State private var cursorLine: Int = 1
    @State private var cursorCol: Int = 1

    // Whether the pointer is over the top chrome (used to gently reveal controls
    // when Focus Mode has quieted them).
    @State private var isToolbarHovered: Bool = false

    // Document metrics + outline are produced off-main by `analyzer`; these
    // computed accessors expose its published values to the existing view code.
    private var wordCount: Int { analyzer.wordCount }
    private var charCount: Int { analyzer.charCount }
    private var readingTimeMinutes: Int { analyzer.readingTimeMinutes }
    private var headings: [HeadingItem] { analyzer.headings }
    private var headingsBinding: Binding<[HeadingItem]> {
        Binding(get: { analyzer.headings }, set: { analyzer.headings = $0 })
    }

    private var documentTitle: String {
        fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
    }

    private var colorSchemeForTheme: ColorScheme? {
        switch preferences.theme {
        case .light, .sepia:
            return .light
        case .dark, .oled, .dracula, .nord:
            return .dark
        case .system:
            return nil
        }
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
                HStack(spacing: 0) {
                    if viewState.showOutline {
                        HStack(spacing: 0) {
                            // Outline Sidebar — owns its own compact top row with traffic light clearance and toggle
                            OutlineSidebarView(
                                headings: headings,
                                activeHeadingId: activeHeading?.id,
                                preferences: preferences,
                                wordCount: wordCount,
                                charCount: charCount,
                                readingTimeMinutes: readingTimeMinutes,
                                trafficLightWidth: trafficLightReservedWidth,
                                onToggleSidebar: {
                                    viewState.showOutline = false
                                }
                            ) { id in
                                activeHeading = headings.first(where: { $0.id == id })
                                if viewState.viewMode != .reader {
                                    scrollEditor(toHeadingId: id)
                                }
                                scrollToHeadingId = id
                                DispatchQueue.main.async {
                                    scrollToHeadingId = nil
                                }
                            }
                            .frame(width: CGFloat(sidebarWidth))

                            // Draggable divider between sidebar and canvas
                            SidebarDivider(width: $sidebarWidth, minWidth: 180, maxWidth: 320)
                        }
                        .clipped()
                        .transition(.move(edge: .leading))
                    }

                    // Document Canvas — fills remaining space, continuously mounted across sidebar toggles
                    documentCanvas(sidebarOpen: viewState.showOutline)
                }
                .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: viewState.showOutline)

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
            .ignoresSafeArea()

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
                    viewState: viewState,
                    webView: webViewInstance,
                    onInsertSnippet: { type in
                        insertSnippet(type)
                    },
                    onExportPDF: { exportPDF() },
                    onExportHTML: { exportHTML() },
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
        .preferredColorScheme(colorSchemeForTheme)
        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.showStatusBar)
        .onChange(of: viewState.showOutline) { oldValue, newValue in
            let token = UUID()
            sidebarTransitionToken = token
            if reduceMotion {
                isSidebarTransitioning = false
            } else {
                isSidebarTransitioning = true
                sidebarTransitionTask?.cancel()
                sidebarTransitionTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 210_000_000)
                    if !Task.isCancelled && sidebarTransitionToken == token {
                        isSidebarTransitioning = false
                    }
                }
            }
        }
        .ignoresSafeArea()
        // Configure the window: hide the native title bar so our custom top bar
        // sits flush at the top, and keep it draggable.
        .background(WindowConfigurator(preferences: preferences, trafficLightWidth: $trafficLightReservedWidth, hostWindow: hostWindow))
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { note in
            guard isHostWindow(note.object) else { return }
            trafficLightReservedWidth = LucidSpacing.medium
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { note in
            guard isHostWindow(note.object) else { return }
            trafficLightReservedWidth = 77
        }
        .focusedSceneObject(viewState)
        .onAppear {
            LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile()
            // The Untitled window can appear just after the file's window.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile()
            }
            setupFileWatcher()
            // AppKit gives a new window's focus to its first text field (the
            // sidebar filter), so typing would go there. Start on the document.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusDocumentIfFieldHasFocus()
            }
            // Prompt initial analysis (off-main, no debounce).
            analyzer.prime(text: document.text)
        }
        .onDisappear {
            // Closing the document must not let in-flight analysis publish.
            analyzer.reset()
        }
        .onChange(of: fileURL) { _, _ in
            // Document switch: drop stale work from the previous document, then
            // analyze the new one promptly.
            analyzer.reset()
            analyzer.prime(text: document.text)
            // A rename, move or Save As changes the path; the old watcher is tied
            // to the previous path and goes quiet, so watch the new one. Keep the
            // sync baseline: unsaved edits must still count as unsaved.
            setupFileWatcher(resetBaseline: false)
        }
        .onChange(of: document.text) { _, newText in
            // Typing path: schedule coalesced/cancellable analysis; never block.
            analyzer.update(text: newText)
            if isFindBarPresented && !findQuery.isEmpty {
                // Refresh match counts only: moving the selection here would make
                // the next keystroke overwrite the first match.
                performFind(findQuery, moveSelection: false)
            }
        }
        .onChange(of: isCommandPalettePresented) { _, isPresented in
            // However the palette closed (Esc, a command, a click outside), give
            // the keyboard back to the document; a command that opens the find
            // bar still takes focus after this, on the next run-loop turn.
            if !isPresented && !isFindBarPresented { restoreFocusAfterFind() }
        }
        // Fires as the mode is set, before the new layout is committed: the
        // cross-fade has to start from the old frame.
        .onReceive(viewState.$viewMode) { newMode in
            let oldMode = viewState.viewMode
            guard newMode != oldMode else { return }
            paneSync.rememberShapes(leaving: oldMode)
            paneSync.editorPositionAtSwitch = oldMode == .editor
                ? (editorTextView as? LucidTextView)?.readingPosition()
                : nil
            crossFadeModeSwitch()
        }
        .onChange(of: viewState.viewMode) { oldMode, newMode in
            carryReadingPosition(from: oldMode, to: newMode)
            DispatchQueue.main.async { focusVisiblePane(for: newMode) }
            if isFindBarPresented && !findQuery.isEmpty {
                performFind(findQuery)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidToggleFind"))) { _ in
            guard isKeyDocumentWindow else { return }
            toggleFind()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidFindNext"))) { _ in
            guard isKeyDocumentWindow else { return }
            findNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidFindPrevious"))) { _ in
            guard isKeyDocumentWindow else { return }
            findPrev()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidToggleCommandPalette"))) { _ in
            guard isKeyDocumentWindow else { return }
            if isCommandPalettePresented { dismissCommandPalette() } else { presentCommandPalette() }
        }
    }

    /// Scrolls the editor so the heading with `id` sits at the top, below the
    /// toolbar, and puts the caret at its start.
    private func scrollEditor(toHeadingId id: String) {
        guard let textView = editorTextView,
              let line = MarkdownOutlineParser.parseWithLines(markdown: textView.string)
                .first(where: { $0.item.id == id })?.line else { return }
        let text = textView.string as NSString
        var location = 0
        for _ in 0..<line where location < text.length {
            location = NSMaxRange(text.lineRange(for: NSRange(location: location, length: 0)))
        }
        textView.setSelectedRange(NSRange(location: location, length: 0))
        guard let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
        let glyphs = layoutManager.glyphRange(forCharacterRange: NSRange(location: location, length: 0), actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphs, in: container)
        // Container y == the clip origin that shows this line where the first line rests.
        textView.scroll(NSPoint(x: 0, y: max(0, rect.minY)))
    }

    private var isKeyDocumentWindow: Bool {
        hostWindow.window?.isKeyWindow == true
    }

    private func isHostWindow(_ object: Any?) -> Bool {
        guard let window = object as? NSWindow, let host = hostWindow.window else { return false }
        return window === host
    }

    private var currentActiveSurface: ActiveSurface {
        switch viewState.viewMode {
        case .reader:
            return .reader
        case .editor:
            return .editor
        case .split:
            return lastActiveSurface
        }
    }

    private func toggleFind() {
        if isFindBarPresented {
            closeFind()
        } else {
            previousFirstResponder = NSApp.keyWindow?.firstResponder
            if viewState.viewMode == .split {
                if let responder = previousFirstResponder as? NSView, (responder is NSTextView || (editorTextView != nil && responder.isDescendant(of: editorTextView!))) {
                    lastActiveSurface = .editor
                } else {
                    lastActiveSurface = .reader
                }
            }
            withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
                isFindBarPresented = true
            }
            if !findQuery.isEmpty {
                performFind(findQuery)
            }
        }
    }

    private func performFind(_ query: String, moveSelection: Bool = true) {
        findQuery = query
        let surface = currentActiveSurface
        if surface == .reader {
            let escaped = query.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
            webViewInstance?.evaluateJavaScript("if (window.lucid) { window.lucid.find('\(escaped)'); }")
        } else {
            if query.isEmpty {
                editorMatches = []
                editorMatchIndex = 0
                findMatchCount = 0
                findCurrentIndex = 0
            } else {
                let text = document.text as NSString
                var matches: [NSRange] = []
                var searchRange = NSRange(location: 0, length: text.length)
                while searchRange.location < text.length {
                    let found = text.range(of: query, options: .caseInsensitive, range: searchRange)
                    if found.location == NSNotFound { break }
                    matches.append(found)
                    let nextLoc = found.location + max(1, found.length)
                    if nextLoc >= text.length { break }
                    searchRange = NSRange(location: nextLoc, length: text.length - nextLoc)
                }
                editorMatches = matches
                findMatchCount = matches.count
                if !moveSelection {
                    editorMatchIndex = matches.isEmpty ? 0 : min(editorMatchIndex, matches.count - 1)
                    findCurrentIndex = matches.isEmpty ? 0 : editorMatchIndex + 1
                } else if !matches.isEmpty {
                    editorMatchIndex = 0
                    findCurrentIndex = 1
                    editorTextView?.setSelectedRange(matches[0])
                    editorTextView?.scrollRangeToVisible(matches[0])
                } else {
                    editorMatchIndex = 0
                    findCurrentIndex = 0
                }
            }
        }
    }

    private func findNext() {
        let surface = currentActiveSurface
        if surface == .reader {
            webViewInstance?.evaluateJavaScript("if (window.lucid) { window.lucid.findNext(); }")
        } else {
            guard !editorMatches.isEmpty else { return }
            editorMatchIndex = (editorMatchIndex + 1) % editorMatches.count
            findCurrentIndex = editorMatchIndex + 1
            let range = editorMatches[editorMatchIndex]
            editorTextView?.setSelectedRange(range)
            editorTextView?.scrollRangeToVisible(range)
        }
    }

    private func findPrev() {
        let surface = currentActiveSurface
        if surface == .reader {
            webViewInstance?.evaluateJavaScript("if (window.lucid) { window.lucid.findPrev(); }")
        } else {
            guard !editorMatches.isEmpty else { return }
            editorMatchIndex = (editorMatchIndex - 1 + editorMatches.count) % editorMatches.count
            findCurrentIndex = editorMatchIndex + 1
            let range = editorMatches[editorMatchIndex]
            editorTextView?.setSelectedRange(range)
            editorTextView?.scrollRangeToVisible(range)
        }
    }

    private func closeFind() {
        withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
            isFindBarPresented = false
        }
        if currentActiveSurface == .reader {
            webViewInstance?.evaluateJavaScript("if (window.lucid) { window.lucid.clearFind(); }")
        }
        restoreFocusAfterFind()
    }

    // Exports render the document text in their own offscreen page, so they
    // work in every view mode, including Editor mode with no preview.
    private func exportPDF() {
        ExportService.shared.exportPDF(markdown: document.text, documentURL: fileURL, preferences: preferences, defaultFilename: documentTitle)
    }

    private func exportHTML() {
        ExportService.shared.exportHTML(markdown: document.text, documentURL: fileURL, preferences: preferences, defaultFilename: documentTitle)
    }

    private func focusDocumentIfFieldHasFocus() {
        guard let window = hostWindow.window,
              let fieldEditor = window.firstResponder as? NSTextView,
              fieldEditor.isFieldEditor,
              !isFindBarPresented, !isCommandPalettePresented else { return }
        previousFirstResponder = nil
        restoreFocusAfterFind()
    }

    private func restoreFocusAfterFind() {
        if let target = previousFirstResponder {
            let targetWindow: NSWindow? = {
                if let view = target as? NSView { return view.window }
                if let window = target as? NSWindow { return window }
                return nil
            }()
            let isHidden: Bool = {
                guard let view = target as? NSView else { return false }
                if viewState.viewMode == .editor, let webView = webViewInstance,
                   view === webView || view.isDescendant(of: webView) {
                    return true  // the preview is kept at alpha 0, not hidden
                }
                return view.isHiddenOrHasHiddenAncestor
            }()

            if let window = targetWindow, window == NSApp.keyWindow, !isHidden {
                window.makeFirstResponder(target)
                return
            }
        }

        switch viewState.viewMode {
        case .editor:
            if let tv = editorTextView, tv.window != nil {
                tv.window?.makeFirstResponder(tv)
            }
        case .reader:
            if let wv = webViewInstance, wv.window != nil {
                wv.window?.makeFirstResponder(wv)
            }
        case .split:
            if lastActiveSurface == .editor, let tv = editorTextView, tv.window != nil {
                tv.window?.makeFirstResponder(tv)
            } else if let wv = webViewInstance, wv.window != nil {
                wv.window?.makeFirstResponder(wv)
            }
        }
    }

    private func presentCommandPalette() {
        previousFirstResponder = NSApp.keyWindow?.firstResponder
        withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
            isCommandPalettePresented = true
        }
    }

    private func dismissCommandPalette() {
        withAnimation(LucidMotion.respecting(reduceMotion, LucidMotion.modal)) {
            isCommandPalettePresented = false
        }
    }

    // MARK: - Structural Document Canvas & Top Chrome

    private func documentCanvas(sidebarOpen: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            documentContent
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: preferences.theme.themeTokens.windowBackground))

            // Floating glass top chrome, structurally contained in the Document Canvas
            documentTopBar(sidebarOpen: sidebarOpen)

            // Floating Find Bar — aligned just below the glass toolbar.
            if isFindBarPresented {
                FindBarView(
                    isPresented: $isFindBarPresented,
                    query: $findQuery,
                    matchCount: $findMatchCount,
                    currentIndex: $findCurrentIndex,
                    onPerformFind: { performFind($0) },
                    onFindNext: { findNext() },
                    onFindPrev: { findPrev() },
                    onDismiss: { closeFind() }
                )
                .padding(.top, LucidChrome.toolbarHeight + LucidSpacing.small)
                .padding(.trailing, LucidSpacing.large)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
    }

    /// One editor and one preview for the window's lifetime. A mode switch only
    /// moves and hides them (PaneLayout), so nothing is rebuilt: no blank
    /// preview, no reload, and each pane keeps its place and its state.
    private var documentContent: some View {
        GeometryReader { proxy in
            let mode = viewState.viewMode
            let layout = PaneLayout(mode: mode, size: proxy.size, splitFraction: splitFraction,
                                    hiddenEditor: paneSync.hiddenEditorShape,
                                    hiddenPreview: paneSync.hiddenPreviewShape)
            ZStack(alignment: .topLeading) {
                PreviewWebView(
                    preferences: preferences,
                    markdown: document.text,
                    headings: headingsBinding,
                    activeHeading: $activeHeading,
                    onScrollFractionChanged: nil,
                    onFindMatchesChanged: { count, index in
                        findMatchCount = count
                        findCurrentIndex = index
                    },
                    scrollToHeadingId: scrollToHeadingId,
                    webViewInstance: $webViewInstance,
                    documentFileURL: fileURL,
                    onScrollIntensityChanged: { intensity in
                        if viewState.viewMode != .editor { scrollIntensity = intensity }
                    },
                    isSidebarTransitioning: isSidebarTransitioning,
                    sidebarWidth: CGFloat(sidebarWidth),
                    transitionToken: sidebarTransitionToken,
                    isSidebarOpen: viewState.showOutline,
                    focusMode: viewState.focusMode,
                    isActive: layout.showsPreview
                )
                .frame(width: layout.preview.width, height: layout.preview.height)
                .offset(x: layout.preview.minX)
                .accessibilityHidden(!layout.showsPreview)

                EditorView(
                    text: $document.text,
                    preferences: preferences,
                    focusMode: viewState.focusMode,
                    isActive: layout.showsEditor,
                    onReadingPositionChanged: mode == .split ? { syncPreviewToEditor($0) } : nil,
                    onCursorPositionChanged: { line, col in
                        cursorLine = line
                        cursorCol = col
                    },
                    onTextViewCreated: { editorTextView = $0 },
                    onScrollIntensityChanged: { intensity in
                        if viewState.viewMode != .reader { scrollIntensity = intensity }
                    }
                )
                .overlay(alignment: .top) {
                    editorScrollEdgeBand.opacity(layout.showsEditor ? 1 : 0)
                }
                .frame(width: layout.editor.width, height: layout.editor.height)
                .accessibilityHidden(!layout.showsEditor)

                if mode == .split {
                    PaneSplitDivider(fraction: $splitFraction, totalWidth: proxy.size.width)
                        .frame(width: PaneSplitDivider.hitWidth, height: proxy.size.height)
                        .offset(x: layout.editor.width - (PaneSplitDivider.hitWidth - PaneLayout.dividerWidth) / 2)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// Cross-fades the whole window from the old mode to the new one (0.19 s)
    /// while the panes switch instantly underneath. A layer transition fades the
    /// composited result, web content included, so nothing reflows on screen
    /// frame by frame. Instant with Reduce Motion.
    private func crossFadeModeSwitch() {
        guard !reduceMotion, let layer = hostWindow.window?.contentView?.layer else { return }
        let fade = CATransition()
        fade.type = .fade
        fade.duration = 0.19
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(fade, forKey: "lucid.modeSwitch")
    }

    /// Puts a pane that was hidden where the reader was. From Split each pane
    /// keeps its own place (the width change is anchored in both panes).
    private func carryReadingPosition(from oldMode: ViewMode, to newMode: ViewMode) {
        paneSync.suppressSplitSyncUntil = CACurrentMediaTime() + 0.4
        switch (oldMode, newMode) {
        case (.reader, .editor), (.reader, .split):
            webViewInstance?.evaluateJavaScript("window.lucid && window.lucid.readingPosition ? window.lucid.readingPosition() : null") { result, _ in
                guard let position = ReadingPosition(javaScriptValue: result),
                      let textView = editorTextView as? LucidTextView else { return }
                paneSync.suppressSplitSyncUntil = CACurrentMediaTime() + 0.3
                textView.scrollToReadingPosition(position)
            }
        case (.editor, .reader), (.editor, .split):
            guard let position = paneSync.editorPositionAtSwitch else { return }
            paneSync.lastSentToPreview = position
            webViewInstance?.evaluateJavaScript("if (window.lucid && window.lucid.scrollToSourceLine) { window.lucid.scrollToSourceLine(\(position.javaScriptLiteral)); }")
        default:
            break
        }
        paneSync.editorPositionAtSwitch = nil
    }

    /// Keyboard focus follows the mode: the editor for Split and Editor, the
    /// preview for Reader (so the arrow keys and Page Down scroll it).
    private func focusVisiblePane(for mode: ViewMode) {
        guard mode == viewState.viewMode, !isFindBarPresented, !isCommandPalettePresented,
              let window = hostWindow.window else { return }
        let target: NSView? = mode == .reader ? webViewInstance : editorTextView
        guard let target, window.firstResponder !== target else { return }
        window.makeFirstResponder(target)
    }

    /// Split sync: the preview follows the editor by source line, so both panes
    /// show the same text (a scroll fraction drifts wherever diagrams or math
    /// make the preview taller than the source).
    private func syncPreviewToEditor(_ position: ReadingPosition) {
        guard viewState.viewMode == .split, CACurrentMediaTime() >= paneSync.suppressSplitSyncUntil else { return }
        if let last = paneSync.lastSentToPreview, last.top == position.top, last.end == position.end,
           abs(last.line - position.line) < 0.05 { return }
        paneSync.lastSentToPreview = position
        webViewInstance?.evaluateJavaScript("if (window.lucid && window.lucid.scrollToSourceLine) { window.lucid.scrollToSourceLine(\(position.javaScriptLiteral)); }")
    }

    /// Hides editor text scrolled beneath the floating toolbar. The preview
    /// draws its own band in the page (markdown-preview.css), so it repaints in
    /// step with the page on theme changes.
    private var editorScrollEdgeBand: some View {
        LucidScrollEdgeBand(color: Color(hex: preferences.theme.themeTokens.editorBackground))
    }

    private func documentTopBar(sidebarOpen: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                // Empty regions of the bar drag the window.
                LucidWindowDragArea()

                HStack(spacing: LucidSpacing.small) {
                    if !sidebarOpen {
                        // Reserved clearance for native traffic lights
                        Color.clear
                            .frame(width: trafficLightReservedWidth, height: 1)
                            .allowsHitTesting(false)

                        LucidIconButton(
                            icon: "sidebar.leading",
                            size: 26,
                            iconSize: 13,
                            isActive: false,
                            helpText: "Toggle Outline Sidebar",
                            shortcutText: "⌃⌘S"
                        ) {
                            viewState.showOutline = true
                        }
                        .background(controlGlassBackground(cornerRadius: 6))
                    }

                    documentTitleBadge
                        .layoutPriority(0)

                    Spacer(minLength: LucidSpacing.medium)

                    rightControlsCluster
                }
                .padding(.leading, sidebarOpen ? LucidSpacing.large : 0)
                .padding(.trailing, LucidSpacing.medium)
                .opacity(toolbarControlsOpacity)
                .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: isToolbarHovered)
                .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: viewState.focusMode)
            }
            .frame(height: LucidChrome.toolbarHeight)
            .frame(maxWidth: .infinity)
            .onHover { isToolbarHovered = $0 }
        }
        .frame(height: LucidChrome.toolbarHeight)
    }

    private func controlGlassBackground(cornerRadius: CGFloat) -> some View {
        Group {
            if scrollIntensity > 0.05 {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(hex: preferences.theme.themeTokens.windowBackground).opacity(0.35))
                    )
            }
        }
        .animation(.easeOut(duration: 0.15), value: scrollIntensity > 0.05)
    }

    private var titleVisibility: Double {
        let progress = min(1.0, max(0.0, scrollIntensity))
        // Smooth continuous cosine curve: 1.0 at rest, 0.95 at ~4px, 0.61 at ~12px, 0.20 at ~20px, 0.0 at 28px
        return (1.0 + cos(progress * .pi)) / 2.0
    }

    private var documentTitleBadge: some View {
        Text(documentTitle)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(Color(hex: preferences.theme.themeTokens.textTertiary))
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 4)
            .frame(height: 24)
            .opacity(titleVisibility)
            .allowsHitTesting(titleVisibility > 0.05)
            .help(titleVisibility > 0.05 ? documentTitle : "")
            .accessibilityLabel(documentTitle)
    }

    /// In Focus Mode the toolbar controls recede to keep the document dominant,
    /// then gently return to full presence when the pointer approaches the top.
    private var toolbarControlsOpacity: Double {
        guard viewState.focusMode else { return 1 }
        return isToolbarHovered ? 1 : 0.4
    }

    private var rightControlsCluster: some View {
        HStack(spacing: 2) {
            modeSelector
            moreMenu
        }
        .padding(2)
        .background(controlGlassBackground(cornerRadius: 6))
        .layoutPriority(1)
        .fixedSize()
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            ForEach([ViewMode.reader, ViewMode.split, ViewMode.editor], id: \.self) { mode in
                let isSelected = viewState.viewMode == mode
                Button(action: {
                    viewState.viewMode = mode
                }) {
                    Image(systemName: modeIcon(mode))
                        .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                        .foregroundColor(isSelected ? Color(hex: preferences.theme.themeTokens.textPrimary) : Color(hex: preferences.theme.themeTokens.textSecondary))
                        .frame(width: 28, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isSelected ? Color(hex: preferences.theme.themeTokens.textPrimary).opacity(0.12) : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.94))
                .help(modeHelp(mode))
                .accessibilityLabel(modeHelp(mode))
            }
        }
    }

    private var moreMenu: some View {
        Menu {
            Section("Focus & Modes") {
                Toggle("Focus Mode", isOn: $viewState.focusMode)
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
                Button("Export as PDF…") { exportPDF() }
                Button("Export as Standalone HTML…") { exportHTML() }
            }

            Section {
                Button("Settings…") {
                    SettingsWindowManager.shared.showSettings(preferences: preferences)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: preferences.theme.themeTokens.textSecondary))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More Actions")
        .accessibilityLabel("More Actions")
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

        if viewState.viewMode == .reader {
            viewState.viewMode = .split
        }

        if let textView = editorTextView {
            // Through the text view, so the insertion is a single undo step
            // (like a paste) and the caret lands after it.
            let location = min(textView.selectedRange().location, (textView.string as NSString).length)
            let range = NSRange(location: location, length: 0)
            if textView.shouldChangeText(in: range, replacementString: template) {
                textView.replaceCharacters(in: range, with: template)
                textView.didChangeText()
                textView.setSelectedRange(NSRange(location: location + (template as NSString).length, length: 0))
            }
        } else {
            // No live editor yet (e.g. just switched modes): append safely.
            document.text += (document.text.hasSuffix("\n") ? "" : "\n") + template
        }
    }

    private func setupFileWatcher(resetBaseline: Bool = true) {
        guard let url = fileURL else { return }
        if resetBaseline { lastSyncedText = document.text }
        fileWatcher = FileWatcher(url: url) {
            guard let data = try? Data(contentsOf: url),
                  let updatedText = LucidDocument.decodeText(data)?.text else { return }
            DispatchQueue.main.async {
                if updatedText == self.document.text {
                    // Already in sync (e.g. Lucid's own save): refresh the baseline.
                    self.lastSyncedText = updatedText
                    return
                }
                if self.document.text == self.lastSyncedText {
                    // No unsaved local edits: safe to live-reload from disk.
                    self.reloadFromDisk(url: url, diskText: updatedText)
                } else {
                    // Disk and buffer both diverged from the last sync point:
                    // never silently discard the user's unsaved edits.
                    self.presentExternalChangeConflict(url: url, diskText: updatedText)
                }
            }
        }
    }

    /// Reloads the document from disk through NSDocument's revert path. Writing
    /// `document.text` directly would mark the document edited, and AppKit would
    /// then report an autosave conflict against the file it just re-read.
    private func reloadFromDisk(url: URL, diskText: String) {
        if let nsDocument = NSDocumentController.shared.document(for: url),
           let type = nsDocument.fileType,
           (try? nsDocument.revert(toContentsOf: url, ofType: type)) != nil {
            lastSyncedText = diskText
            return
        }
        document.text = diskText
        lastSyncedText = diskText
    }

    private func presentExternalChangeConflict(url: URL, diskText: String) {
        let alert = NSAlert()
        alert.messageText = "“\(url.lastPathComponent)” changed on disk"
        alert.informativeText = "This file was modified by another application, but you have unsaved changes here. Reload the version on disk (discarding your changes) or keep your version?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep My Changes")
        alert.addButton(withTitle: "Reload from Disk")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            reloadFromDisk(url: url, diskText: diskText)
        }
        // "Keep My Changes": leave the buffer untouched; the baseline is left as
        // is so a further on-disk change prompts again instead of silently losing edits.
    }
}

// MARK: - Window Chrome Helpers

/// Hides the native title bar so the custom top bar sits flush at the top,
/// while keeping the traffic lights, resizing, and standard window behavior.
private struct WindowConfigurator: NSViewRepresentable {
    @ObservedObject var preferences: LucidPreferences
    @Binding var trafficLightWidth: CGFloat
    let hostWindow: WeakWindowRef

    func makeNSView(context: Context) -> ConfiguratorView {
        let view = ConfiguratorView()
        view.onWindowAttached = { window in
            self.applyWindowSettings(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: ConfiguratorView, context: Context) {
        nsView.onWindowAttached = { window in
            self.applyWindowSettings(to: window)
        }
        if let window = nsView.window {
            applyWindowSettings(to: window)
        }
    }

    private func applyWindowSettings(to window: NSWindow) {
        hostWindow.window = window
        window.titlebarAppearsTransparent = true
        // The title stays set (NSDocument names the window) so the Window menu,
        // Mission Control and accessibility show the document name; it is just
        // not drawn in the hidden title bar.
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = false
        if let toolbar = window.toolbar {
            toolbar.isVisible = false
        }
        window.standardWindowButton(.documentIconButton)?.isHidden = true
        window.standardWindowButton(.documentVersionsButton)?.isHidden = true

        switch preferences.theme {
        case .light, .sepia:
            window.appearance = NSAppearance(named: .aqua)
        case .dark, .oled, .dracula, .nord:
            window.appearance = NSAppearance(named: .darkAqua)
        case .system:
            window.appearance = nil
        }

        let computed = computeTrafficLightWidth(for: window)
        if abs(trafficLightWidth - computed) > 0.5 {
            DispatchQueue.main.async {
                self.trafficLightWidth = computed
            }
        }
    }

    private func computeTrafficLightWidth(for window: NSWindow) -> CGFloat {
        if window.styleMask.contains(.fullScreen) {
            return LucidSpacing.medium
        }
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        var maxX: CGFloat = 0
        var found = false
        for bType in buttons {
            if let btn = window.standardWindowButton(bType), !btn.isHidden, let cv = window.contentView {
                let rect = btn.convert(btn.bounds, to: cv)
                maxX = max(maxX, rect.maxX)
                found = true
            }
        }
        if found && maxX > 0 {
            return maxX + LucidSpacing.small
        }
        return 77
    }

    final class ConfiguratorView: NSView {
        var onWindowAttached: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window = window {
                onWindowAttached?(window)
            }
        }
    }
}

/// A weak reference to a window, safe to keep in view state.
final class WeakWindowRef {
    weak var window: NSWindow?
}

// MARK: - Draggable Sidebar Divider

private struct SidebarDivider: View {
    @Binding var width: Double
    var minWidth: Double = 180
    var maxWidth: Double = 320

    @State private var dragStartWidth: Double? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LucidColors.subtleSeparator)
                .frame(width: 1)

            CursorTrackingView(cursor: .resizeLeftRight)
                .frame(width: 8)
                .contentShape(Rectangle())
        }
        .frame(width: 1)
        .zIndex(10)
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartWidth == nil {
                        dragStartWidth = width
                        NSCursor.resizeLeftRight.push()
                    }
                    if let start = dragStartWidth {
                        let newWidth = start + Double(value.translation.width)
                        width = min(maxWidth, max(minWidth, newWidth))
                    }
                }
                .onEnded { _ in
                    if dragStartWidth != nil {
                        NSCursor.pop()
                        dragStartWidth = nil
                    }
                }
        )
    }
}

private struct CursorTrackingView: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> TrackingNSView {
        let view = TrackingNSView()
        view.cursor = cursor
        return view
    }

    func updateNSView(_ nsView: TrackingNSView, context: Context) {
        nsView.cursor = cursor
    }

    final class TrackingNSView: NSView {
        var cursor: NSCursor = .resizeLeftRight

        override func resetCursorRects() {
            super.resetCursorRects()
            addCursorRect(bounds, cursor: cursor)
        }
    }
}

/// Mode-switch and split-sync bookkeeping for one window. A reference type so
/// updating it never invalidates the view.
final class PaneSyncState {
    /// The editor's reading position just before it was hidden or resized.
    var editorPositionAtSwitch: ReadingPosition?
    /// Last position sent to the preview (skips repeats while scrolling).
    var lastSentToPreview: ReadingPosition?
    /// The split sync ignores editor scrolls until then: a mode switch scrolls
    /// the editor itself, and that must not bounce back to the preview.
    var suppressSplitSyncUntil: CFTimeInterval = 0
    /// The shape each pane had when it was last on screen (see PaneLayout).
    var hiddenEditorShape: PaneLayout.Shape = .full
    var hiddenPreviewShape: PaneLayout.Shape = .full

    func rememberShapes(leaving mode: ViewMode) {
        switch mode {
        case .reader: hiddenPreviewShape = .full
        case .editor: hiddenEditorShape = .full
        case .split:
            hiddenEditorShape = .split
            hiddenPreviewShape = .split
        }
    }
}

/// The draggable divider between the Split panes.
private struct PaneSplitDivider: View {
    static let hitWidth: CGFloat = 9

    @Binding var fraction: CGFloat
    let totalWidth: CGFloat

    @State private var dragStartWidth: CGFloat? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LucidColors.subtleSeparator)
                .frame(width: PaneLayout.dividerWidth)

            CursorTrackingView(cursor: .resizeLeftRight)
                .frame(width: 8)
                .contentShape(Rectangle())
        }
        .frame(width: Self.hitWidth)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel("Split divider")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            let step: CGFloat = direction == .increment ? 0.05 : -0.05
            fraction = PaneLayout.fraction(forEditorWidth: (fraction + step) * totalWidth, total: totalWidth)
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartWidth == nil {
                        dragStartWidth = PaneLayout.editorWidth(total: totalWidth, fraction: fraction)
                        NSCursor.resizeLeftRight.push()
                    }
                    if let start = dragStartWidth {
                        fraction = PaneLayout.fraction(forEditorWidth: start + value.translation.width, total: totalWidth)
                    }
                }
                .onEnded { _ in
                    if dragStartWidth != nil {
                        NSCursor.pop()
                        dragStartWidth = nil
                    }
                }
        )
    }
}
