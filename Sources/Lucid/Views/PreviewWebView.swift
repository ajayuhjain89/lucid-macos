import SwiftUI
import WebKit

public struct PreviewWebView: NSViewRepresentable {
    @ObservedObject var preferences: LucidPreferences
    let markdown: String
    @Binding var headings: [HeadingItem]
    var onScrollFractionChanged: ((Double) -> Void)?
    var scrollToHeadingId: String?
    var targetScrollFraction: Double?
    @Binding var webViewInstance: WKWebView?
    @Environment(\.colorScheme) var colorScheme

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()

        userContent.add(context.coordinator, name: "lucidScroll")
        userContent.add(context.coordinator, name: "lucidHeadings")
        config.userContentController = userContent

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground") // Transparent background until theme loads

        DispatchQueue.main.async {
            self.webViewInstance = webView
        }

        // Load local WebEngine index.html
        let engineURL: URL? = {
            if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebEngine") {
                return url
            }
            if let resURL = Bundle.main.resourceURL?.appendingPathComponent("WebEngine/index.html"),
               FileManager.default.fileExists(atPath: resURL.path) {
                return resURL
            }
            // Fallback for development/direct execution
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

        // Update content if changed
        if context.coordinator.lastRenderedMarkdown != markdown {
            context.coordinator.lastRenderedMarkdown = markdown
            if let data = try? JSONEncoder().encode(markdown),
               let jsonString = String(data: data, encoding: .utf8) {
                webView.evaluateJavaScript("if (window.lucid) { window.lucid.updateContent(\(jsonString)); }")
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
        var lastRenderedMarkdown = ""
        var lastScrolledHeadingId: String?
        var lastAppliedFraction: Double = -1

        init(_ parent: PreviewWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true

            // Send initial preferences
            let prefsJSON = parent.preferences.jsonPayload(systemColorScheme: .light)
            webView.evaluateJavaScript("if (window.lucid) { window.lucid.updatePreferences(\(prefsJSON)); }")

            // Send initial markdown
            if let data = try? JSONEncoder().encode(parent.markdown),
               let jsonString = String(data: data, encoding: .utf8) {
                webView.evaluateJavaScript("if (window.lucid) { window.lucid.updateContent(\(jsonString)); }")
            }
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "lucidScroll", let body = message.body as? [String: Any], let fraction = body["fraction"] as? Double {
                parent.onScrollFractionChanged?(fraction)
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
            }
        }
    }
}
