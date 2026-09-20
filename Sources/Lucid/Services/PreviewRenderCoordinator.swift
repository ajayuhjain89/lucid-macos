import Foundation
import Combine
import WebKit

/// Coordinates asynchronous preview rendering, debouncing, task cancellation,
/// and document revision equality checking.
@MainActor
public final class PreviewRenderCoordinator: ObservableObject {
    public private(set) var currentRevision: UInt64 = 0
    private var pendingTask: Task<Void, Never>?
    private weak var webView: WKWebView?
    private var lastRenderedMarkdown: String = ""

    public init() {}

    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }

    /// Request rendering for an updated document string.
    public func scheduleRender(
        markdown: String,
        debounceMilliseconds: UInt64 = 150,
        immediate: Bool = false
    ) {
        // Increment monotonic document revision
        currentRevision &+= 1
        let targetRevision = currentRevision

        // Cancel previous pending task if any
        pendingTask?.cancel()

        guard markdown != lastRenderedMarkdown else { return }

        pendingTask = Task { @MainActor in
            if !immediate && debounceMilliseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            }

            // Verify task was not cancelled during sleep
            if Task.isCancelled { return }

            // Verify strict revision equality
            guard targetRevision == self.currentRevision else { return }

            self.lastRenderedMarkdown = markdown
            self.dispatchRender(markdown: markdown, revision: targetRevision)
        }
    }

    private func dispatchRender(markdown: String, revision: UInt64) {
        guard let webView = webView else { return }

        let payload: [String: Any] = [
            "type": "updateContent",
            "revision": revision,
            "markdown": markdown
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            webView.evaluateJavaScript("if (window.lucid && window.lucid.handleMessage) { window.lucid.handleMessage(\(jsonString)); }")
        }
    }
}
