import Foundation

/// Pure decision for whether an incoming `lucidHeadings` echo from the WebEngine
/// may update the shared `headings`.
///
/// Invariant: a heading echo may update `headings` ONLY when its renderId belongs
/// to the currently valid render/document state — i.e. it must equal the live
/// `PreviewRenderCoordinator.currentRevision`, NOT merely be newer than the last
/// applied echo. A delayed echo from a superseded render (e.g. revision 10 arriving
/// after the user advanced the document to revision 11) is rejected.
///
/// Extracted as a standalone pure function so it is the single source of truth for
/// both the live handler (`PreviewWebView.Coordinator`) and its verification test.
public enum HeadingEchoGate {
    /// - Parameters:
    ///   - tagged: whether the echo carried a `renderId` (revision-tagged shape).
    ///   - echoRevision: the parsed revision from the echo's `renderId`, if numeric.
    ///   - currentRevision: the live `PreviewRenderCoordinator.currentRevision`.
    ///   - hasSeenTagged: whether a tagged echo has ever been observed on this view.
    /// - Returns: `true` iff the echo may update `headings`.
    public static func accepts(tagged: Bool,
                               echoRevision: UInt64?,
                               currentRevision: UInt64,
                               hasSeenTagged: Bool) -> Bool {
        if tagged {
            // Must belong to the current render/document revision.
            guard let rev = echoRevision, rev == currentRevision else { return false }
            return true
        }
        // Untagged (legacy) echo: allowed only before tagging is active; once tagged
        // messages are seen it can never bypass revision safety.
        return !hasSeenTagged
    }
}
