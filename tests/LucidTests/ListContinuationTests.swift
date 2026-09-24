import Testing
@testable import Lucid

@Suite("LucidTextView.listContinuation")
struct ListContinuationTests {
    @Test(arguments: [
        ("- item", "- ", "- "),
        ("* item", "* ", "* "),
        ("+ item", "+ ", "+ "),
        ("  - nested", "  - ", "  - "),
        ("\t- tabbed", "\t- ", "\t- "),
        ("- [x] done", "- [ ] ", "- [x] "),
        ("- [ ] todo", "- [ ] ", "- [ ] "),
        ("1. first", "2. ", "1. "),
        ("9) ninth", "10) ", "9) "),
        ("   41. deep", "   42. ", "   41. "),
        ("> quote", "> ", "> "),
        ("> > nested quote", "> > ", "> > ")
    ])
    func continues(line: String, prefix: String, marker: String) throws {
        let result = try #require(LucidTextView.listContinuation(for: line))
        #expect(result.prefix == prefix)
        #expect(result.marker == marker)
    }

    @Test(arguments: ["plain text", "-no space", "1.no space", "**bold**", "", "    code"])
    func doesNotContinue(line: String) {
        #expect(LucidTextView.listContinuation(for: line) == nil)
    }

    @Test func markerOnlyLineIsRecognizedForExit() throws {
        // insertText ends the list when the line holds nothing but its marker.
        let result = try #require(LucidTextView.listContinuation(for: "- "))
        #expect(result.marker.trimmingCharacters(in: .whitespaces) == "-")
    }
}
