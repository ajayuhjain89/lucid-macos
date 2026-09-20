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
        guard !markdown.isEmpty else { return [] }

        var items: [HeadingItem] = []
        var inCodeBlock = false
        var seenIds: [String: Int] = [:]

        markdown.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track fenced code blocks (``` or ~~~)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock.toggle()
                return
            }
            if inCodeBlock { return }

            // Check for ATX headings (# ... ######)
            if trimmed.hasPrefix("#") {
                var level = 0
                for ch in trimmed {
                    if ch == "#" {
                        level += 1
                    } else {
                        break
                    }
                }

                if level >= 1 && level <= 6 {
                    let rest = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
                    if !rest.isEmpty {
                        var baseId = slugify(rest)
                        if baseId.isEmpty { baseId = "heading" }

                        let count = seenIds[baseId, default: 0]
                        seenIds[baseId] = count + 1
                        let uniqueId = count == 0 ? baseId : "\(baseId)-\(count)"

                        items.append(HeadingItem(id: uniqueId, level: level, text: rest))
                    }
                }
            }
        }

        return items
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
