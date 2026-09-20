import SwiftUI
import WebKit
import AppKit

public struct PreviewWebView: NSViewRepresentable {
    @ObservedObject var preferences: LucidPreferences
    let markdown: String
    @Binding var headings: [HeadingItem]
    @Binding var activeHeading: HeadingItem?
    var onScrollFractionChanged: ((Double) -> Void)?
    var onFindMatchesChanged: ((Int, Int) -> Void)?
    var scrollToHeadingId: String?
    var targetScrollFraction: Double?
    @Binding var webViewInstance: WKWebView?
    /// The on-disk location of the document being previewed, used to resolve
    /// relative links to sibling files when the reader clicks a cross-file link.
    var documentFileURL: URL? = nil
    /// Reports a graduated 0…1 intensity of how far the content has scrolled away
    /// from the top, so the chrome can raise its glass depth almost subconsciously.
    var onScrollIntensityChanged: ((Double) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
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

        userContent.add(context.coordinator, name: "lucidReady")
        userContent.add(context.coordinator, name: "lucidScroll")
        userContent.add(context.coordinator, name: "lucidHeadings")
        userContent.add(context.coordinator, name: "lucidActiveHeading")
        userContent.add(context.coordinator, name: "lucidFindMatches")
        userContent.add(context.coordinator, name: "lucidLinkClicked")
        userContent.add(context.coordinator, name: "lucidSaveSvg")
        userContent.add(context.coordinator, name: "lucidPerf")
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

        DispatchQueue.main.async {
            self.webViewInstance = webView
        }

        let engineURL: URL? = {
            if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebEngine") {
                return url
            }
            if let resURL = Bundle.main.resourceURL?.appendingPathComponent("WebEngine/index.html"),
               FileManager.default.fileExists(atPath: resURL.path) {
                return resURL
            }
            let devURL = URL(fileURLWithPath: "/Users/ayushjain/lucid-macos/Sources/Lucid/Resources/WebEngine/index.html")
            if FileManager.default.fileExists(atPath: devURL.path) {
                return devURL
            }
            return nil
        }()

        if let indexURL = engineURL {
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        }

        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        let tokens = preferences.theme.themeTokens
        webView.underPageBackgroundColor = NSColor(Color(hex: tokens.previewBackground))

        // Update preferences
        let prefsJSON = preferences.jsonPayload(systemColorScheme: colorScheme)
        webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")

        // Schedule render: immediate on first load or file change, debounced on interactive typing
        let isFirstRender = !context.coordinator.hasRenderedFirstContent
        let isNewContent = context.coordinator.lastRenderedMarkdown != markdown
        if isFirstRender || isNewContent {
            context.coordinator.lastRenderedMarkdown = markdown
            context.coordinator.renderCoordinator.scheduleRender(markdown: markdown, immediate: isFirstRender)
            if isFirstRender && context.coordinator.renderCoordinator.isBridgeReady {
                context.coordinator.hasRenderedFirstContent = true
            }
        }

        // Scroll to heading if requested
        if let headingId = scrollToHeadingId, headingId != context.coordinator.lastScrolledHeadingId {
            context.coordinator.lastScrolledHeadingId = headingId
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.scrollToHeading('\(headingId)'); }")
        }

        // Sync scroll fraction if requested
        if let fraction = targetScrollFraction, abs(fraction - context.coordinator.lastAppliedFraction) > 0.02 {
            context.coordinator.lastAppliedFraction = fraction
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.setScrollFraction(\(fraction)); }")
        }
    }

    public final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: PreviewWebView
        var isPageLoaded = false
        var hasRenderedFirstContent = false
        var lastRenderedMarkdown = ""
        var lastScrolledHeadingId: String?
        var lastAppliedFraction: Double = -1
        /// Whether any revision-tagged heading echo has been seen. Once tagging is
        /// active, an untagged (legacy) echo must not bypass revision safety.
        var hasSeenTaggedHeadings: Bool = false
        let renderCoordinator = PreviewRenderCoordinator()

        init(_ parent: PreviewWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            renderCoordinator.setWebView(webView)

            let prefsJSON = parent.preferences.jsonPayload(systemColorScheme: parent.colorScheme)
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
                    parent.onScrollFractionChanged?(fraction)
                }
                if let intensity = body["intensity"] as? Double {
                    parent.onScrollIntensityChanged?(intensity)
                } else if let scrolled = body["scrolled"] as? Bool {
                    parent.onScrollIntensityChanged?(scrolled ? 1 : 0)
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
                if let id = body["id"] as? String,
                   let text = body["text"] as? String,
                   let level = body["level"] as? Int {
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
        /// relative references to sibling documents open in a Lucid window.
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

            guard FileManager.default.fileExists(atPath: target.path) else {
                NSSound.beep()
                return
            }

            let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mdx", "txt"]
            if markdownExtensions.contains(target.pathExtension.lowercased()) {
                NSDocumentController.shared.openDocument(withContentsOf: target, display: true) { _, _, _ in }
            } else {
                NSWorkspace.shared.open(target)
            }
        }
    }
}
