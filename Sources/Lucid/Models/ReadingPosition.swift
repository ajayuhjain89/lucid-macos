import Foundation

/// Where the reader is in the document, as a fractional source line at the edge
/// where content rests below the toolbar. The editor and the preview both speak
/// it, so a mode switch or the split sync can put the other pane at the same
/// place (bridge.js: readingPosition / scrollToSourceLine).
struct ReadingPosition: Equatable {
    /// Zero-based source line; the fraction is how far through that line (or,
    /// in the preview, through the block that starts on it) the edge sits.
    var line: Double
    /// Scrolled to the very top or the very end: the other pane follows exactly,
    /// whatever the line mapping says.
    var top: Bool = false
    var end: Bool = false

    static let documentTop = ReadingPosition(line: 0, top: true)

    init(line: Double, top: Bool = false, end: Bool = false) {
        self.line = line
        self.top = top
        self.end = end
    }

    /// Reads the `{ line, top, end }` object bridge.js returns.
    init?(javaScriptValue value: Any?) {
        guard let dict = value as? [String: Any],
              let line = (dict["line"] as? NSNumber)?.doubleValue,
              line.isFinite else { return nil }
        self.line = max(0, line)
        self.top = (dict["top"] as? Bool) ?? false
        self.end = (dict["end"] as? Bool) ?? false
    }

    /// A JavaScript object literal for `lucid.scrollToSourceLine(…)`.
    var javaScriptLiteral: String {
        let safeLine = line.isFinite ? max(0, line) : 0
        return "{line: \(safeLine), top: \(top), end: \(end)}"
    }

    /// Zero-based line number of the line containing UTF-16 `location`.
    static func lineIndex(of location: Int, in text: NSString) -> Int {
        var count = 0
        var position = 0
        let limit = min(location, text.length)
        while position < limit {
            let found = text.range(of: "\n", options: .literal, range: NSRange(location: position, length: limit - position))
            if found.location == NSNotFound { break }
            count += 1
            position = found.location + 1
        }
        return count
    }

    /// UTF-16 location where zero-based `line` starts, or the text length when
    /// the text has fewer lines.
    static func location(ofLine line: Int, in text: NSString) -> Int {
        var position = 0
        var remaining = line
        while remaining > 0 && position < text.length {
            let found = text.range(of: "\n", options: .literal, range: NSRange(location: position, length: text.length - position))
            if found.location == NSNotFound { return text.length }
            position = found.location + 1
            remaining -= 1
        }
        return min(position, text.length)
    }
}
