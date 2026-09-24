import SwiftUI
import WebKit
import UniformTypeIdentifiers
import AppKit

/// A custom NSView container that hosts WKWebView with strict layout clipping and
/// geometry freeze-and-settle control during sidebar open/close transitions.
///
/// Prevents WebKit from reflowing document contents (Markdown, tables, KaTeX, Mermaid)
/// on every animation frame by freezing or pre-sizing the WKWebView frame while the outer
/// container animates smoothly via SwiftUI.
public final class LucidWebContainerView: NSView {
    public let webView: WKWebView
    /// False while another view mode hides the preview. It stays in the window
    /// at alpha 0 rather than being hidden, so WebKit keeps its rendered tiles
    /// and showing it again needs no repaint; it just takes no clicks.
    var isPaneActive = true {
        didSet { alphaValue = isPaneActive ? 1 : 0 }
    }
    private var isTransitioning: Bool = false
    private var activeTransitionToken: UUID? = nil
    private var frozenWidth: CGFloat? = nil

    public init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        autoresizesSubviews = false
        wantsLayer = true
        layer?.masksToBounds = true
        webView.autoresizingMask = []
        addSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        isPaneActive ? super.hitTest(point) : nil
    }

    public override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }

        if isTransitioning, let frozen = frozenWidth {
            // During transition, maintain the frozen width and match container height
            webView.frame = CGRect(x: 0, y: 0, width: frozen, height: bounds.height)
        } else {
            // Normal layout: match container bounds exactly
            webView.frame = bounds
        }
    }

    public func handleSidebarTransition(
        isTransitioning: Bool,
        isSidebarOpen: Bool,
        sidebarWidth: CGFloat,
        token: UUID?
    ) {
        if self.isTransitioning == isTransitioning && self.activeTransitionToken == token {
            return
        }

        let previousTransitioning = self.isTransitioning
        self.isTransitioning = isTransitioning
        self.activeTransitionToken = token

        if isTransitioning && !previousTransitioning {
            // Transition is starting
            if isSidebarOpen {
                // OPENING: Container starts wide and will narrow.
                // Freeze current wide bounds so the document does not reflow during the slide.
                let currentWidth = bounds.width > 0 ? bounds.width : (webView.frame.width > 0 ? webView.frame.width : 800)
                self.frozenWidth = currentWidth
                webView.frame = CGRect(x: 0, y: 0, width: currentWidth, height: bounds.height)
            } else {
                // CLOSING: Container starts narrow and will widen.
                // Pre-resize WKWebView to wide width so newly exposed space reveals already-rendered content.
                let currentWidth = bounds.width > 0 ? bounds.width : 600
                let wideWidth = currentWidth + sidebarWidth
                self.frozenWidth = wideWidth

                webView.evaluateJavaScript("if (window.lucid && window.lucid.captureReadingAnchor) { window.lucid.captureReadingAnchor(); }") { [weak self] _, _ in
                    guard let self = self else { return }
                    self.webView.frame = CGRect(x: 0, y: 0, width: wideWidth, height: self.bounds.height)
                    self.webView.evaluateJavaScript("if (window.lucid && window.lucid.restoreReadingAnchor) { window.lucid.restoreReadingAnchor(); }")
                }
            }
        } else if !isTransitioning && previousTransitioning {
            // Transition has settled
            self.frozenWidth = nil

            if isSidebarOpen {
                // OPENING SETTLE:
                // Capture anchor before committing narrow geometry
                webView.evaluateJavaScript("if (window.lucid && window.lucid.captureReadingAnchor) { window.lucid.captureReadingAnchor(); }") { [weak self] _, _ in
                    guard let self = self else { return }
                    self.webView.frame = self.bounds
                    DispatchQueue.main.async {
                        self.webView.evaluateJavaScript("if (window.lucid && window.lucid.restoreReadingAnchor) { window.lucid.restoreReadingAnchor(); }")
                    }
                }
            } else {
                // CLOSING SETTLE:
                // Commit exact final bounds
                self.webView.frame = bounds
            }
        }
    }
}

public struct PreviewWebView: NSViewRepresentable {
    @ObservedObject var preferences: LucidPreferences
    let markdown: String
    @Binding var headings: [HeadingItem]
    @Binding var activeHeading: HeadingItem?
    var onScrollFractionChanged: ((Double) -> Void)?
    var onFindMatchesChanged: ((Int, Int) -> Void)?
    var scrollToHeadingId: String?
    @Binding var webViewInstance: WKWebView?
    /// The on-disk location of the document being previewed, used to resolve
    /// relative links to sibling files when the reader clicks a cross-file link.
    var documentFileURL: URL? = nil
    /// Reports a graduated 0…1 intensity of how far the content has scrolled away
    /// from the top, so the chrome can raise its glass depth almost subconsciously.
    var onScrollIntensityChanged: ((Double) -> Void)? = nil
    var isSidebarTransitioning: Bool = false
    var sidebarWidth: CGFloat = 240
    var transitionToken: UUID? = nil
    var isSidebarOpen: Bool = false
    /// This window's Focus Mode (WindowViewState), not the app-wide default.
    var focusMode: Bool = false
    /// False while another view mode hides the preview: edits are not rendered
    /// until it is shown again, then the latest text renders at once.
    var isActive: Bool = true
    @Environment(\.colorScheme) var colorScheme

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> LucidWebContainerView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(
            LocalAssetSchemeHandler { [weak coordinator = context.coordinator] in
                coordinator?.parent.documentFileURL?.deletingLastPathComponent()
            },
            forURLScheme: LocalAssetSchemeHandler.scheme
        )
        let userContent = WKUserContentController()

        let effectiveTheme: String = {
            if preferences.theme == .system {
                let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return isDark ? "dark" : "light"
            }
            return preferences.theme.rawValue
        }()

        let themeScript = WKUserScript(
            source: """
            document.documentElement.setAttribute('data-theme', '\(effectiveTheme)');
            document.documentElement.classList.add('\(effectiveTheme)');
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContent.addUserScript(themeScript)

        // WKUserContentController retains its handlers strongly; route through a
        // weak proxy so the coordinator (and this web view) can be released.
        let messageHandler = WeakScriptMessageHandler(context.coordinator)
        for name in PreviewWebView.messageHandlerNames {
            userContent.add(messageHandler, name: name)
        }
        config.userContentController = userContent

        let effectiveTokens: LucidThemeTokens = {
            if preferences.theme == .system {
                let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return isDark ? LucidTheme.studioDark.tokens : LucidTheme.editorialLight.tokens
            }
            return preferences.theme.themeTokens
        }()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.underPageBackgroundColor = NSColor(Color(hex: effectiveTokens.previewBackground))

        context.coordinator.renderCoordinator.setWebView(webView)
        context.coordinator.wasActive = isActive

        DispatchQueue.main.async {
            self.webViewInstance = webView
        }

        if let indexURL = Self.engineIndexURL {
            context.coordinator.allowedFileURL = indexURL
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        }

        let container = LucidWebContainerView(webView: webView)
        container.isPaneActive = isActive
        return container
    }

    /// The bundled preview engine page (WebEngine/index.html in the app's resources).
    static var engineIndexURL: URL? {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebEngine") {
            return url
        }
        if let resURL = Bundle.main.resourceURL?.appendingPathComponent("WebEngine/index.html"),
           FileManager.default.fileExists(atPath: resURL.path) {
            return resURL
        }
        return nil
    }

    static let messageHandlerNames = [
        "lucidReady", "lucidScroll", "lucidHeadings", "lucidActiveHeading",
        "lucidFindMatches", "lucidLinkClicked", "lucidSaveSvg", "lucidPerf"
    ]

    /// Tears the web view down when SwiftUI removes it (e.g. a view-mode switch),
    /// so its WebContent process exits instead of accumulating.
    public static func dismantleNSView(_ containerView: LucidWebContainerView, coordinator: Coordinator) {
        let webView = containerView.webView
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.removeAllUserScripts()
        DispatchQueue.main.async {
            // Drop the window's reference only if it still points at this web view.
            if coordinator.parent.webViewInstance === webView {
                coordinator.parent.webViewInstance = nil
            }
        }
    }

    public func updateNSView(_ containerView: LucidWebContainerView, context: Context) {
        let webView = containerView.webView
        context.coordinator.parent = self

        // Forward sidebar transition state to container view
        containerView.handleSidebarTransition(
            isTransitioning: isSidebarTransitioning,
            isSidebarOpen: isSidebarOpen,
            sidebarWidth: sidebarWidth,
            token: transitionToken
        )

        if containerView.isPaneActive != isActive {
            containerView.isPaneActive = isActive
        }
        let revealing = isActive && !context.coordinator.wasActive
        let hasPendingRender: Bool
        if isActive {
            hasPendingRender = context.coordinator.renderCoordinator.setRenderingPaused(false)
        } else if context.coordinator.hasRenderedFirstContent {
            hasPendingRender = false
            if context.coordinator.renderCoordinator.setRenderingPaused(true, latestMarkdown: markdown) {
                context.coordinator.needsRenderWhenRevealed = true
            }
        } else {
            hasPendingRender = false
        }
        context.coordinator.wasActive = isActive

        let tokens = preferences.theme.themeTokens
        webView.underPageBackgroundColor = NSColor(Color(hex: tokens.previewBackground))

        // Update preferences only when payload changes to avoid IPC thrashing
        let prefsJSON = preferences.jsonPayload(systemColorScheme: colorScheme, focusMode: focusMode)
        if prefsJSON != context.coordinator.lastAppliedPrefsJSON {
            context.coordinator.lastAppliedPrefsJSON = prefsJSON
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")
        }

        // Schedule render: immediate on first load, file change or when a hidden
        // preview is shown again; debounced on interactive typing. A hidden
        // preview renders the document once (so showing it is instant) and then
        // waits: edits made in Editor mode render when it comes back.
        let isFirstRender = !context.coordinator.hasRenderedFirstContent
        let isNewContent = context.coordinator.lastRenderedMarkdown != markdown
        if isFirstRender || (isNewContent && isActive) ||
            (revealing && (context.coordinator.needsRenderWhenRevealed || hasPendingRender)) {
            context.coordinator.lastRenderedMarkdown = markdown
            context.coordinator.renderCoordinator.scheduleRender(markdown: markdown, immediate: isFirstRender || revealing)
            context.coordinator.needsRenderWhenRevealed = false
            if isFirstRender && context.coordinator.renderCoordinator.isBridgeReady {
                context.coordinator.hasRenderedFirstContent = true
            }
        }

        // Scroll to heading if requested
        if let headingId = scrollToHeadingId {
            if headingId != context.coordinator.lastScrolledHeadingId {
                context.coordinator.lastScrolledHeadingId = headingId
                webView.evaluateJavaScript("if (window.lucid) { window.lucid.scrollToHeading('\(headingId)'); }")
            }
        } else {
            context.coordinator.lastScrolledHeadingId = nil
        }
    }

    public final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: PreviewWebView
        var isPageLoaded = false
        var hasRenderedFirstContent = false
        var lastRenderedMarkdown = ""
        var lastScrolledHeadingId: String?
        var lastAppliedPrefsJSON: String?
        var wasActive = true
        var needsRenderWhenRevealed = false
        var lastReportedIntensity: Double = -1
        var lastReportedFraction: Double = -1
        var lastActiveHeadingId: String?
        /// Whether any revision-tagged heading echo has been seen. Once tagging is
        /// active, an untagged (legacy) echo must not bypass revision safety.
        var hasSeenTaggedHeadings: Bool = false
        /// The only document the WebView is permitted to navigate to (the bundled
        /// `index.html`). Any other navigation is refused as a defense-in-depth
        /// guard so document/script content cannot drive the reader off-page.
        var allowedFileURL: URL?
        let renderCoordinator = PreviewRenderCoordinator()

        init(_ parent: PreviewWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""

            // Allow only the app's own bundled preview document — the initial
            // load, reloads, and same-document fragment navigation.
            if url.isFileURL, let allowed = allowedFileURL,
               url.standardizedFileURL.path == allowed.standardizedFileURL.path {
                decisionHandler(.allow)
                return
            }

            // Internal WebKit navigations (e.g. about:blank) are harmless.
            if scheme == "about" {
                decisionHandler(.allow)
                return
            }

            // Anything else only reaches here if the in-page link interceptor was
            // bypassed. Hand genuine web/mail links to the system handler and
            // refuse every other navigation so the reader never leaves index.html.
            if ["http", "https", "mailto", "tel", "ftp"].contains(scheme) {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        }

        public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            // Without this the preview stays blank after a WebContent crash.
            isPageLoaded = false
            hasRenderedFirstContent = false
            renderCoordinator.handleContentProcessTerminated()
            webView.reload()
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            renderCoordinator.setWebView(webView)

            let prefsJSON = parent.preferences.jsonPayload(systemColorScheme: parent.colorScheme, focusMode: parent.focusMode)
            lastAppliedPrefsJSON = prefsJSON
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")

            // Check if window.lucid is already defined (e.g. from inline script)
            webView.evaluateJavaScript("typeof window.lucid !== 'undefined'") { [weak self] res, _ in
                if let isReady = res as? Bool, isReady {
                    self?.renderCoordinator.setBridgeReady(true)
                    self?.hasRenderedFirstContent = true
                    self?.renderCoordinator.scheduleRender(markdown: self?.parent.markdown ?? "", immediate: true)
                }
            }
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "lucidReady" {
                renderCoordinator.setBridgeReady(true)
                hasRenderedFirstContent = true
                renderCoordinator.scheduleRender(markdown: parent.markdown, immediate: true)
            } else if message.name == "lucidScroll", let body = message.body as? [String: Any] {
                if let fraction = body["fraction"] as? Double {
                    if abs(fraction - self.lastReportedFraction) >= 0.005 {
                        self.lastReportedFraction = fraction
                        self.parent.onScrollFractionChanged?(fraction)
                    }
                }

                let rawIntensity: Double
                if let intensity = body["intensity"] as? Double {
                    rawIntensity = intensity
                } else if let scrolled = body["scrolled"] as? Bool {
                    rawIntensity = scrolled ? 1.0 : 0.0
                } else {
                    rawIntensity = 0.0
                }

                // Filter sub-pixel jitter: notify only if delta > 0.04 or crosses 0.05 threshold
                let delta = abs(rawIntensity - self.lastReportedIntensity)
                let thresholdCrossing = (rawIntensity >= 0.05 && self.lastReportedIntensity < 0.05) ||
                                       (rawIntensity < 0.05 && self.lastReportedIntensity >= 0.05)
                if delta > 0.04 || thresholdCrossing {
                    self.lastReportedIntensity = rawIntensity
                    self.parent.onScrollIntensityChanged?(rawIntensity)
                }
            } else if message.name == "lucidHeadings" {
                // Accept the tagged shape { renderId, headings }; tolerate the
                // legacy bare-array shape only until tagging is active.
                var rawHeadings: [[String: Any]] = []
                var echoRevision: UInt64? = nil
                var tagged = false
                if let body = message.body as? [String: Any] {
                    rawHeadings = body["headings"] as? [[String: Any]] ?? []
                    if let rid = body["renderId"] as? String {
                        tagged = true
                        echoRevision = UInt64(rid)
                    }
                } else if let arr = message.body as? [[String: Any]] {
                    rawHeadings = arr
                }
                // Dual-writer safety: a heading echo may update `headings` ONLY when
                // its renderId belongs to the CURRENT render/document revision
                // (compared against the live PreviewRenderCoordinator revision, not
                // against the last echo). A delayed echo from a superseded render is
                // dropped, so it can never overwrite the newer text/document state.
                if tagged { hasSeenTaggedHeadings = true }
                guard HeadingEchoGate.accepts(tagged: tagged,
                                              echoRevision: echoRevision,
                                              currentRevision: renderCoordinator.currentRevision,
                                              hasSeenTagged: hasSeenTaggedHeadings) else { return }
                var parsed: [HeadingItem] = []
                for item in rawHeadings {
                    if let id = item["id"] as? String,
                       let level = item["level"] as? Int,
                       let text = item["text"] as? String {
                        parsed.append(HeadingItem(id: id, level: level, text: text))
                    }
                }
                DispatchQueue.main.async {
                    self.parent.headings = parsed
                }
            } else if message.name == "lucidActiveHeading", let body = message.body as? [String: Any] {
                let id = body["id"] as? String ?? ""
                if id.isEmpty {
                    if self.lastActiveHeadingId != nil {
                        self.lastActiveHeadingId = nil
                        DispatchQueue.main.async {
                            self.parent.activeHeading = nil
                        }
                    }
                } else if id != self.lastActiveHeadingId {
                    self.lastActiveHeadingId = id
                    let text = body["text"] as? String ?? ""
                    let level = body["level"] as? Int ?? 1
                    DispatchQueue.main.async {
                        self.parent.activeHeading = HeadingItem(id: id, level: level, text: text)
                    }
                }
            } else if message.name == "lucidFindMatches", let body = message.body as? [String: Any] {
                if let count = body["count"] as? Int,
                   let index = body["index"] as? Int {
                    parent.onFindMatchesChanged?(count, index)
                }
            } else if message.name == "lucidLinkClicked", let href = message.body as? String {
                handleLinkClick(href)
            } else if message.name == "lucidSaveSvg", let body = message.body as? [String: Any], let svgString = body["svg"] as? String {
                // ExportService is @MainActor-isolated; WKScriptMessage handlers are
                // delivered on the main thread, but the callback itself is nonisolated,
                // so hop onto the main actor explicitly to satisfy strict concurrency
                // checking on newer toolchains.
                Task { @MainActor in
                    ExportService.shared.exportSVG(svgString: svgString)
                }
            } else if message.name == "lucidPerf" {
                // Performance event received from WebEngine
            }
        }

        /// Resolves a clicked link. External URLs open in the default browser;
        /// local Markdown documents open in a Lucid window; any other local
        /// target is revealed in Finder, never opened.
        private func handleLinkClick(_ href: String) {
            let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            // External schemes → hand off to the system browser / handler.
            if let scheme = URL(string: trimmed)?.scheme?.lowercased(),
               ["http", "https", "mailto", "tel", "ftp"].contains(scheme) {
                if let url = URL(string: trimmed) {
                    NSWorkspace.shared.open(url)
                }
                return
            }

            // Local / relative reference: strip any fragment and resolve against
            // the current document's directory.
            let pathPart = trimmed.components(separatedBy: "#").first ?? trimmed
            let decoded = pathPart.removingPercentEncoding ?? pathPart
            guard !decoded.isEmpty else { return }

            let target: URL
            if decoded.hasPrefix("/") {
                target = URL(fileURLWithPath: decoded).standardizedFileURL
            } else if let baseDir = parent.documentFileURL?.deletingLastPathComponent() {
                target = URL(fileURLWithPath: decoded, relativeTo: baseDir).standardizedFileURL
            } else {
                return
            }

            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory) else {
                NSSound.beep()
                return
            }

            let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mdx", "txt"]
            if !isDirectory.boolValue && markdownExtensions.contains(target.pathExtension.lowercased()) {
                NSDocumentController.shared.openDocument(withContentsOf: target, display: true) { _, _, _ in }
            } else {
                // Document content must never launch apps, scripts or other files:
                // reveal anything that is not a Markdown document in Finder instead.
                NSWorkspace.shared.activateFileViewerSelecting([target])
            }
        }
    }
}

/// Forwards script messages to a weakly held handler, breaking the retain cycle
/// WKUserContentController would otherwise form with its handler.
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

/// Serves images referenced by the document (`lucid-asset://doc/<relative>` or
/// `lucid-asset://abs/<absolute>`, each path one percent-encoded segment, as
/// written by bridge.js). Only image files are served; anything else fails.
final class LocalAssetSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "lucid-asset"
    private let documentDirectory: () -> URL?

    init(documentDirectory: @escaping () -> URL?) {
        self.documentDirectory = documentDirectory
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let fileURL = resolve(url),
              let type = UTType(filenameExtension: fileURL.pathExtension),
              type.conforms(to: .image),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = URLResponse(
            url: url,
            mimeType: type.preferredMIMEType ?? "application/octet-stream",
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func resolve(_ url: URL) -> URL? {
        Self.resolve(url, documentDirectory: documentDirectory())
    }

    /// The file a `lucid-asset:` URL points to (relative paths against `documentDirectory`).
    static func resolve(_ url: URL, documentDirectory: URL?) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = String(components.percentEncodedPath.drop(while: { $0 == "/" })).removingPercentEncoding,
              !path.isEmpty else { return nil }
        switch components.host {
        case "abs":
            return URL(fileURLWithPath: "/" + path).standardizedFileURL
        case "doc":
            guard let base = documentDirectory else { return nil }
            return URL(fileURLWithPath: path, relativeTo: base).standardizedFileURL
        default:
            return nil
        }
    }
}
