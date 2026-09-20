import SwiftUI
import AppKit

public struct EditorView: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var preferences: LucidPreferences
    var onScrollFractionChanged: ((Double) -> Void)?
    var onCursorPositionChanged: ((Int, Int) -> Void)? // (line, column)
    var onTextViewCreated: ((NSTextView) -> Void)?
    var onScrollIntensityChanged: ((Double) -> Void)?

    public init(
        text: Binding<String>,
        preferences: LucidPreferences = .shared,
        onScrollFractionChanged: ((Double) -> Void)? = nil,
        onCursorPositionChanged: ((Int, Int) -> Void)? = nil,
        onTextViewCreated: ((NSTextView) -> Void)? = nil,
        onScrollIntensityChanged: ((Double) -> Void)? = nil
    ) {
        self._text = text
        self.preferences = preferences
        self.onScrollFractionChanged = onScrollFractionChanged
        self.onCursorPositionChanged = onCursorPositionChanged
        self.onTextViewCreated = onTextViewCreated
        self.onScrollIntensityChanged = onScrollIntensityChanged
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = LucidTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.preferences = preferences

        // Apply initial typography
        applyTypography(to: textView)

        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true

        // Expose the text view so document-level actions (e.g. Insert Template)
        // can target the single source-of-truth editor.
        DispatchQueue.main.async { [weak textView] in
            if let textView = textView { self.onTextViewCreated?(textView) }
        }

        // Attach Line Number Gutter
        let gutter = LineNumberGutterView(scrollView: scrollView)
        scrollView.verticalRulerView = gutter
        scrollView.hasVerticalRuler = preferences.lineNumbers
        scrollView.rulersVisible = preferences.lineNumbers
        context.coordinator.gutterView = gutter

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? LucidTextView else { return }

        // Update preferences reference
        textView.preferences = preferences

        // Update gutter visibility
        if scrollView.hasVerticalRuler != preferences.lineNumbers {
            scrollView.hasVerticalRuler = preferences.lineNumbers
            scrollView.rulersVisible = preferences.lineNumbers
        }

        // Apply updated typography
        applyTypography(to: textView)

        // Update text only if modified externally without disturbing selection
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.gutterView?.needsDisplay = true
        }

        textView.needsDisplay = true
    }

    private func applyTypography(to textView: LucidTextView) {
        let font = preferences.fontFamily.nsFont(
            size: CGFloat(preferences.fontSize),
            customName: preferences.customFontName
        )
        textView.font = font
        textView.insertionPointColor = NSColor(Color(hex: preferences.accentColor))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat((preferences.lineHeight - 1.0) * preferences.fontSize)
        textView.defaultParagraphStyle = paragraphStyle

        // Dynamic padding based on content width with editorial breathing room.
        // The top inset clears the floating glass toolbar so the first line sits
        // below it at rest and scrolls beneath it (matching the reader).
        let horizontalPadding: CGFloat = 32
        textView.textContainerInset = NSSize(width: horizontalPadding, height: LucidChrome.contentTopInset)

        if let gutter = (textView.enclosingScrollView?.verticalRulerView as? LineNumberGutterView) {
            gutter.font = NSFont.monospacedSystemFont(ofSize: max(10, CGFloat(preferences.fontSize * 0.65)), weight: .regular)
        }
    }

    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var gutterView: LineNumberGutterView?

        init(_ parent: EditorView) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? LucidTextView else { return }
            parent.text = textView.string
            gutterView?.needsDisplay = true
            updateCursorInfo(textView)
        }

        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? LucidTextView else { return }
            updateCursorInfo(textView)
            textView.updateCurrentLineHighlight()
        }

        private func updateCursorInfo(_ textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            let string = textView.string as NSString
            let location = min(selectedRange.location, string.length)

            var line = 1
            var col = 1
            var lastLineStart = 0

            string.enumerateSubstrings(in: NSRange(location: 0, length: location), options: [.byLines, .substringNotRequired]) { _, range, _, _ in
                line += 1
                lastLineStart = NSMaxRange(range)
            }
            col = location - lastLineStart + 1

            gutterView?.activeLineIndex = line
            parent.onCursorPositionChanged?(line, col)
        }

        @objc func boundsDidChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView,
                  let documentView = clipView.documentView else { return }
            let maxScroll = documentView.bounds.height - clipView.bounds.height
            if maxScroll > 0 {
                let fraction = clipView.bounds.origin.y / maxScroll
                parent.onScrollFractionChanged?(Double(fraction))
            }
            let intensity = min(1, max(0, Double(clipView.bounds.origin.y) / 22))
            parent.onScrollIntensityChanged?(intensity)
            gutterView?.needsDisplay = true
        }
    }
}

/// Custom NSTextView providing low-cost current-line highlight and context-aware auto-pairing.
public final class LucidTextView: NSTextView {
    public var preferences: LucidPreferences?
    private var previousActiveLineRect: NSRect?

    // MARK: - Drawing: Current-Line Highlight
    public func updateCurrentLineHighlight() {
        guard let preferences = preferences, preferences.highlightCurrentLine else {
            if previousActiveLineRect != nil {
                setNeedsDisplay(previousActiveLineRect!)
                previousActiveLineRect = nil
            }
            return
        }

        guard let layoutManager = layoutManager else { return }
        let selectedRange = selectedRange()
        let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)

        // Expand to full container width
        lineRect.origin.x = 0
        lineRect.size.width = bounds.width
        lineRect.origin.y += textContainerInset.height

        // Invalidate old and new rects with minimal redraw impact
        if let prev = previousActiveLineRect, prev != lineRect {
            setNeedsDisplay(prev)
        }
        previousActiveLineRect = lineRect
        setNeedsDisplay(lineRect)
    }

    override public func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)

        guard let preferences = preferences, preferences.highlightCurrentLine,
              let activeRect = previousActiveLineRect else { return }

        let highlightColor = NSColor.textColor.withAlphaComponent(0.035)
        highlightColor.setFill()
        activeRect.intersection(rect).fill()
    }

    // MARK: - Context-Aware Auto-Pairing & Delimiter Handling
    override public func insertText(_ string: Any, replacementRange: NSRange) {
        guard let str = string as? String, let preferences = preferences, preferences.autoPairDelimiters else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        let currentString = self.string as NSString
        let selectedRange = self.selectedRange()

        // 1. Step-over existing closing delimiter
        let closingDelimiters: Set<String> = [")", "]", "}", "\"", "`", "*", "_"]
        if closingDelimiters.contains(str),
           selectedRange.length == 0,
           selectedRange.location < currentString.length {
            let nextChar = currentString.substring(with: NSRange(location: selectedRange.location, length: 1))
            if nextChar == str {
                setSelectedRange(NSRange(location: selectedRange.location + 1, length: 0))
                return
            }
        }

        // 2. Wrap selected text with delimiters
        let pairMap: [String: (open: String, close: String)] = [
            "(": ("(", ")"),
            "[": ("[", "]"),
            "{": ("{", "}"),
            "\"": ("\"", "\""),
            "`": ("`", "`"),
            "*": ("*", "*"),
            "_": ("_", "_")
        ]

        if let pair = pairMap[str], selectedRange.length > 0 {
            let selectedText = currentString.substring(with: selectedRange)
            let wrapped = pair.open + selectedText + pair.close
            super.insertText(wrapped, replacementRange: selectedRange)
            setSelectedRange(NSRange(location: selectedRange.location + pair.open.count, length: selectedText.count))
            return
        }

        // 3. Auto-pair open delimiters
        if let pair = pairMap[str], selectedRange.length == 0 {
            // Only auto-pair quotes, asterisks, backticks if not in the middle of an identifier
            var shouldPair = true
            if str == "\"" || str == "`" || str == "*" || str == "_" {
                if selectedRange.location < currentString.length {
                    let nextChar = currentString.substring(with: NSRange(location: selectedRange.location, length: 1))
                    if !nextChar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !closingDelimiters.contains(nextChar) {
                        shouldPair = false
                    }
                }
            }

            if shouldPair {
                super.insertText(pair.open + pair.close, replacementRange: selectedRange)
                setSelectedRange(NSRange(location: selectedRange.location + pair.open.count, length: 0))
                return
            }
        }

        // 4. Auto-indentation on Return
        if str == "\n", preferences.autoIndent {
            let lineRange = currentString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let currentLine = currentString.substring(with: lineRange)
            let leadingWhitespace = currentLine.prefix { $0 == " " || $0 == "\t" }

            // Check for list markers
            let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
            var indentPrefix = String(leadingWhitespace)

            if trimmed.hasPrefix("- [ ] ") {
                indentPrefix += "- [ ] "
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                indentPrefix += "- "
            }

            super.insertText("\n" + indentPrefix, replacementRange: selectedRange)
            return
        }

        super.insertText(string, replacementRange: replacementRange)
    }

    // MARK: - Backspace in Empty Pair Deletion
    override public func deleteBackward(_ sender: Any?) {
        let selectedRange = self.selectedRange()
        let currentString = self.string as NSString

        if selectedRange.length == 0 && selectedRange.location > 0 && selectedRange.location < currentString.length {
            let prevChar = currentString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
            let nextChar = currentString.substring(with: NSRange(location: selectedRange.location, length: 1))

            let pairs: [(String, String)] = [
                ("(", ")"), ("[", "]"), ("{", "}"), ("\"", "\""), ("`", "`"), ("*", "*"), ("_", "_")
            ]

            for (open, close) in pairs {
                if prevChar == open && nextChar == close {
                    super.deleteBackward(sender)
                    super.deleteForward(sender)
                    return
                }
            }
        }

        super.deleteBackward(sender)
    }
}
