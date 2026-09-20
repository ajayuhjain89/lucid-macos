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

        userContent.add(context.coordinator, name: "lucidScroll")
        userContent.add(context.coordinator, name: "lucidHeadings")
        userContent.add(context.coordinator, name: "lucidActiveHeading")
        userContent.add(context.coordinator, name: "lucidFindMatches")
        userContent.add(context.coordinator, name: "lucidLinkClicked")
        config.userContentController = userContent

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

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

        guard context.coordinator.isPageLoaded else { return }

        // Update preferences
        let prefsJSON = preferences.jsonPayload(systemColorScheme: colorScheme)
        webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")

        // Schedule debounced render through the coordinator
        context.coordinator.renderCoordinator.scheduleRender(markdown: markdown)

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
        var lastScrolledHeadingId: String?
        var lastAppliedFraction: Double = -1
        let renderCoordinator = PreviewRenderCoordinator()

        init(_ parent: PreviewWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            renderCoordinator.setWebView(webView)

            let prefsJSON = parent.preferences.jsonPayload(systemColorScheme: .dark)
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")

            renderCoordinator.scheduleRender(markdown: parent.markdown, immediate: true)
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "lucidScroll", let body = message.body as? [String: Any] {
                if let fraction = body["fraction"] as? Double {
                    parent.onScrollFractionChanged?(fraction)
                }
                if let intensity = body["intensity"] as? Double {
                    parent.onScrollIntensityChanged?(intensity)
                } else if let scrolled = body["scrolled"] as? Bool {
                    parent.onScrollIntensityChanged?(scrolled ? 1 : 0)
                }
            } else if message.name == "lucidHeadings", let body = message.body as? [[String: Any]] {
                var parsed: [HeadingItem] = []
                for item in body {
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
