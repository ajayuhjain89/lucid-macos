import SwiftUI
import WebKit
import AppKit

public struct MainWindowView: View {
    @Binding var document: LucidDocument
    var fileURL: URL?

    @StateObject private var documentManager: WindowDocumentManager
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
    /// Graduated 0…1 depth of the content beneath the toolbar, driving the
    /// scroll-responsive glass almost subconsciously.
    @State private var scrollIntensity: Double = 0
    /// Dynamic clearance for the native traffic-light cluster, derived from NSWindow geometry.
    @State private var trafficLightReservedWidth: CGFloat = 77
    // Per-window width: dragging one outline must not resize every window.
    // Persist at the end of the drag for the next window, off the layout path.
    @State private var sidebarWidth: Double = min(320, max(180, UserDefaults.standard.object(forKey: "lucid.sidebarWidth") as? Double ?? 220))
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
    @State private var startedWritingSessionIDs: Set<UUID> = []

    // Document metrics + outline are produced off-main by `analyzer`; these
    // computed accessors expose its published values to the existing view code.
    private var wordCount: Int { analyzer.wordCount }
    private var charCount: Int { analyzer.charCount }
    private var readingTimeMinutes: Int { analyzer.readingTimeMinutes }
    private var headings: [HeadingItem] { analyzer.headings }
    private var headingsBinding: Binding<[HeadingItem]> {
        Binding(get: { analyzer.headings }, set: { analyzer.headings = $0 })
    }

    private var activeDocumentText: Binding<String> {
        let session = documentManager.activeSession
        return Binding(
            get: { session.text },
            set: { newText in
                session.text = newText
                if !newText.isEmpty {
                    startedWritingSessionIDs.insert(session.id)
                }
                syncHostWindowEditingState()
            }
        )
    }

    private func syncHostWindowEditingState() {
        guard let win = hostWindow.window else { return }
        let hasDirtyTabs = documentManager.sessions.contains(where: { $0.isDirty })

        let active = documentManager.activeSession
        if let url = active.fileURL {
            win.representedURL = url
            win.title = active.displayName
        } else {
            win.representedURL = nil
            win.title = active.displayName
        }

        if let doc = (win.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: win) {
            // FileDocument supplies the initial file only. Tab sessions own saves
            // and recovery; a second native dirty buffer causes duplicate prompts.
            doc.updateChangeCount(.changeCleared)
        }
        win.isDocumentEdited = hasDirtyTabs
    }

    private var documentTitle: String {
        documentManager.activeSession.displayName
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

    public init(
        document: Binding<LucidDocument>? = nil,
        fileURL: URL? = nil,
        documentManager: WindowDocumentManager? = nil
    ) {
        let initialDoc = document ?? .constant(LucidDocument())
        self._document = initialDoc
        self.fileURL = fileURL

        if let dm = documentManager {
            self._documentManager = StateObject(wrappedValue: dm)
        } else {
            let session = DocumentSession(
                fileURL: fileURL,
                text: initialDoc.wrappedValue.text,
                savedBaselineText: initialDoc.wrappedValue.text,
                encoding: initialDoc.wrappedValue.encoding
            )
            let dm = WindowDocumentManager(initialSession: session)
            self._documentManager = StateObject(wrappedValue: dm)
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Content plane fills the whole window, edge to edge, so the document
            // scrolls beneath the floating glass toolbar rather than starting below
            // a reserved opaque band.
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Keep the outline mounted, including its filter and scroll position.
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
                    .offset(x: viewState.showOutline ? 0 : -CGFloat(sidebarWidth) - 1)
                    .frame(width: viewState.showOutline ? CGFloat(sidebarWidth) + 1 : 0, alignment: .leading)
                    .clipped()
                    .allowsHitTesting(viewState.showOutline)
                    .accessibilityHidden(!viewState.showOutline)

                    // Document Canvas — fills remaining space, continuously mounted across sidebar toggles
                    documentCanvas(sidebarOpen: viewState.showOutline)
                }
                // One layout animation owns both the sidebar and native panes.
                // WebKit follows the actual bounds; no frozen width or delayed
                // settle can add a second reflow or override a reversal.
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
                        ExportService.shared.copyRichText(markdown: documentManager.activeSession.text, documentURL: documentManager.activeSession.fileURL, preferences: preferences)
                    }
                )
                .padding(.top, (documentManager.sessions.count > 1 ? LucidChrome.toolbarHeight + 28 : LucidChrome.toolbarHeight) + LucidSpacing.xxLarge)
                .transition(
                    reduceMotion
                        ? AnyTransition.opacity
                        : AnyTransition.opacity.combined(with: .offset(y: -6))
                )
            }
        }
        .preferredColorScheme(colorSchemeForTheme)
        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.panel), value: preferences.showStatusBar)
        .onChange(of: viewState.showOutline) { _, isOpen in
            if !isOpen { focusDocumentIfFieldHasFocus() }
        }
        .ignoresSafeArea()
        // Configure the window: hide the native title bar so our custom top bar
        // sits flush at the top, and keep it draggable.
        .background(WindowConfigurator(preferences: preferences, trafficLightWidth: $trafficLightReservedWidth, hostWindow: hostWindow, documentManager: documentManager))
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
            var restoredSession = false
            LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile()
            // The Untitled window can appear just after the file's window.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile()
            }
            if let url = documentManager.activeSession.fileURL {
                RecentDocumentsManager.shared.recordRecent(url: url)
            } else if documentManager.activeSession.isUntitled && documentManager.activeSession.text.isEmpty {
                if SessionRestorationManager.shared.restoreInto(documentManager: documentManager) {
                    restoredSession = true
                    let active = documentManager.activeSession
                    viewState.viewMode = active.viewMode
                    splitFraction = active.splitFraction
                    cursorLine = active.cursorLine
                    cursorCol = active.cursorCol
                    SessionRestorationManager.shared.requestAdditionalRestorationWindow()
                }
            }
            if !restoredSession {
                documentManager.activeSession.viewMode = viewState.viewMode
                documentManager.activeSession.splitFraction = splitFraction
            }
            syncHostWindowEditingState()
            // AppKit gives a new window's focus to its first text field (the
            // sidebar filter), so typing would go there. Start on the document.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusDocumentIfFieldHasFocus()
            }
            // Prompt initial analysis (off-main, no debounce).
            analyzer.prime(text: documentManager.activeSession.text)
        }
        .onDisappear {
            // Closing the document must not let in-flight analysis publish.
            analyzer.reset()
            SessionRestorationManager.shared.unregister(manager: documentManager)
        }
        .onChange(of: documentManager.activeSession.text) { _, newText in
            if !newText.isEmpty { startedWritingSessionIDs.insert(documentManager.activeSession.id) }
            // Typing path: schedule coalesced/cancellable analysis; never block.
            analyzer.update(text: newText)
            syncHostWindowEditingState()
            if isFindBarPresented && !findQuery.isEmpty {
                // Refresh match counts only: moving the selection here would make
                // the next keystroke overwrite the first match.
                performFind(findQuery, moveSelection: false)
            }
        }
        .onChange(of: documentManager.activeSessionID) { oldID, newID in
            guard oldID != newID else { return }
            handleTabSwitch(from: oldID, to: newID)
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
            crossFadeLayoutChange()
        }
        .onChange(of: viewState.viewMode) { oldMode, newMode in
            documentManager.activeSession.viewMode = newMode
            carryReadingPosition(from: oldMode, to: newMode)
            DispatchQueue.main.async { focusVisiblePane(for: newMode) }
            if isFindBarPresented && !findQuery.isEmpty {
                performFind(findQuery)
            }
        }
        .onChange(of: splitFraction) { _, fraction in
            documentManager.activeSession.splitFraction = fraction
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidNewTab"))) { _ in
            guard isKeyDocumentWindow else { return }
            documentManager.newTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidCloseTab"))) { note in
            guard isKeyDocumentWindow, note.object == nil || isHostWindow(note.object) else { return }
            if documentManager.sessions.count > 1 {
                documentManager.closeTab(id: documentManager.activeSessionID, window: hostWindow.window) { success in
                    if success { syncHostWindowEditingState() }
                }
            } else {
                documentManager.closeTab(id: documentManager.activeSessionID, window: hostWindow.window) { success in
                    guard success else { return }
                    if let win = hostWindow.window,
                       let doc = (win.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: win) {
                        doc.updateChangeCount(.changeCleared)
                        doc.close()
                    } else {
                        hostWindow.window?.close()
                    }
                }
            }
        }
        .onReceive(documentManager.objectWillChange) { _ in
            DispatchQueue.main.async {
                syncHostWindowEditingState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidCloseWindow"))) { note in
            guard isKeyDocumentWindow, note.object == nil || isHostWindow(note.object), let win = hostWindow.window else { return }
            documentManager.closeAllTabs(window: win) { success in
                guard success else { return }
                DispatchQueue.main.async {
                    if let doc = (win.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: win) {
                        doc.updateChangeCount(.changeCleared)
                        doc.close()
                    } else {
                        win.close()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidNextTab"))) { _ in
            guard isKeyDocumentWindow else { return }
            documentManager.selectNextTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidPreviousTab"))) { _ in
            guard isKeyDocumentWindow else { return }
            documentManager.selectPreviousTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidSaveDocument"))) { _ in
            guard isKeyDocumentWindow else { return }
            documentManager.saveSession(documentManager.activeSession, saveAs: false, window: hostWindow.window) { success in
                if success { syncHostWindowEditingState() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidSaveDocumentAs"))) { _ in
            guard isKeyDocumentWindow else { return }
            documentManager.saveSession(documentManager.activeSession, saveAs: true, window: hostWindow.window) { success in
                if success { syncHostWindowEditingState() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidOpenFile"))) { note in
            if let targetWindow = note.object as? NSWindow {
                guard hostWindow.window === targetWindow else { return }
            } else {
                guard isKeyDocumentWindow else { return }
            }
            documentManager.promptOpenFile(window: hostWindow.window)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LucidOpenRecentURL"))) { note in
            guard isKeyDocumentWindow, let url = note.object as? URL else { return }
            documentManager.openFile(url: url)
            syncHostWindowEditingState()
        }
    }

    private func handleTabSwitch(from oldID: UUID, to newID: UUID) {
        guard let newSession = documentManager.sessions.first(where: { $0.id == newID }) else { return }

        if let oldSession = documentManager.sessions.first(where: { $0.id == oldID }) {
            oldSession.viewMode = viewState.viewMode
            oldSession.splitFraction = splitFraction
            oldSession.cursorLine = cursorLine
            oldSession.cursorCol = cursorCol
            if let tv = editorTextView as? LucidTextView, tv.documentSession === oldSession {
                oldSession.selectedRange = tv.selectedRange()
                oldSession.readingPosition = tv.readingPosition()
            }
        }

        viewState.viewMode = newSession.viewMode
        splitFraction = newSession.splitFraction
        cursorLine = newSession.cursorLine
        cursorCol = newSession.cursorCol

        (editorTextView as? LucidTextView)?.displaySession(newSession)

        analyzer.reset()
        analyzer.prime(text: newSession.text)

        paneSync.suppressSplitSyncUntil = CACurrentMediaTime() + 0.4
        webViewInstance?.evaluateJavaScript("if (window.lucid && window.lucid.scrollToSourceLine) { window.lucid.scrollToSourceLine(\(newSession.readingPosition.javaScriptLiteral)); }")

        syncHostWindowEditingState()
        documentManager.resolveExternalConflictIfPresent(for: newSession)
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
        guard let win = hostWindow.window else { return false }
        if win.isKeyWindow { return true }
        if NSApp.keyWindow == nil && win.isMainWindow { return true }
        let docWindows = NSApp.windows.filter { $0.isVisible && !($0 is NSPanel) && $0.canBecomeKey }
        if docWindows.count == 1 && docWindows.first === win {
            return true
        }
        return false
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
            guard let data = try? JSONEncoder().encode(query), let literal = String(data: data, encoding: .utf8) else { return }
            webViewInstance?.evaluateJavaScript("if (window.lucid) { window.lucid.find(\(literal), {reveal: \(moveSelection)}); }")
        } else {
            if query.isEmpty {
                editorMatches = []
                editorMatchIndex = 0
                findMatchCount = 0
                findCurrentIndex = 0
            } else {
                let text = documentManager.activeSession.text as NSString
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
        ExportService.shared.exportPDF(markdown: documentManager.activeSession.text, documentURL: documentManager.activeSession.fileURL, preferences: preferences, defaultFilename: documentTitle)
    }

    private func exportHTML() {
        ExportService.shared.exportHTML(markdown: documentManager.activeSession.text, documentURL: documentManager.activeSession.fileURL, preferences: preferences, defaultFilename: documentTitle)
    }

    private var isShowingEmptyState: Bool {
        documentManager.activeSession.isUntitled
            && documentManager.activeSession.text.isEmpty
            && !startedWritingSessionIDs.contains(documentManager.activeSession.id)
    }

    private func focusDocumentIfFieldHasFocus() {
        guard !isShowingEmptyState,
              let window = hostWindow.window,
              let fieldEditor = window.firstResponder as? NSTextView,
              fieldEditor.isFieldEditor,
              !isFindBarPresented, !isCommandPalettePresented else { return }
        previousFirstResponder = nil
        restoreFocusAfterFind()
    }

    private func restoreFocusAfterFind() {
        guard !isShowingEmptyState else { return }
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
                .padding(.top, (documentManager.sessions.count > 1 ? LucidChrome.toolbarHeight + 28 : LucidChrome.toolbarHeight) + LucidSpacing.small)
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
            let session = documentManager.activeSession
            let mode = viewState.viewMode
            let layout = PaneLayout(mode: mode, size: proxy.size, splitFraction: splitFraction,
                                    hiddenEditor: paneSync.hiddenEditorShape,
                                    hiddenPreview: paneSync.hiddenPreviewShape)

            let showEmptyState = documentManager.activeSession.isUntitled
                && documentManager.activeSession.text.isEmpty
                && !startedWritingSessionIDs.contains(documentManager.activeSession.id)

            ZStack(alignment: .topLeading) {
                PreviewWebView(
                    preferences: preferences,
                    markdown: documentManager.activeSession.text,
                    headings: headingsBinding,
                    activeHeading: $activeHeading,
                    onScrollFractionChanged: nil,
                    onFindMatchesChanged: { count, index in
                        findMatchCount = count
                        findCurrentIndex = index
                    },
                    scrollToHeadingId: scrollToHeadingId,
                    webViewInstance: $webViewInstance,
                    documentFileURL: documentManager.activeSession.fileURL,
                    onScrollIntensityChanged: { intensity in
                        if viewState.viewMode != .editor { scrollIntensity = intensity }
                    },
                    focusMode: viewState.focusMode,
                    isActive: layout.showsPreview && !showEmptyState
                )
                .frame(width: layout.preview.width, height: layout.preview.height)
                .offset(x: layout.preview.minX)
                .opacity(showEmptyState ? 0 : 1)
                .accessibilityHidden(!layout.showsPreview || showEmptyState)

                EditorView(
                    text: activeDocumentText,
                    preferences: preferences,
                    focusMode: viewState.focusMode,
                    isActive: layout.showsEditor && !showEmptyState,
                    documentFileURL: documentManager.activeSession.fileURL,
                    documentSession: documentManager.activeSession,
                    onRequestSave: { displayedSession in
                        guard let displayedSession,
                              documentManager.sessions.contains(where: { $0 === displayedSession }) else { return }
                        documentManager.saveSession(displayedSession, window: hostWindow.window) { _ in }
                    },
                    onReadingPositionChanged: { position in
                        session.readingPosition = position
                        if documentManager.activeSession === session && mode == .split { syncPreviewToEditor(position) }
                    },
                    onCursorPositionChanged: { line, col in
                        session.cursorLine = line
                        session.cursorCol = col
                        guard documentManager.activeSession === session else { return }
                        cursorLine = line
                        cursorCol = col
                    },
                    onTextViewCreated: { editorTextView = $0 },
                    onScrollIntensityChanged: { intensity in
                        if viewState.viewMode != .reader { scrollIntensity = intensity }
                    }
                )
                .overlay(alignment: .top) {
                    editorScrollEdgeBand.opacity((layout.showsEditor && !showEmptyState) ? 1 : 0)
                }
                .frame(width: layout.editor.width, height: layout.editor.height)
                .offset(x: layout.editor.minX)
                .opacity(showEmptyState ? 0 : 1)
                .accessibilityHidden(!layout.showsEditor || showEmptyState)

                if mode == .split && !showEmptyState {
                    PaneSplitDivider(fraction: $splitFraction, totalWidth: proxy.size.width)
                        .frame(width: PaneSplitDivider.hitWidth, height: proxy.size.height)
                        .offset(x: layout.editor.width - (PaneSplitDivider.hitWidth - PaneLayout.dividerWidth) / 2)
                }

                if showEmptyState {
                    NewDocumentEmptyStateView(
                        preferences: preferences,
                        onOpen: {
                            documentManager.promptOpenFile(window: hostWindow.window)
                        },
                        onStartWriting: {
                            startedWritingSessionIDs.insert(documentManager.activeSession.id)
                            viewState.viewMode = .editor
                            DispatchQueue.main.async {
                                focusVisiblePane(for: .editor)
                            }
                        },
                        onOpenRecent: { url in
                            RecentDocumentsManager.shared.openRecent(url: url) { targetURL in
                                documentManager.openFile(url: targetURL)
                                syncHostWindowEditingState()
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: preferences.theme.themeTokens.windowBackground))
                    .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// One composited fade for mode changes. Geometry commits
    /// immediately; no animation timer or deferred frame can overwrite a newer
    /// toggle. Reusing the layer key replaces an interrupted fade.
    private func crossFadeLayoutChange() {
        guard let layer = hostWindow.window?.contentView?.layer else { return }
        guard !reduceMotion else {
            layer.removeAnimation(forKey: "lucid.layoutChange")
            return
        }
        let fade = CATransition()
        fade.type = .fade
        fade.duration = LucidMotion.panelDuration
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(fade, forKey: "lucid.layoutChange")
    }

    /// Puts a pane that was hidden where the reader was. From Split each pane
    /// keeps its own place (the width change is anchored in both panes).
    private func carryReadingPosition(from oldMode: ViewMode, to newMode: ViewMode) {
        paneSync.suppressSplitSyncUntil = CACurrentMediaTime() + 0.4
        switch (oldMode, newMode) {
        case (.reader, .editor), (.reader, .split):
            let sessionID = documentManager.activeSessionID
            webViewInstance?.evaluateJavaScript("window.lucid && window.lucid.readingPosition ? window.lucid.readingPosition() : null") { result, _ in
                guard viewState.viewMode == newMode, documentManager.activeSessionID == sessionID,
                      let position = ReadingPosition(javaScriptValue: result),
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
        guard !isShowingEmptyState,
              mode == viewState.viewMode, !isFindBarPresented, !isCommandPalettePresented,
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

                    if documentManager.sessions.count <= 1 {
                        documentTitleBadge
                            .layoutPriority(0)
                    }

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

            if documentManager.sessions.count > 1 {
                TabBarView(documentManager: documentManager, preferences: preferences)
            }
        }
        .frame(height: documentManager.sessions.count > 1 ? LucidChrome.toolbarHeight + 28 : LucidChrome.toolbarHeight)
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
        .animation(LucidMotion.respecting(reduceMotion, LucidMotion.hover), value: scrollIntensity > 0.05)
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
        HStack(spacing: LucidSpacing.xSmall) {
            HStack(spacing: 2) {
                LucidIconButton(
                    icon: "plus",
                    size: 26,
                    iconSize: 12,
                    isActive: false,
                    helpText: "New Tab",
                    shortcutText: "⌘T"
                ) {
                    documentManager.newTab()
                }

                LucidIconButton(
                    icon: "arrow.up.doc",
                    size: 26,
                    iconSize: 12,
                    isActive: false,
                    helpText: "Open File…",
                    shortcutText: "⌘O"
                ) {
                    documentManager.promptOpenFile(window: hostWindow.window)
                }
            }
            .padding(2)
            .background(controlGlassBackground(cornerRadius: 6))

            HStack(spacing: 2) {
                modeSelector
                moreMenu
            }
            .padding(2)
            .background(controlGlassBackground(cornerRadius: 6))
        }
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
                Button("Open File…") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidOpenFile"), object: nil)
                }
                Button("New Tab") {
                    documentManager.newTab()
                }
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
            documentManager.activeSession.text += (documentManager.activeSession.text.hasSuffix("\n") ? "" : "\n") + template
        }
    }
}

// MARK: - Window Chrome Helpers

/// Hides the native title bar so the custom top bar sits flush at the top,
/// while keeping the traffic lights, resizing, and standard window behavior.
private struct WindowConfigurator: NSViewRepresentable {
    @ObservedObject var preferences: LucidPreferences
    @Binding var trafficLightWidth: CGFloat
    let hostWindow: WeakWindowRef
    let documentManager: WindowDocumentManager

    func makeNSView(context: Context) -> ConfiguratorView {
        let view = ConfiguratorView(documentManager: documentManager)
        view.onWindowAttached = { window in
            self.applyWindowSettings(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: ConfiguratorView, context: Context) {
        nsView.documentManager = documentManager
        nsView.onWindowAttached = { window in
            self.applyWindowSettings(to: window)
        }
        if let window = nsView.window {
            applyWindowSettings(to: window)
            nsView.ensureCloseDelegate()
        }
        // SwiftUI installs its own document delegate during the same update.
        DispatchQueue.main.async { [weak nsView] in nsView?.ensureCloseDelegate() }
    }

    private func applyWindowSettings(to window: NSWindow) {
        hostWindow.window = window
        documentManager.hostWindow = window
        // DocumentGroup can create an additional launch placeholder after
        // AppKit and Lucid have both completed their saved-window restoration.
        if LaunchUntitledCleanup.isLaunching,
           SessionRestorationManager.shared.isExtraRestorationWindow(documentManager) {
            DispatchQueue.main.async {
                guard LaunchUntitledCleanup.isLaunching,
                      SessionRestorationManager.shared.isExtraRestorationWindow(documentManager) else { return }
                if let document = (window.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: window) {
                    document.updateChangeCount(.changeCleared)
                    document.close()
                }
            }
        }
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
        weak var documentManager: WindowDocumentManager?
        private var willCloseObserver: Any?
        private var delegateProxy: WindowDelegateProxy?

        init(documentManager: WindowDocumentManager) {
            self.documentManager = documentManager
            super.init(frame: .zero)
        }

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window = window {
                onWindowAttached?(window)
                if let dm = documentManager {
                    if delegateProxy == nil || delegateProxy?.window !== window {
                        delegateProxy?.detach()
                        delegateProxy = WindowDelegateProxy(window: window, documentManager: dm)
                    }
                }
                DispatchQueue.main.async { [weak self] in self?.ensureCloseDelegate() }
                if willCloseObserver == nil {
                    willCloseObserver = NotificationCenter.default.addObserver(
                        forName: NSWindow.willCloseNotification,
                        object: window,
                        queue: .main
                    ) { [weak window] _ in
                        guard let window = window else { return }
                        if let doc = (window.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: window) {
                            doc.updateChangeCount(.changeCleared)
                        }
                    }
                }
            } else {
                delegateProxy?.detach()
                delegateProxy = nil
            }
        }

        func ensureCloseDelegate() {
            guard let window, let documentManager, window.delegate !== delegateProxy else { return }
            delegateProxy?.detach()
            delegateProxy = WindowDelegateProxy(window: window, documentManager: documentManager)
        }

        deinit {
            delegateProxy?.detach()
            if let observer = willCloseObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

private final class WindowDelegateProxy: NSObject, NSWindowDelegate {
    weak var originalDelegate: NSWindowDelegate?
    weak var documentManager: WindowDocumentManager?
    weak var window: NSWindow?
    private var isClosingFromManager = false

    init(window: NSWindow, documentManager: WindowDocumentManager) {
        self.window = window
        self.documentManager = documentManager
        self.originalDelegate = window.delegate
        super.init()
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isClosingFromManager { return true }
        guard let dm = documentManager else { return true }

        if dm.sessions.contains(where: { $0.isDirty }) {
            dm.closeAllTabs(window: sender) { [weak self, weak sender] success in
                if success {
                    self?.isClosingFromManager = true
                    if let win = sender,
                       let doc = (win.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: win) {
                        doc.updateChangeCount(.changeCleared)
                        doc.close()
                    } else {
                        sender?.close()
                    }
                }
            }
            return false
        }

        if let doc = (sender.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: sender) {
            doc.updateChangeCount(.changeCleared)
        }
        return true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(windowShouldClose(_:)) {
            return true
        }
        return super.responds(to: aSelector) || (originalDelegate?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let orig = originalDelegate, orig.responds(to: aSelector) {
            return orig
        }
        return super.forwardingTarget(for: aSelector)
    }

    func detach() {
        if window?.delegate === self {
            window?.delegate = originalDelegate
        }
    }

    deinit {
        detach()
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
        .accessibilityElement()
        .accessibilityLabel("Sidebar divider")
        .accessibilityValue("\(Int(width)) points")
        .accessibilityAdjustableAction { direction in
            width = min(maxWidth, max(minWidth, width + (direction == .increment ? 10 : -10)))
            UserDefaults.standard.set(width, forKey: "lucid.sidebarWidth")
        }
        .onDisappear {
            if dragStartWidth != nil { NSCursor.pop(); dragStartWidth = nil }
        }
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
                        UserDefaults.standard.set(width, forKey: "lucid.sidebarWidth")
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
        .onDisappear {
            if dragStartWidth != nil { NSCursor.pop(); dragStartWidth = nil }
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
