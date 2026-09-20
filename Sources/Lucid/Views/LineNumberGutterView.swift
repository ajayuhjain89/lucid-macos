import AppKit

/// A high-performance line number gutter for NSTextView.
/// Calculates and draws line numbers strictly for the visible rect.
public final class LineNumberGutterView: NSRulerView {
    public var font: NSFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular) {
        didSet { needsDisplay = true }
    }

    public var textColor: NSColor = NSColor.secondaryLabelColor {
        didSet { needsDisplay = true }
    }

    public var activeLineNumberColor: NSColor = NSColor.labelColor {
        didSet { needsDisplay = true }
    }

    public var activeLineIndex: Int? {
        didSet {
            if oldValue != activeLineIndex {
                needsDisplay = true
            }
        }
    }

    public init(scrollView: NSScrollView) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = scrollView.documentView
        self.ruleThickness = 42
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        let visibleRect = scrollView?.contentView.bounds ?? rect
        let textString = textView.string as NSString
        let totalLength = textString.length

        // Background
        NSColor.clear.setFill()
        rect.fill()

        // Calculate visible glyph range
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        // Find the line number of the first visible character
        var lineNumber = 1
        textString.enumerateSubstrings(in: NSRange(location: 0, length: min(visibleCharRange.location, totalLength)), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let activeFont = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .medium)
        let activeAttributes: [NSAttributedString.Key: Any] = [
            .font: activeFont,
            .foregroundColor: activeLineNumberColor
        ]

        // Enumerate line fragments within the visible glyph range
        var glyphIndex = visibleGlyphRange.location
        let maxGlyphIndex = NSMaxRange(visibleGlyphRange)

        while glyphIndex < maxGlyphIndex {
            var lineFragmentRange = NSRange()
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineFragmentRange)
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

            // Only draw a line number at the start of a logical line
            let isLineStart = charIndex == 0 || textString.character(at: charIndex - 1) == 0x0A

            if isLineStart {
                let isCurrent = (activeLineIndex != nil && lineNumber == activeLineIndex)
                let numStr = "\(lineNumber)"
                let numAttrs = isCurrent ? activeAttributes : textAttributes
                let strSize = (numStr as NSString).size(withAttributes: numAttrs)

                // Align numbers right with padding
                let drawX = ruleThickness - strSize.width - 10
                let drawY = lineRect.origin.y + textView.textContainerInset.height + (lineRect.height - strSize.height) / 2

                if drawY + strSize.height >= visibleRect.origin.y && drawY <= visibleRect.origin.y + visibleRect.height {
                    (numStr as NSString).draw(at: NSPoint(x: drawX, y: drawY), withAttributes: numAttrs)
                }
                lineNumber += 1
            }

            glyphIndex = NSMaxRange(lineFragmentRange)
        }

        // Divider line on the right edge
        let dividerRect = NSRect(x: ruleThickness - 0.5, y: rect.origin.y, width: 0.5, height: rect.height)
        NSColor.separatorColor.withAlphaComponent(0.25).setFill()
        dividerRect.fill()
    }
}
