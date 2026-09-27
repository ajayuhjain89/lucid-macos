import AppKit
import WebKit
import Testing
@testable import Lucid

/// Runs the shipped HTML, CSP, plugins and bridge in real WebKit. No fake DOM.
@Suite("WebEngine integration", .serialized)
@MainActor struct WebEngineIntegrationTests {
    @MainActor final class Page {
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
                              styleMask: .borderless, backing: .buffered, defer: false)
        init() {
            window.isReleasedWhenClosed = false
            window.contentView = web
            window.orderBack(nil)
        }
        func close() { web.stopLoading(); window.contentView = nil; window.close() }
        func load() async throws {
            let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            let url = root.appendingPathComponent("Sources/Lucid/Resources/WebEngine/index.html")
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            for _ in 0..<250 {
                if (try? await web.evaluateJavaScript("typeof window.lucid === 'object'")) as? Bool == true { return }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            throw CocoaError(.fileReadUnknown)
        }
        func check(_ script: String) async throws -> Bool {
            (try await web.evaluateJavaScript(script)) as? Bool == true
        }
    }

    @Test func findAcrossInlineNodesDoesNotMutateDOM() async throws {
        let page = Page(); defer { page.close() }; try await page.load()
        #expect(try await page.check("""
        lucid.updateContent('hello **world** and hello *world*\\n\\n`hello world`\\n\\n| Header |\\n|---|\\n| hello world |', 'find1');
        window.beforeFind = document.getElementById('lucid-content').innerHTML;
        lucid.find('hello world');
        lucid.findMatches.length === 4;
        """))
        #expect(try await page.check("document.getElementById('lucid-content').innerHTML === window.beforeFind"))
        #expect(try await page.check("lucid.findNext(); lucid.findCurrentIndex === 1"))
        #expect(try await page.check("lucid.findPrev(); lucid.findCurrentIndex === 0"))
        #expect(try await page.check("lucid.updateContent('hello **world**', 'find2'); lucid.findMatches.length === 1"))
        #expect(try await page.check("lucid.updateContent('replacement', 'find3'); lucid.findMatches.length === 0"))
        #expect(try await page.check("lucid.clearFind(); document.querySelectorAll('mark.lucid-find-match').length === 0"))
    }

    @Test func taskListsAndRawHTMLInActualWebKit() async throws {
        let page = Page(); defer { page.close() }; try await page.load()
        #expect(try await page.check("""
        lucid.updateContent('- [ ] Todo\\n- [x] Done\\n- [X] Upper\\n  - [x] Nested\\n\\n<img src=x onerror="window.probe=1">\\n<script>window.probe=1</script>\\n<iframe src="https://example.com"></iframe>\\n\\n[bad](javascript:window.probe=1)', 'security');
        const boxes = [...document.querySelectorAll('input[type=checkbox]')];
        boxes.length === 4 && boxes.every(b => b.disabled) && boxes.filter(b => b.checked).length === 3 &&
        !document.querySelector('#lucid-content script, #lucid-content iframe, #lucid-content img, a[href^="javascript:"]') && !window.probe;
        """))
    }

    @Test func initialMermaidAndThemeUseOneWorker() async throws {
        let page = Page(); defer { page.close() }; try await page.load()
        #expect(try await page.check("""
        window.jobs = []; window.activeJobs = 0; window.maxJobs = 0; window.runCalls = 0;
        window.mermaid = { initialize: () => {} };
        mermaid.run = () => { window.runCalls++; return new Promise(() => {}); };
        mermaid.render = () => { window.activeJobs++; window.maxJobs = Math.max(window.maxJobs, window.activeJobs);
          return new Promise(resolve => window.jobs.push(() => { window.activeJobs--; resolve({svg:'<svg></svg>'}); })); };
        lucid.updateContent('```mermaid\\nflowchart TD\\nA-->B\\n```', 'race1');
        lucid.updatePreferences({theme:'light'});
        window.runCalls === 0;
        """))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(try await page.check("window.maxJobs === 1 && window.jobs.length === 1"))
        _ = try await page.web.evaluateJavaScript("window.jobs.shift()(); true")
        for _ in 0..<100 {
            if try await page.check("window.jobs.length > 0") { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        _ = try await page.web.evaluateJavaScript("if(window.jobs.length) window.jobs.shift()(); true")
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(try await page.check("window.maxJobs === 1 && document.querySelector('.mermaid-container')._lucidCurrentTheme === 'light'"))
    }

    @Test func rejectedMermaidDoesNotRetryForever() async throws {
        let page = Page(); defer { page.close() }; try await page.load()
        _ = try await page.web.evaluateJavaScript("""
        window.attempts = 0;
        window.mermaid = { run: () => Promise.resolve(), initialize: () => {} };
        mermaid.render = () => { window.attempts++; return Promise.reject(new Error('invalid fixture')); };
        lucid.updateContent('```mermaid\\ninvalid fixture\\n```', 'error1');
        lucid.updatePreferences({theme:'sepia'}); true;
        """)
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(try await page.check("window.attempts <= 2 && !!document.querySelector('.lucid-mermaid-error') && lucid.isExportReady()"))
    }

    @Test func realMermaidSurvivesThemeChangesAndSourceReplacement() async throws {
        let page = Page(); defer { page.close() }; try await page.load()
        _ = try await page.web.evaluateJavaScript("""
        lucid.updateContent('```mermaid\\nflowchart TD\\nA-->B\\n```\\n\\n```mermaid\\nsequenceDiagram\\nAlice->>Bob: Hello\\n```', 'real1'); true;
        """)

        for theme in ["light", "dark", "sepia", "light"] {
            _ = try await page.web.evaluateJavaScript("lucid.updatePreferences({theme:'\(theme)'}); true")
            for _ in 0..<500 {
                if try await page.check("[...document.querySelectorAll('.mermaid-container')].every(c => c._lucidCurrentTheme === '\(theme)')") { break }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            #expect(try await page.check("document.querySelectorAll('.mermaid-canvas svg').length === 2 && !document.querySelector('.lucid-mermaid-error') && lucid.isExportReady()"))
        }
        #expect(try await page.check("lucid.updateContent('removed', 'real2'); document.querySelectorAll('.mermaid-container').length === 0 && lucid.isExportReady()"))
    }
}
