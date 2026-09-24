import Foundation
import Testing
@testable import Lucid

@Suite("MarkdownOutlineParser")
struct OutlineParserTests {
    @Test func atxHeadingsWithLevelsAndLines() {
        let md = "# One\n\ntext\n\n## Two\n### Three\n"
        let parsed = MarkdownOutlineParser.parseWithLines(markdown: md)
        #expect(parsed.map(\.item.text) == ["One", "Two", "Three"])
        #expect(parsed.map(\.item.level) == [1, 2, 3])
        #expect(parsed.map(\.line) == [0, 4, 5])
    }

    @Test func headingsInsideFencesAndMathAreIgnored() {
        let md = "# Real\n```\n# not a heading\n```\n$$\n# nor this\n$$\n## Also real\n"
        #expect(MarkdownOutlineParser.parse(markdown: md).map(\.text) == ["Real", "Also real"])
    }

    @Test func idsMatchTheRendererSlugs() {
        // Same expectations as tests/test-security-and-engines.js (AUDIT-004).
        let md = ["# Overview", "## Overview", "## 概要", "## Section θ", "## Overview",
                  "## Пример", "## Café résumé", "## !!! ???"].joined(separator: "\n\n")
        #expect(MarkdownOutlineParser.parse(markdown: md).map(\.id) ==
                ["overview", "overview-1", "概要", "section-θ", "overview-2", "пример", "café-résumé", "heading"])
    }

    @Test func emptyDocument() {
        #expect(MarkdownOutlineParser.parse(markdown: "").isEmpty)
    }

    /// tests/test-outline-parity.js checks the renderer against the same JSON.
    @Test func matchesTheRendererOnTheParityFixture() throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("fixtures")
        let markdown = try String(contentsOf: fixtures.appendingPathComponent("outline-parity.md"), encoding: .utf8)
        let data = try Data(contentsOf: fixtures.appendingPathComponent("outline-parity.json"))
        let expected = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        let collapse = { (s: String) in s.split(whereSeparator: \.isWhitespace).joined(separator: " ") }

        let parsed = MarkdownOutlineParser.parse(markdown: markdown)
        #expect(parsed.map(\.id) == expected.map { $0["id"] as? String ?? "" })
        #expect(parsed.map(\.level) == expected.map { $0["level"] as? Int ?? 0 })
        #expect(parsed.map { collapse($0.text) } == expected.map { collapse($0["text"] as? String ?? "") })
    }

    @Test(arguments: ["#hashtag", "#", "####### seven", "    # indented code", "\\# escaped"])
    func notHeadings(_ line: String) {
        #expect(MarkdownOutlineParser.parse(markdown: "Intro\n\n" + line + "\n").isEmpty)
    }

    @Test func tildeInsideBacktickFenceDoesNotCloseIt() {
        let md = "```\n~~~\n# hidden\n~~~\n```\n# Shown\n"
        #expect(MarkdownOutlineParser.parse(markdown: md).map(\.text) == ["Shown"])
    }

    @Test func frontMatterIsSkippedButALaterRuleIsNot() {
        let md = "---\ntitle: x\n---\n\nPara\n---\n"
        let parsed = MarkdownOutlineParser.parseWithLines(markdown: md)
        #expect(parsed.map(\.item.text) == ["Para"])
        #expect(parsed.map(\.line) == [4])
    }
}
