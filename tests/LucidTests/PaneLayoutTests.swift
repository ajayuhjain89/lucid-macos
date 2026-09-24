import AppKit
import Testing
@testable import Lucid

@Suite("PaneLayout")
struct PaneLayoutTests {
    let size = CGSize(width: 900, height: 588)

    @Test func readerShowsOnlyThePreviewAndKeepsTheEditorFullWidth() {
        let layout = PaneLayout(mode: .reader, size: size, splitFraction: 0.5)
        #expect(layout.showsPreview && !layout.showsEditor)
        #expect(layout.preview == CGRect(origin: .zero, size: size))
        #expect(layout.editor == CGRect(origin: .zero, size: size))
    }

    @Test func editorShowsOnlyTheEditorAndKeepsThePreviewFullWidth() {
        let layout = PaneLayout(mode: .editor, size: size, splitFraction: 0.5)
        #expect(layout.showsEditor && !layout.showsPreview)
        #expect(layout.editor.width == 900 && layout.preview.width == 900)
    }

    @Test func splitPlacesThePanesEitherSideOfTheDivider() {
        let layout = PaneLayout(mode: .split, size: size, splitFraction: 0.5)
        #expect(layout.showsEditor && layout.showsPreview)
        #expect(layout.editor.minX == 0)
        #expect(layout.preview.minX == layout.editor.width + PaneLayout.dividerWidth)
        #expect(layout.editor.width + PaneLayout.dividerWidth + layout.preview.width == 900)
    }

    @Test func aHiddenPaneKeepsItsSplitShape() {
        let split = PaneLayout(mode: .split, size: size, splitFraction: 0.4)
        let reader = PaneLayout(mode: .reader, size: size, splitFraction: 0.4, hiddenEditor: .split)
        let editor = PaneLayout(mode: .editor, size: size, splitFraction: 0.4, hiddenPreview: .split)
        #expect(reader.editor == split.editor)
        #expect(editor.preview == split.preview)
        #expect(reader.preview.width == 900 && editor.editor.width == 900)
    }

    @Test(arguments: [0.0, 0.1, 0.9, 1.0])
    func splitKeepsBothPanesAtTheMinimumWidth(fraction: CGFloat) {
        let layout = PaneLayout(mode: .split, size: size, splitFraction: fraction)
        #expect(layout.editor.width >= PaneLayout.minPaneWidth)
        #expect(layout.preview.width >= PaneLayout.minPaneWidth)
    }

    @Test func dividerFractionRoundTrips() {
        let fraction = PaneLayout.fraction(forEditorWidth: 300, total: 900)
        #expect(PaneLayout.editorWidth(total: 900, fraction: fraction) == 300)
        // Dragged past the minimum: clamped, not beyond.
        let clamped = PaneLayout.fraction(forEditorWidth: 50, total: 900)
        #expect(PaneLayout.editorWidth(total: 900, fraction: clamped) == PaneLayout.minPaneWidth)
    }
}

@Suite("ReadingPosition")
@MainActor
struct ReadingPositionTests {
    @Test func lineIndexAndLocationAreInverse() {
        let text = "zero\none\n\nthree\nfour" as NSString
        #expect(ReadingPosition.lineIndex(of: 0, in: text) == 0)
        #expect(ReadingPosition.lineIndex(of: 5, in: text) == 1)
        #expect(ReadingPosition.lineIndex(of: 10, in: text) == 3)
        for line in 0..<5 {
            let location = ReadingPosition.location(ofLine: line, in: text)
            #expect(ReadingPosition.lineIndex(of: location, in: text) == line)
        }
        #expect(ReadingPosition.location(ofLine: 99, in: text) == text.length)
    }

    @Test func parsesTheBridgeObject() {
        let position = ReadingPosition(javaScriptValue: ["line": 12.5, "top": false, "end": true])
        #expect(position == ReadingPosition(line: 12.5, end: true))
        #expect(ReadingPosition(javaScriptValue: nil) == nil)
        #expect(ReadingPosition(javaScriptValue: ["top": true]) == nil)
        #expect(ReadingPosition(line: 3, top: true).javaScriptLiteral == "{line: 3.0, top: true, end: false}")
    }

    /// An editor in a scroll view, as EditorView builds it (without a window).
    private func makeEditor(lines: Int) -> (NSScrollView, LucidTextView) {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 500, height: 400))
        let storage = NSTextStorage(string: (0..<lines).map { "Line \($0) with a few words in it" }.joined(separator: "\n"))
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(containerSize: NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        let textView = LucidTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize), textContainer: container)
        textView.strongTextStorage = storage
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.font = .systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 32, height: LucidChrome.contentTopInset)
        scrollView.documentView = textView
        layoutManager.ensureLayout(for: container)
        textView.sizeToFit()
        return (scrollView, textView)
    }

    @Test func editorStartsAtTheTop() {
        let (_, textView) = makeEditor(lines: 200)
        #expect(textView.readingPosition() == .documentTop)
    }

    @Test func editorScrollsToALineAndReadsItBack() {
        let (_, textView) = makeEditor(lines: 200)
        textView.scrollToReadingPosition(ReadingPosition(line: 80.5))
        let back = textView.readingPosition()
        #expect(abs(back.line - 80.5) < 0.05)
        #expect(!back.top && !back.end)
    }

    @Test func editorFollowsTheEndOfTheDocument() {
        let (_, textView) = makeEditor(lines: 200)
        textView.scrollToReadingPosition(ReadingPosition(line: 150, end: true))
        #expect(textView.readingPosition().end)
    }
}

@Suite("PreviewRenderCoordinator")
struct PreviewRenderCoordinatorTests {
    @Test func reportsQueuedContentWhenRenderingResumes() {
        let coordinator = PreviewRenderCoordinator()
        coordinator.setRenderingPaused(true)
        coordinator.scheduleRender(markdown: "latest")

        #expect(coordinator.setRenderingPaused(false))
    }

    @Test func doesNotReportPendingContentWhenNothingWasQueued() {
        let coordinator = PreviewRenderCoordinator()
        coordinator.setRenderingPaused(true)

        #expect(!coordinator.setRenderingPaused(false))
    }
}
