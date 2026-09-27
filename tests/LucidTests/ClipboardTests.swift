import AppKit
import Testing
@testable import Lucid

@MainActor struct ClipboardTests {
    @Test func writesHTMLAndPlainTextWithoutTouchingGeneralClipboard() {
        let pasteboard = NSPasteboard(name: .init("lucid.test.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        #expect(ExportService.writeRichText(html: "<p>Hello <strong>world</strong></p>", plainText: "Hello world", to: pasteboard))
        #expect(pasteboard.string(forType: .html) == "<p>Hello <strong>world</strong></p>")
        #expect(pasteboard.string(forType: .string) == "Hello world")
    }
}
