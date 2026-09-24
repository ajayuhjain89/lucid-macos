import CoreGraphics

/// Where the editor and the preview sit for a view mode. A window keeps both
/// panes for its lifetime and switches modes by moving and hiding them, so no
/// pane is rebuilt (or its web content reloaded) on a mode switch. A hidden pane
/// keeps the shape it last had on screen, so going back to that mode (Reader ↔
/// Split, Editor ↔ Split) needs no rewrap of the text or reflow of the page.
struct PaneLayout: Equatable {
    /// The shape a pane last had on screen: the whole canvas or its Split half.
    enum Shape: Equatable {
        case full
        case split
    }

    var editor: CGRect
    var preview: CGRect
    var showsEditor: Bool
    var showsPreview: Bool

    /// 2 × 220 + the divider + the widest sidebar (320) fits the 780 pt window minimum.
    static let minPaneWidth: CGFloat = 220
    static let dividerWidth: CGFloat = 1

    init(mode: ViewMode, size: CGSize, splitFraction: CGFloat,
         hiddenEditor: Shape = .full, hiddenPreview: Shape = .full) {
        let full = CGRect(origin: .zero, size: size)
        let left = Self.editorWidth(total: size.width, fraction: splitFraction)
        let splitEditor = CGRect(x: 0, y: 0, width: left, height: size.height)
        let splitPreview = CGRect(x: left + Self.dividerWidth, y: 0,
                                  width: max(0, size.width - left - Self.dividerWidth), height: size.height)
        switch mode {
        case .reader:
            editor = hiddenEditor == .split ? splitEditor : full
            preview = full
            showsEditor = false
            showsPreview = true
        case .editor:
            editor = full
            preview = hiddenPreview == .split ? splitPreview : full
            showsEditor = true
            showsPreview = false
        case .split:
            editor = splitEditor
            preview = splitPreview
            showsEditor = true
            showsPreview = true
        }
    }

    /// The Split editor width for a divider at `fraction` of the space left of
    /// the divider, keeping both panes at least `minPaneWidth` when they fit.
    static func editorWidth(total: CGFloat, fraction: CGFloat) -> CGFloat {
        let available = max(0, total - dividerWidth)
        guard available > 2 * minPaneWidth else { return (available / 2).rounded() }
        let wanted = (available * min(max(fraction, 0), 1)).rounded()
        return min(max(wanted, minPaneWidth), available - minPaneWidth)
    }

    /// The fraction that puts the divider at `editorWidth`, clamped like `editorWidth(total:fraction:)`.
    static func fraction(forEditorWidth editorWidth: CGFloat, total: CGFloat) -> CGFloat {
        let available = total - dividerWidth
        guard available > 0 else { return 0.5 }
        return self.editorWidth(total: total, fraction: editorWidth / available) / available
    }
}
