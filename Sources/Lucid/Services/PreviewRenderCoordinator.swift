import Foundation
import Combine
import WebKit

/// Coordinates asynchronous preview rendering, debouncing, task cancellation,
/// and document revision equality checking.
///
/// Intentionally not `@MainActor`-isolated at the type level: it is only ever
/// used from the main thread (WKNavigationDelegate callbacks and
/// NSViewRepresentable methods), and its debounced render already hops to the
/// main actor via `Task { @MainActor in … }`. Keeping the type nonisolated avoids
/// actor-crossing errors when built against SDKs that annotate WebKit/SwiftUI as
/// `@MainActor`, while behaving identically at runtime.
public final class PreviewRenderCoordinator: ObservableObject {
    public private(set) var currentRevision: UInt64 = 0
    public private(set) var isBridgeReady: Bool = false
    private var pendingTask: Task<Void, Never>?
    private weak var webView: WKWebView?
    private var lastRenderedMarkdown: String = ""
    private var pendingMarkdown: String? = nil
    private var hasRenderedInitialContent: Bool = false

    public init() {}

    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }

    public func setBridgeReady(_ ready: Bool) {
        self.isBridgeReady = ready
        if ready, let pending = pendingMarkdown {
            pendingMarkdown = nil
            scheduleRender(markdown: pending, immediate: true)
        }
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

        // If not an immediate/forced render, skip if markdown has not changed
        if !immediate && markdown == lastRenderedMarkdown {
            return
        }

        // If the web engine bridge is not yet ready, queue this markdown and await the handshake
        guard isBridgeReady else {
            pendingMarkdown = markdown
            return
        }

        if immediate || !hasRenderedInitialContent {
            // Immediate dispatch for initial open, file switches, or bridge-ready handshakes
            self.lastRenderedMarkdown = markdown
            self.hasRenderedInitialContent = true
            self.dispatchRender(markdown: markdown, revision: targetRevision)
        } else {
            // Debounced dispatch for interactive typing
            pendingTask = Task { @MainActor in
                if debounceMilliseconds > 0 {
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
    }

    private func dispatchRender(markdown: String, revision: UInt64) {
        guard let webView = webView else { return }

        let payload: [String: Any] = [
            "type": "updateContent",
            "revision": revision,
            "renderId": "\(revision)",
            "markdown": markdown
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            let script = "if (window.lucid && window.lucid.handleMessage) { window.lucid.handleMessage(\(jsonString)); true; } else { false; }"
            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self else { return }
                if let success = result as? Bool, success {
                    // Successfully delivered
                } else {
                    // Bridge was not actually ready to receive; re-queue for when bridge reports ready
                    self.isBridgeReady = false
                    self.pendingMarkdown = markdown
                }
            }
        }
    }
}
