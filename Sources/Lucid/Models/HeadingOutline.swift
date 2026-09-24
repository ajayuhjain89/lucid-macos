import Foundation

public struct HeadingItem: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var level: Int
    public var text: String

    public init(id: String, level: Int, text: String) {
        self.id = id
        self.level = level
        self.text = text
    }
}

/// Fast native parser that extracts document headings directly from Markdown
/// text in < 2ms without waiting for WebKit / DOM / JavaScript initialization.
public struct MarkdownOutlineParser {
    public static func parse(markdown: String) -> [HeadingItem] {
        parseWithLines(markdown: markdown).map(\.item)
    }

    /// Like `parse`, plus each heading's zero-based line index in `markdown`.
    ///
    /// Follows markdown-it (CommonMark) closely enough that the outline matches
    /// the rendered preview: ATX headings need a space after the `#`s and lose a
    /// closing `#` sequence; setext (`===` / `---` underlined) headings count;
    /// headings inside blockquotes and list items count; fenced code (``` or ~~~,
    /// closed only by the same fence), indented code, display math and YAML front
    /// matter are skipped. Ids are slugs of the raw heading source, exactly as
    /// bridge.js computes them; `text` is that source with inline Markdown removed.
    public static func parseWithLines(markdown: String) -> [(item: HeadingItem, line: Int)] {
        guard !markdown.isEmpty else { return [] }

        var items: [(item: HeadingItem, line: Int)] = []
        var seenIds: [String: Int] = [:]
        var lineIndex = -1
        let frontMatterLines = frontMatterLineCount(markdown)
        var fence: (char: Character, length: Int)? = nil
        var inMathBlock = false
        var activeMathCloseDelim: String? = nil
        var paragraph: [String] = []
        var paragraphStartLine = 0

        func addHeading(level: Int, source: String, line: Int) {
            let text = displayText(source)
            guard !text.isEmpty else { return }
            var baseId = slugify(source)
            if baseId.isEmpty { baseId = "heading" }
            let count = seenIds[baseId, default: 0]
            seenIds[baseId] = count + 1
            let uniqueId = count == 0 ? baseId : "\(baseId)-\(count)"
            items.append((HeadingItem(id: uniqueId, level: level, text: text), line))
        }

        markdown.enumerateLines { line, _ in
            lineIndex += 1
            if lineIndex < frontMatterLines { return }

            let indent = leadingIndent(line)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code: closed only by the same character, at least as long, with no info string.
            if let open = fence {
                if indent < 4, let close = fenceRun(trimmed), close.char == open.char,
                   close.length >= open.length,
                   trimmed.dropFirst(close.length).trimmingCharacters(in: .whitespaces).isEmpty {
                    fence = nil
                }
                return
            }
            if indent < 4, let open = fenceRun(trimmed), open.length >= 3,
               !(open.char == "`" && trimmed.dropFirst(open.length).contains("`")) {
                fence = open
                paragraph = []
                return
            }

            // Display math blocks ($$ or \[)
            if inMathBlock {
                if let close = activeMathCloseDelim, trimmed.contains(close) {
                    inMathBlock = false
                    activeMathCloseDelim = nil
                }
                return
            }
            if trimmed.hasPrefix("$$") || trimmed.hasPrefix("\\[") {
                let delim = trimmed.hasPrefix("$$") ? "$$" : "\\]"
                paragraph = []
                if !trimmed.dropFirst(2).contains(delim) {
                    inMathBlock = true
                    activeMathCloseDelim = delim
                }
                return
            }

            if trimmed.isEmpty {
                paragraph = []
                return
            }
            // Indented code, unless it continues a paragraph.
            if indent >= 4 && paragraph.isEmpty { return }

            // Setext underline below a paragraph.
            if indent < 4, !paragraph.isEmpty, let level = setextLevel(trimmed) {
                let source = paragraph.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
                addHeading(level: level, source: source, line: paragraphStartLine)
                paragraph = []
                return
            }

            // ATX heading, possibly inside blockquote / list item markers.
            var content = Substring(indent < 4 ? trimmed : "")
            var inContainer = false
            while true {
                if content.hasPrefix(">") {
                    content = content.dropFirst()
                } else if let marker = listMarkerLength(content) {
                    content = content.dropFirst(marker)
                } else {
                    break
                }
                inContainer = true
                content = content.drop { $0 == " " || $0 == "\t" }
            }
            if let (level, source) = atxHeading(content) {
                addHeading(level: level, source: source, line: lineIndex)
                paragraph = []
                return
            }
            // Setext detection across containers is not modeled; start afresh.
            if inContainer || isThematicBreak(trimmed) {
                paragraph = []
                return
            }
            if paragraph.isEmpty { paragraphStartLine = lineIndex }
            paragraph.append(line)
        }

        return items
    }

    /// Lines taken by YAML front matter (`---` … `---`/`...` at the very start),
    /// matching bridge.js `blankFrontMatter`; 0 when there is none.
    static func frontMatterLineCount(_ markdown: String) -> Int {
        guard markdown.hasPrefix("---") else { return 0 }
        var count = 0
        var lines = 0
        var found = false
        markdown.enumerateLines { line, stop in
            lines += 1
            let t = line.trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
            if lines == 1 {
                if t != "---" { stop = true }
                return
            }
            if t == "---" || t == "..." {
                count = lines
                found = true
                stop = true
            }
        }
        return found ? count : 0
    }

    private static func leadingIndent(_ line: String) -> Int {
        var width = 0
        for ch in line {
            if ch == " " { width += 1 } else if ch == "\t" { width += 4 - width % 4 } else { break }
        }
        return width
    }

    /// A leading run of ` or ~ (the fence character and its length).
    private static func fenceRun(_ trimmed: String) -> (char: Character, length: Int)? {
        guard let first = trimmed.first, first == "`" || first == "~" else { return nil }
        let length = trimmed.prefix { $0 == first }.count
        return length >= 3 ? (first, length) : nil
    }

    private static func setextLevel(_ trimmed: String) -> Int? {
        if !trimmed.isEmpty && trimmed.allSatisfy({ $0 == "=" }) { return 1 }
        if !trimmed.isEmpty && trimmed.allSatisfy({ $0 == "-" }) { return 2 }
        return nil
    }

    private static func isThematicBreak(_ trimmed: String) -> Bool {
        let chars = trimmed.filter { $0 != " " && $0 != "\t" }
        guard chars.count >= 3, let first = chars.first, "*-_".contains(first) else { return false }
        return chars.allSatisfy { $0 == first }
    }

    /// Length of a list item marker plus its following whitespace ("- ", "12. ").
    private static func listMarkerLength(_ s: Substring) -> Int? {
        if let first = s.first, "-*+".contains(first) {
            let after = s.dropFirst()
            guard let next = after.first, next == " " || next == "\t" else { return nil }
            return 2
        }
        let digits = s.prefix { $0.isASCII && $0.isNumber }
        guard (1...9).contains(digits.count) else { return nil }
        let after = s.dropFirst(digits.count)
        guard let delim = after.first, delim == "." || delim == ")" else { return nil }
        guard let next = after.dropFirst().first, next == " " || next == "\t" else { return nil }
        return digits.count + 2
    }

    /// `# Title ##` → (1, "Title"). Requires a space or tab after the opening
    /// `#`s (so `#hashtag` is text); a closing `#` run needs a space before it.
    private static func atxHeading(_ content: Substring) -> (Int, String)? {
        let level = content.prefix { $0 == "#" }.count
        guard (1...6).contains(level) else { return nil }
        var rest = content.dropFirst(level)
        if let next = rest.first, next != " " && next != "\t" { return nil }
        rest = rest.drop { $0 == " " || $0 == "\t" }
        var source = String(rest).trimmingCharacters(in: .whitespaces)
        let withoutClosing = source.replacingOccurrences(of: "(^|[ \t])#+$", with: "", options: .regularExpression)
        if withoutClosing != source {
            source = withoutClosing.trimmingCharacters(in: .whitespaces)
        }
        return (level, source)
    }

    /// The heading as the preview shows it: inline Markdown syntax removed.
    static func displayText(_ source: String) -> String {
        var text = source.replacingOccurrences(of: "\n", with: " ")
        let rules: [(String, String)] = [
            ("!\\[([^\\]]*)\\]\\([^)]*\\)", "$1"),               // images
            ("\\[([^\\]]*)\\]\\([^)]*\\)", "$1"),                // inline links
            ("\\[([^\\]]*)\\]\\[[^\\]]*\\]", "$1"),              // reference links
            ("<((?:https?|mailto):[^>\\s]+)>", "$1"),         // autolinks
            ("(`+)(.+?)\\1", "$2"),                            // code spans
            ("(\\*\\*|__)(?=\\S)(.+?)(?<=\\S)\\1", "$2"),            // strong
            ("\\*(?=\\S)(.+?)(?<=\\S)\\*", "$1"),                    // emphasis
            ("(?<![\\p{L}\\p{N}_])_(?=\\S)(.+?)(?<=\\S)_(?![\\p{L}\\p{N}_])", "$1"),
            ("~~(?=\\S)(.+?)(?<=\\S)~~", "$1"),                   // strikethrough
            ("==(?=\\S)(.+?)(?<=\\S)==", "$1"),                   // mark
            ("\\\\([!-/:-@\\[-`{-~])", "$1")                    // backslash escapes
        ]
        for (pattern, template) in rules {
            text = text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    public static func slugify(_ text: String) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var result = ""
        for ch in lower {
            if ch.isLetter || ch.isNumber || ch == " " || ch == "-" || ch == "_" {
                result.append(ch)
            }
        }
        var parts: [String] = []
        var current = ""
        for ch in result {
            if ch == " " || ch == "-" || ch == "_" {
                if !current.isEmpty {
                    parts.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty {
            parts.append(current)
        }
        return parts.joined(separator: "-")
    }
}
