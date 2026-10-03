import AppKit
import WebKit
import Testing
@testable import Lucid

@Suite("Layout interactions", .serialized)
@MainActor
struct LayoutInteractionTests {
    @Test func previewGeometryAlwaysUsesLatestBounds() {
        let web = WKWebView()
        let host = LucidWebContainerView(webView: web)
        for width in [900.0, 579, 900, 680, 579, 900] {
            host.frame = NSRect(x: 0, y: 0, width: width, height: 600)
            host.layout()
            #expect(web.frame == host.bounds)
        }
        // Mode hiding changes only visibility; it never changes geometry.
        host.isPaneActive = false
        #expect(host.alphaValue == 0)
        #expect(host.hitTest(NSPoint(x: 10, y: 10)) == nil)
        host.isPaneActive = true
        #expect(host.alphaValue == 1)
        #expect(web.frame == host.bounds)
    }

    private func controlFrames(_ page: WebEngineIntegrationTests.Page) async throws {
        // Drive the real bridge's queued work deterministically. WebKit suspends
        // RAF in occluded test windows; these tests protect state, not frame rate.
        _ = try await page.web.evaluateJavaScript("window.layoutFrames = []; window.requestAnimationFrame = callback => { layoutFrames.push(callback); return layoutFrames.length; }; true")
    }

    private func flushFrames(_ page: WebEngineIntegrationTests.Page) async throws {
        _ = try await page.web.evaluateJavaScript("for (let i = 0; i < 4 && layoutFrames.length; i++) { const batch = layoutFrames.splice(0); batch.forEach(callback => callback(performance.now())); } true")
    }

    @Test func resizingPreservesReadingLineAndFindRanges() async throws {
        let page = WebEngineIntegrationTests.Page()
        defer { page.close() }
        try await page.load()
        try await controlFrames(page)
        let markdown = (0..<100).map { "## Section \($0)\n\n" + String(repeating: "Wrapping text and a searchable phrase. ", count: 12) }.joined(separator: "\n\n")
        _ = try await page.web.callAsyncJavaScript(
            "lucid.updateContent(markdown, 'resize1'); lucid.scrollToSourceLine({line:120, top:false, end:false}); lucid.find('searchable phrase', {reveal:false});",
            arguments: ["markdown": markdown], in: nil, contentWorld: .page
        )
        try await flushFrames(page)
        #expect(try await page.check("window.savedLine = lucid.readingPosition().line; window.savedMatches = lucid.findMatches.length; savedLine > 100 && savedMatches > 0"))
        for width in [600.0, 850, 650, 900] {
            page.window.setContentSize(NSSize(width: width, height: 700))
            for _ in 0..<100 {
                if (try await page.web.evaluateJavaScript("innerWidth")) as? Double == width { break }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            #expect((try await page.web.evaluateJavaScript("innerWidth")) as? Double == width)
            _ = try await page.web.evaluateJavaScript("window.dispatchEvent(new Event('resize')); true")
            try await flushFrames(page)
            #expect(try await page.check("Math.abs(lucid.readingPosition().line - savedLine) < 1 && lucid.findMatches.length === savedMatches && lucid.findMatches.every(r => r.startContainer.isConnected)"))
        }
    }

    @Test func pendingResizeCannotScrollReplacementDocument() async throws {
        let page = WebEngineIntegrationTests.Page()
        defer { page.close() }
        try await page.load()
        try await controlFrames(page)
        #expect(try await page.check("""
        lucid.updateContent('# Old\\n\\n' + 'paragraph\\n\\n'.repeat(100), 'old');
        lucid.scrollToSourceLine({line:100,top:false,end:false});
        window.dispatchEvent(new Event('resize'));
        lucid.updateContent('# New\\n\\nshort', 'new');
        lucid.scrollToSourceLine({line:0,top:true,end:false});
        true;
        """))
        try await flushFrames(page)
        #expect(try await page.check("scrollY === 0 && lucid.readingPosition().top && lucid.getCurrentRevision() === 'new'"))
    }
}
