import Foundation
import Combine

/// Coalesced, cancellable, off-main document analysis.
///
/// Typing must never wait for the O(n) document metrics scan or the Markdown
/// outline parse. `DocumentAnalyzer` moves both off the main thread while keeping
/// all published SwiftUI state mutations on the `MainActor`:
///
///   text snapshot + revision
///     → compute (word/char/reading-time  |  headings) off the MainActor
///     → verify the revision is still current
///     → publish on the MainActor
///
/// Rapid typing coalesces via a short debounce and cancels superseded work, so
/// there is at most one in-flight job per pipeline and stale results can never
/// replace a newer revision. This is intentionally *not* a debounce of the text
/// mutation itself — only of the derived, non-instantaneous analysis.
@MainActor
public final class DocumentAnalyzer: ObservableObject {
    // Published, display-facing state. Mutated only on the MainActor.
    @Published public private(set) var wordCount: Int = 0
    @Published public private(set) var charCount: Int = 0
    @Published public private(set) var readingTimeMinutes: Int = 1
    /// Headings are also written by the WebEngine (`lucidHeadings`), so this stays
    /// publicly settable and is exposed to the view as a binding.
    @Published public var headings: [HeadingItem] = []

    // Lightweight observability counters (Ints; no measurable cost). Useful for
    // validation and telemetry: started == completed + cancelled (± in-flight).
    public private(set) var metricsStarted = 0
    public private(set) var metricsCompleted = 0
    public private(set) var metricsCancelled = 0
    public private(set) var outlineStarted = 0
    public private(set) var outlineCompleted = 0
    public private(set) var outlineCancelled = 0

    private var metricsRevision: UInt64 = 0
    private var outlineRevision: UInt64 = 0
    private var metricsTask: Task<Void, Never>?
    private var outlineTask: Task<Void, Never>?

    private let metricsDebounceNanos: UInt64
    private let outlineDebounceNanos: UInt64

    /// - Parameters:
    ///   - metricsDebounceMs: coalescing window for status metrics.
    ///   - outlineDebounceMs: coalescing window for the outline.
    public init(metricsDebounceMs: UInt64 = 120, outlineDebounceMs: UInt64 = 90) {
        self.metricsDebounceNanos = metricsDebounceMs * 1_000_000
        self.outlineDebounceNanos = outlineDebounceMs * 1_000_000
    }

    /// Initial-open / mode-switch path: analyze promptly (no debounce) but still
    /// off the main thread, so the outline and metrics appear without a stall.
    public func prime(text: String) {
        scheduleMetrics(text, debounce: false)
        scheduleOutline(text, debounce: false)
    }

    /// Typing path: coalesced + cancellable. Returns immediately; the main thread
    /// never runs the scan/parse.
    public func update(text: String) {
        scheduleMetrics(text, debounce: true)
        scheduleOutline(text, debounce: true)
    }

    /// Document switch/close: cancel in-flight work and invalidate revisions so no
    /// stale result from the previous document can publish.
    public func reset() {
        metricsRevision &+= 1
        outlineRevision &+= 1
        metricsTask?.cancel(); metricsTask = nil
        outlineTask?.cancel(); outlineTask = nil
    }

    // MARK: - Metrics pipeline

    private func scheduleMetrics(_ text: String, debounce: Bool) {
        metricsRevision &+= 1
        let rev = metricsRevision
        metricsTask?.cancel()
        metricsStarted += 1
        metricsTask = Task { [weak self] in
            guard let self else { return }
            if debounce {
                try? await Task.sleep(nanoseconds: self.metricsDebounceNanos)
            }
            if Task.isCancelled { self.metricsCancelled += 1; return }
            // Off-MainActor CPU work (nonisolated async).
            let result = await DocumentAnalyzer.computeMetrics(text)
            if Task.isCancelled { self.metricsCancelled += 1; return }
            guard rev == self.metricsRevision else { self.metricsCancelled += 1; return }
            self.charCount = result.chars
            self.wordCount = result.words
            self.readingTimeMinutes = result.readingTime
            self.metricsCompleted += 1
        }
    }

    // MARK: - Outline pipeline

    private func scheduleOutline(_ text: String, debounce: Bool) {
        outlineRevision &+= 1
        let rev = outlineRevision
        outlineTask?.cancel()
        outlineStarted += 1
        outlineTask = Task { [weak self] in
            guard let self else { return }
            if debounce {
                try? await Task.sleep(nanoseconds: self.outlineDebounceNanos)
            }
            if Task.isCancelled { self.outlineCancelled += 1; return }
            // Off-MainActor CPU work; reuses the existing MarkdownOutlineParser.
            let parsed = await DocumentAnalyzer.computeOutline(text)
            if Task.isCancelled { self.outlineCancelled += 1; return }
            guard rev == self.outlineRevision else { self.outlineCancelled += 1; return }
            // An empty outline is a valid result: a document with zero headings
            // must clear the sidebar. Staleness is determined ONLY by cancellation
            // and revision above — never by treating "empty" as stale.
            self.headings = parsed
            self.outlineCompleted += 1
        }
    }

    // MARK: - Pure off-main computations

    /// Reading time derives from the SAME word count, preserving existing semantics
    /// (word count filtered on whitespace boundaries; reading time = ceil(words/200)).
    nonisolated static func computeMetrics(_ text: String) async -> (chars: Int, words: Int, readingTime: Int) {
        let chars = text.count
        var count = 0
        var inWord = false
        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                if inWord { count += 1; inWord = false }
            } else {
                inWord = true
            }
        }
        if inWord { count += 1 }
        let readingTime = max(1, Int(ceil(Double(count) / 200.0)))
        return (chars, count, readingTime)
    }

    nonisolated static func computeOutline(_ text: String) async -> [HeadingItem] {
        MarkdownOutlineParser.parse(markdown: text)
    }
}
