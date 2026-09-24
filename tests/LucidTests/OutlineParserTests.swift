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
}
