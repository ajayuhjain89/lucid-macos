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
        let tokens = preferences.theme.themeTokens
        let bgColor = NSColor(Color(hex: tokens.editorBackground))
        let fgColor = NSColor(Color(hex: tokens.textPrimary))
        let selColor = NSColor(Color(hex: tokens.selection))

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !preferences.wordWrap
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = bgColor

        // Start at the clip view's real width. Width autoresizing preserves the
        // initial difference, so any larger placeholder here would leave the text
        // view permanently wider than its pane (lines hidden, sideways scrolling).
        let initialWidth = scrollView.contentSize.width
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(containerSize: NSSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude))
        if preferences.wordWrap {
            textContainer.widthTracksTextView = true
        } else {
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        layoutManager.addTextContainer(textContainer)

        let textView = LucidTextView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: 1000), textContainer: textContainer)
        textView.strongTextStorage = textStorage
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !preferences.wordWrap
        textView.autoresizingMask = preferences.wordWrap ? [.width] : []
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.drawsBackground = true
        textView.backgroundColor = bgColor
        textView.textColor = fgColor
        textView.selectedTextAttributes = [
            .backgroundColor: selColor,
            .foregroundColor: fgColor
        ]
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
        gutter.backgroundColor = bgColor
        gutter.textColor = NSColor(Color(hex: tokens.textTertiary))
        gutter.activeLineNumberColor = fgColor
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
        // Keep callbacks (scroll fraction, cursor, text binding) pointing at the
        // current view values rather than the ones captured at creation.
        context.coordinator.parent = self

        // Update preferences reference
        textView.preferences = preferences

        // Update gutter visibility
        if scrollView.hasVerticalRuler != preferences.lineNumbers {
            scrollView.hasVerticalRuler = preferences.lineNumbers
            scrollView.rulersVisible = preferences.lineNumbers
        }

        // Update word wrap
        if let textContainer = textView.textContainer, textContainer.widthTracksTextView != preferences.wordWrap {
            let savedSelectedRanges = textView.selectedRanges
            let savedVisibleOrigin = scrollView.contentView.bounds.origin

            if preferences.wordWrap {
                scrollView.hasHorizontalScroller = false
                textView.isHorizontallyResizable = false
                textView.autoresizingMask = [.width]
                textContainer.widthTracksTextView = true
                textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
                textView.setFrameSize(NSSize(width: scrollView.contentSize.width, height: textView.frame.height))
            } else {
                scrollView.hasHorizontalScroller = true
                textView.isHorizontallyResizable = true
                textView.autoresizingMask = []
                textContainer.widthTracksTextView = false
                textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }

            textView.layoutManager?.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textView.string.count), actualCharacterRange: nil)
            textView.selectedRanges = savedSelectedRanges
            scrollView.contentView.bounds.origin = savedVisibleOrigin
            context.coordinator.gutterView?.needsDisplay = true
        }

        let tokens = preferences.theme.themeTokens
        let bgColor = NSColor(Color(hex: tokens.editorBackground))
        let fgColor = NSColor(Color(hex: tokens.textPrimary))
        let selColor = NSColor(Color(hex: tokens.selection))

        if scrollView.backgroundColor != bgColor {
            scrollView.backgroundColor = bgColor
        }
        if textView.backgroundColor != bgColor {
            textView.backgroundColor = bgColor
        }
        if textView.textColor != fgColor {
            textView.textColor = fgColor
        }
        textView.selectedTextAttributes = [
            .backgroundColor: selColor,
            .foregroundColor: fgColor
        ]

        if let gutter = context.coordinator.gutterView {
            gutter.backgroundColor = bgColor
            gutter.textColor = NSColor(Color(hex: tokens.textTertiary))
            gutter.activeLineNumberColor = fgColor
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
        let tokens = preferences.theme.themeTokens
        let font = preferences.fontFamily.nsFont(
            size: CGFloat(preferences.fontSize),
            customName: preferences.customFontName
        )
        let fgColor = NSColor(Color(hex: tokens.textPrimary))
        textView.font = font
        textView.textColor = fgColor
        textView.insertionPointColor = NSColor(Color(hex: tokens.cursor))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat((preferences.lineHeight - 1.0) * preferences.fontSize)
        textView.defaultParagraphStyle = paragraphStyle

        // Dynamic padding based on content width with editorial breathing room.
        // The top inset clears the floating glass toolbar so the first line sits
        // below it at rest and scrolls beneath it (matching the reader).
        let horizontalPadding: CGFloat = 32
        textView.textContainerInset = NSSize(width: horizontalPadding, height: LucidChrome.contentTopInset)

        if let textStorage = textView.textStorage, textStorage.length > 0 {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.addAttribute(.font, value: font, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: fgColor, range: fullRange)
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        }

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
            // Measure in document coordinates: the text view's frame origin is not
            // always 0 inside the clip view, so clipView.bounds.origin is not the
            // scroll offset (it produced negative fractions and broke split sync).
            let visible = clipView.documentVisibleRect
            let offset = visible.minY - documentView.bounds.minY
            let maxScroll = documentView.bounds.height - visible.height
            if maxScroll > 0 {
                let fraction = min(1, max(0, offset / maxScroll))
                parent.onScrollFractionChanged?(Double(fraction))
            }
            let intensity = min(1, max(0, Double(offset) / 28))
            parent.onScrollIntensityChanged?(intensity)
            gutterView?.needsDisplay = true
        }
    }
}

/// Custom NSTextView providing low-cost current-line highlight and context-aware auto-pairing.
public final class LucidTextView: NSTextView {
    public var preferences: LucidPreferences?
    public var strongTextStorage: NSTextStorage?
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

        // A space inside an empty `*`/`_` pair means a bullet ("* ") or spaced
        // arithmetic ("a * b"), not emphasis: drop the auto-inserted closer.
        if str == " ", selectedRange.length == 0,
           selectedRange.location > 0, selectedRange.location < currentString.length {
            let prevChar = currentString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
            let nextChar = currentString.substring(with: NSRange(location: selectedRange.location, length: 1))
            if (prevChar == "*" || prevChar == "_") && nextChar == prevChar {
                super.insertText(" ", replacementRange: NSRange(location: selectedRange.location, length: 1))
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
            setSelectedRange(NSRange(location: selectedRange.location + (pair.open as NSString).length, length: (selectedText as NSString).length))
            return
        }

        // 3. Auto-pair open delimiters
        if let pair = pairMap[str], selectedRange.length == 0 {
            // Only auto-pair quotes, asterisks, backticks if not in the middle of an identifier
            var shouldPair = true
            if str == "\"" || str == "`" || str == "*" || str == "_" {
                // Symmetric delimiters don't pair right after a word character
                // (snake_case, x*y, don"t) or inside a run of the same delimiter
                // (a ``` fence, **bold**), where a closer would be left behind.
                if selectedRange.location > 0 {
                    let prevChar = currentString.substring(with: NSRange(location: selectedRange.location - 1, length: 1))
                    if prevChar == str || prevChar.rangeOfCharacter(from: .alphanumerics) != nil {
                        shouldPair = false
                    }
                }
                if shouldPair && selectedRange.location < currentString.length {
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
            let lineStart = lineRange.location
            let head = currentString.substring(with: NSRange(location: lineStart, length: selectedRange.location - lineStart))
            let fullLine = currentString.substring(with: lineRange).trimmingCharacters(in: .newlines)

            // Return on an item that holds only its marker ends the list or quote.
            if selectedRange.length == 0,
               let marker = Self.listContinuation(for: fullLine)?.marker,
               fullLine.trimmingCharacters(in: .whitespaces) == marker.trimmingCharacters(in: .whitespaces) {
                let markerRange = NSRange(location: lineStart, length: (fullLine as NSString).length)
                super.insertText("", replacementRange: markerRange)
                return
            }

            let prefix = Self.listContinuation(for: head)?.prefix
                ?? String(head.prefix { $0 == " " || $0 == "\t" })
            super.insertText("\n" + prefix, replacementRange: selectedRange)
            return
        }

        super.insertText(string, replacementRange: replacementRange)
    }

    /// The marker that starts `line` (bullet, task, numbered item or blockquote)
    /// and the prefix the next line should get: same bullet, an unchecked task
    /// box, the next number, the same quote depth.
    static func listContinuation(for line: String) -> (prefix: String, marker: String)? {
        let ns = line as NSString
        func match(_ pattern: String) -> NSTextCheckingResult? {
            (try? NSRegularExpression(pattern: pattern))?.firstMatch(in: line, range: NSRange(location: 0, length: ns.length))
        }
        func group(_ m: NSTextCheckingResult, _ i: Int) -> String {
            m.range(at: i).location == NSNotFound ? "" : ns.substring(with: m.range(at: i))
        }
        if let m = match("^([ \\t]*)([-*+])([ \\t]+)(\\[[ xX]\\][ \\t]+)?") {
            let task = m.range(at: 4).location == NSNotFound ? "" : "[ ] "
            return (group(m, 1) + group(m, 2) + group(m, 3) + task, ns.substring(with: m.range))
        }
        if let m = match("^([ \\t]*)([0-9]{1,9})([.)])([ \\t]+)") {
            let next = (Int(group(m, 2)) ?? 0) + 1
            return (group(m, 1) + String(next) + group(m, 3) + group(m, 4), ns.substring(with: m.range))
        }
        if let m = match("^([ \\t]*(?:>[ \\t]?)+)") {
            let marker = ns.substring(with: m.range)
            return (marker, marker)
        }
        return nil
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
