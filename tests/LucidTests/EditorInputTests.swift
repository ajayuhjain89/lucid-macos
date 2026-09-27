import AppKit
import Testing
import SwiftUI
@testable import Lucid

extension UserDefaultsTests {
    @Suite("Editor input", .serialized)
    @MainActor struct EditorInputTests {
        private func editor(_ text: String, pairing: Bool = true) -> LucidTextView {
            _ = NSApplication.shared
            let view = LucidTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
            view.preferences = LucidPreferences()
            view.preferences?.autoIndent = true
            view.preferences?.autoPairDelimiters = pairing
            view.string = text
            view.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
            return view
        }

        @Test func indentDoesNotDependOnPairing() {
            let view = editor("- item", pairing: false)
            view.insertText("\n", replacementRange: NSRange(location: NSNotFound, length: 0))
            #expect(view.string == "- item\n- ")
        }

        @Test func disabledPairingDoesNotDeleteTheCloser() {
            let view = editor("()", pairing: false)
            view.setSelectedRange(NSRange(location: 1, length: 0))
            view.deleteBackward(nil)
            #expect(view.string == ")")
        }

        @Test func escapedDelimiterStaysLiteral() {
            let view = editor("\\")
            view.insertText("*", replacementRange: NSRange(location: NSNotFound, length: 0))
            #expect(view.string == "\\*")
        }

        @Test func explicitReplacementIsHonored() {
            let view = editor("hello")
            view.insertText("(", replacementRange: NSRange(location: 0, length: 5))
            #expect(view.string == "(")
        }

        @Test func bareMarkerTerminates() {
            let view = editor("- item\n-")
            view.insertText("\n", replacementRange: NSRange(location: NSNotFound, length: 0))
            #expect(view.string == "- item\n")
        }

        @Test func nativeReturnContinuesList() {
            let view = editor("- item")
            view.insertNewline(nil)
            #expect(view.string == "- item\n- ")
        }

        @Test func cursorReportsTheActualLineAndColumn() {
            var position = (0, 0)
            let parent = EditorView(text: .constant(""), onCursorPositionChanged: { position = ($0, $1) })
            let coordinator = parent.makeCoordinator()
            let view = editor("hello\nworld")
            coordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: view))
            #expect(position.0 == 2 && position.1 == 6)
        }

        @Test func largeDocumentTypingMeasurements() {
            for lines in [1_000, 5_000, 10_000, 20_000] {
                let view = editor(String(repeating: "A line of Markdown text with Unicode café.\n", count: lines))
                let coordinator = EditorView(text: .constant(view.string)).makeCoordinator()
                view.delegate = coordinator
                var samples: [Double] = []
                for _ in 0..<20 {
                    let start = DispatchTime.now().uptimeNanoseconds
                    view.insertText("x", replacementRange: NSRange(location: NSNotFound, length: 0))
                    samples.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
                }
                samples.sort()
                print("Native edit + delegate, \(lines) lines: median \(samples[10]) ms; p95 \(samples[18]) ms")
                #expect(view.string.hasSuffix(String(repeating: "x", count: 20)))
            }
        }
    }
}
