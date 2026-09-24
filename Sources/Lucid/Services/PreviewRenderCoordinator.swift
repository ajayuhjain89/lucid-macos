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
    /// When the current burst of edits started waiting for a render (nil = none pending).
    private var burstStartedAt: UInt64? = nil

    /// Longest the preview may lag behind continuous typing. The trailing debounce
    /// alone restarts on every keystroke, so a steady typist never saw an update.
    public static let maxRenderWaitMilliseconds: UInt64 = 600

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

    /// The web content process died (crash or memory pressure). Queue the last
    /// document so it renders again once the reloaded page reports ready.
    public func handleContentProcessTerminated() {
        isBridgeReady = false
        hasRenderedInitialContent = false
        pendingTask?.cancel()
        if pendingMarkdown == nil {
            pendingMarkdown = lastRenderedMarkdown
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
            burstStartedAt = nil
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
            // Debounced dispatch for interactive typing, capped so a render still
            // happens at least every maxRenderWaitMilliseconds while typing continues.
            let now = DispatchTime.now().uptimeNanoseconds
            let startedAt = burstStartedAt ?? now
            burstStartedAt = startedAt
            let waitedMs = (now - startedAt) / 1_000_000
            let remainingMs = Self.maxRenderWaitMilliseconds > waitedMs ? Self.maxRenderWaitMilliseconds - waitedMs : 0
            let delayMs = min(debounceMilliseconds, remainingMs)
            pendingTask = Task { @MainActor in
                if delayMs > 0 {
                    try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
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
        burstStartedAt = nil
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
                } else if let error {
                    // The page is alive but this render threw. Keep the bridge
                    // ready so the next edit renders again; marking it not
                    // ready here froze the preview for good (nothing re-sends
                    // lucidReady on a loaded page).
                    NSLog("Lucid preview render failed: %@", error.localizedDescription)
                } else {
                    // The bridge isn't on the page yet; re-queue for its ready handshake.
                    self.isBridgeReady = false
                    self.pendingMarkdown = markdown
                }
            }
        }
    }
}
