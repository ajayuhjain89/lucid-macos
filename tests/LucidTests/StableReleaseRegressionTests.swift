import Foundation
import AppKit
import Testing
import SwiftUI
import WebKit
@testable import Lucid

@Suite("Stable release regressions", .serialized)
@MainActor struct StableReleaseRegressionTests {
    @Test func namedDirtyDocumentRecoversUnsavedBuffer() throws {
        let defaults = UserDefaults(suiteName: "LucidAudit-\(UUID())")!
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("audit-recovery-\(UUID()).md")
        try "Disk baseline".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let session = try #require(manager.openFile(url: url))
        session.text = "Unsaved work"
        restorer.saveSession(managers: [manager])
        let restored = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restored))
        #expect(restored.activeSession.text == "Unsaved work")
        #expect(restored.activeSession.isDirty)
    }

    @Test func restoringTwoWindowsRetainsBothDistinctTabSets() throws {
        let defaults = UserDefaults(suiteName: "LucidAudit-\(UUID())")!
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let first = WindowDocumentManager(initialSession: DocumentSession(text: "Window A"))
        let second = WindowDocumentManager(initialSession: DocumentSession(text: "Window B"))
        restorer.saveSession(managers: [first, second])
        let restoredA = WindowDocumentManager()
        let restoredB = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restoredA))
        #expect(restorer.restoreInto(documentManager: restoredB))
        #expect(restoredA.activeSession.text == "Window A")
        #expect(restoredB.activeSession.text == "Window B")
    }

    @Test func ownAtomicSaveDoesNotCauseExternalConflict() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("audit-own-save-\(UUID()).md")
        try "Original".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let session = try #require(manager.openFile(url: url))
        // Keep inactive to observe the genuine watcher callback without a modal alert.
        _ = manager.newTab()
        session.text = "Saved by Lucid"
        var saved = false
        manager.saveSession(session) { saved = $0 }
        #expect(saved)
        session.text = "Typed immediately after save"
        try await Task.sleep(nanoseconds: 600_000_000)
        #expect(!session.hasExternalConflict)
        #expect(session.text == "Typed immediately after save")
        #expect(try String(contentsOf: url, encoding: .utf8) == "Saved by Lucid")
    }

    @Test func cleanInactiveTabObservesRealExternalWrite() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("audit-reload-\(UUID()).md")
        try "Original".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let session = try #require(manager.openFile(url: url))
        _ = manager.newTab()
        try "External replacement".write(to: url, atomically: true, encoding: .utf8)
        try await Task.sleep(nanoseconds: 600_000_000)
        #expect(session.text == "External replacement")
        #expect(!session.isDirty)
    }
    @Test func sharedEditorUndoDoesNotMutateAnotherDocument() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let editor = LucidTextView(frame: window.contentView!.bounds)
        editor.allowsUndo = true
        window.contentView = editor
        defer { editor.undoManager?.removeAllActions(); window.contentView = nil; window.close() }
        let a = DocumentSession(text: "Saved document A")
        let b = DocumentSession()
        editor.displaySession(a)
        editor.insertText("!", replacementRange: NSRange(location: 16, length: 0))
        a.text = editor.string
        editor.displaySession(b)
        editor.insertText("Draft B", replacementRange: NSRange(location: 0, length: 0))
        b.text = editor.string
        editor.displaySession(a)
        let undo = NSSelectorFromString("undo:")
        let redo = NSSelectorFromString("redo:")
        #expect(editor.responds(to: undo))
        #expect(editor.responds(to: redo))
        let undoItem = NSMenuItem(title: "Undo", action: undo, keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: redo, keyEquivalent: "Z")
        #expect(editor.validateUserInterfaceItem(undoItem))
        NSApp.sendAction(undo, to: editor, from: undoItem)
        #expect(editor.string == "Saved document A")
        #expect(editor.validateUserInterfaceItem(redoItem))
        NSApp.sendAction(redo, to: editor, from: redoItem)
        #expect(editor.string == "Saved document A!")
        editor.displaySession(b)
        NSApp.sendAction(undo, to: editor, from: undoItem)
        #expect(editor.string.isEmpty)
        #expect(!editor.validateUserInterfaceItem(undoItem))
    }

    @Test func editDuringPendingTabSwitchUpdatesDisplayedBuffer() {
        let displayed = DocumentSession(text: "A")
        let selected = DocumentSession(text: "B")
        let view = EditorView(text: Binding(get: { selected.text }, set: { selected.text = $0 }),
                              documentSession: selected,
                              onCursorPositionChanged: { line, col in
                                  selected.cursorLine = line; selected.cursorCol = col
                              })
        let coordinator = view.makeCoordinator()
        let editor = LucidTextView(frame: .zero)
        editor.displaySession(displayed)
        editor.string = "A typed before the tab switch rendered"
        editor.setSelectedRange(NSRange(location: 5, length: 0))
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        #expect(displayed.text == editor.string)
        #expect(selected.text == "B")
        #expect(displayed.cursorCol == 6)
        #expect(selected.cursorCol == 1)
    }

    @Test func saveThenCancelKeepsAllTabsAcrossWindows() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("close-save-\(UUID()).md")
        try "Baseline".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let a = WindowDocumentManager()
        let saved = try #require(a.openFile(url: url))
        saved.text = "Saved during review"
        let b = WindowDocumentManager(initialSession: DocumentSession(text: "Unsaved B"))
        var reviewed: [UUID] = []
        var completed = false
        DocumentCloseReview.review(managers: [a, b], prompt: { session, _, decide in
            reviewed.append(session.id)
            decide(session === saved ? .save : .cancel)
        }) { approval in
            completed = true
            #expect(approval == nil)
        }
        #expect(completed)
        #expect(reviewed == [saved.id, b.activeSession.id])
        #expect(a.sessions.count == 1 && a.sessions[0] === saved)
        #expect(b.sessions.count == 1 && b.activeSession.text == "Unsaved B")
        #expect(!saved.isDirty)
        #expect(try String(contentsOf: url, encoding: .utf8) == "Saved during review")
        #expect(!a.isReviewingClose && !b.isReviewingClose)
    }

    @Test func discardThenCancelPreservesBuffersAndOrder() {
        let manager = WindowDocumentManager(initialSession: DocumentSession(text: "Keep A"))
        let first = manager.activeSession
        let second = manager.newTab(text: "Keep B")
        let activeID = manager.activeSessionID
        DocumentCloseReview.review(managers: [manager], prompt: { session, _, decide in
            decide(session === first ? .discard : .cancel)
        }) { approval in #expect(approval == nil) }
        #expect(manager.sessions.map(\.id) == [first.id, second.id])
        #expect(first.text == "Keep A" && second.text == "Keep B")
        #expect(first.isDirty && second.isDirty)
        #expect(manager.activeSessionID == activeID)
    }

    @Test func failedSaveAbortsReviewWithoutRemovingTabs() {
        let manager = WindowDocumentManager(initialSession: DocumentSession(text: "Must survive"))
        let original = manager.activeSession
        var completed = false
        DocumentCloseReview.review(managers: [manager], prompt: { _, _, decide in decide(.save) },
                                  save: { _, _, _, saved in saved(false) }) { approval in
            completed = true
            #expect(approval == nil)
        }
        #expect(completed)
        #expect(manager.sessions.count == 1 && manager.sessions[0] === original)
        #expect(original.isDirty && original.text == "Must survive")
    }

    @Test func repeatedCloseCannotQueueAnotherPrompt() {
        let manager = WindowDocumentManager(initialSession: DocumentSession(text: "Dirty"))
        var firstResponse: ((DocumentCloseDecision) -> Void)?
        DocumentCloseReview.review(managers: [manager], prompt: { _, _, decide in firstResponse = decide }) { approval in
            #expect(approval == nil)
        }
        #expect(manager.isReviewingClose)
        DocumentCloseReview.review(managers: [manager], prompt: { _, _, _ in Issue.record("A second prompt was presented") }) { approval in
            #expect(approval == nil)
        }
        firstResponse?(.cancel)
        #expect(!manager.isReviewingClose)
        #expect(manager.activeSession.text == "Dirty")
    }

    @Test func changedDiscardedBufferRequiresAnotherDecision() {
        let manager = WindowDocumentManager(initialSession: DocumentSession(text: "A"))
        let a = manager.activeSession
        let b = manager.newTab(text: "B")
        var calls: [UUID] = []
        DocumentCloseReview.review(managers: [manager], prompt: { session, _, decide in
            calls.append(session.id)
            if calls.count == 1 { decide(.discard) }
            else if session === b { a.text = "A changed during review"; decide(.discard) }
            else { decide(.cancel) }
        }) { approval in #expect(approval == nil) }
        #expect(calls == [a.id, b.id, a.id])
        #expect(a.text == "A changed during review")
        #expect(manager.sessions.count == 2)
    }

    @Test func recoveryRetainsDeletedFilesAndDetectsDiskDivergence() throws {
        let defaults = UserDefaults(suiteName: "LucidRecovery-\(UUID())")!
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("recover-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let firstURL = root.appendingPathComponent("deleted.md")
        let secondURL = root.appendingPathComponent("changed.md")
        try "Baseline".write(to: firstURL, atomically: true, encoding: .utf8)
        try "Baseline".write(to: secondURL, atomically: true, encoding: .utf8)
        let manager = WindowDocumentManager()
        let first = try #require(manager.openFile(url: firstURL))
        let second = try #require(manager.openFile(url: secondURL))
        first.text = "Recover deleted draft"
        first.encoding = .utf16
        second.text = "Recover changed draft"
        restorer.saveSession(managers: [manager])
        try FileManager.default.removeItem(at: firstURL)
        try "New disk version".write(to: secondURL, atomically: true, encoding: .utf8)
        let restored = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restored))
        #expect(restored.sessions.count == 2)
        #expect(restored.sessions[0].text == "Recover deleted draft")
        #expect(restored.sessions[0].fileURL == firstURL)
        #expect(restored.sessions[0].encoding == .utf16)
        #expect(restored.sessions[0].isDirty)
        #expect(restored.sessions[1].text == "Recover changed draft")
        #expect(restored.sessions[1].savedBaselineText == "Baseline")
        #expect(restored.sessions[1].hasExternalConflict)
        #expect(restored.sessions[1].lastExternalDiskText == "New disk version")
    }

    @Test func recoveryAutosavesEditsAndTerminationSurvivesUnregistration() async throws {
        let defaults = UserDefaults(suiteName: "LucidAutosave-\(UUID())")!
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let manager = WindowDocumentManager()
        restorer.register(manager: manager)
        manager.activeSession.text = "Typed after opening the window"
        try await Task.sleep(nanoseconds: 400_000_000)
        #expect(restorer.loadSavedSession()?.windows.first?.tabs.first?.draftText == manager.activeSession.text)
        restorer.prepareForTermination()
        restorer.unregister(manager: manager)
        #expect(restorer.loadSavedSession()?.windows.first?.tabs.first?.draftText == manager.activeSession.text)
    }

    @Test func restorationConsumesRecordsOnceAndProtectsPendingWindows() throws {
        let defaults = UserDefaults(suiteName: "LucidWindows-\(UUID())")!
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let a = WindowDocumentManager(initialSession: DocumentSession(text: "Window A"))
        let b = WindowDocumentManager(initialSession: DocumentSession(text: "Window B"))
        restorer.saveSession(managers: [a, b])
        let restoredA = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restoredA))
        restorer.saveSession(managers: [restoredA])
        #expect(restorer.loadSavedSession()?.windows.count == 2)
        #expect(restorer.needsAdditionalRestorationWindow(nativeWindowCount: 1))
        #expect(!restorer.needsAdditionalRestorationWindow(nativeWindowCount: 2))
        #expect(!restorer.isExtraRestorationWindow(WindowDocumentManager()))
        #expect(!restorer.isExtraRestorationWindow(restoredA))
        let restoredB = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restoredB))
        #expect(restoredB.activeSession.text == "Window B")
        #expect(restorer.isExtraRestorationWindow(WindowDocumentManager()))
        #expect(!restorer.needsAdditionalRestorationWindow(nativeWindowCount: 2))
        #expect(!restorer.restoreInto(documentManager: WindowDocumentManager()))
    }

    @Test func sameMarkdownTabSwitchReloadsRelativeImages() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("audit-images-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let dirs = [root.appendingPathComponent("a"), root.appendingPathComponent("b")]
        for (i, dir) in dirs.enumerated() {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: i + 1, pixelsHigh: 1,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            try image.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent("image.png"))
        }
        let state = AuditPreviewState(url: dirs[0].appendingPathComponent("doc.md"))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AuditPreviewHarness(state: state))
        window.orderBack(nil)
        defer { window.contentView = nil; window.close() }
        for _ in 0..<50 where state.web == nil { try await Task.sleep(nanoseconds: 20_000_000) }
        let hostedWeb = try #require(state.web)
        // SwiftPM's test host has no app-bundle WebEngine; load the repository's
        // exact engine into the actual representable and coordinator.
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let index = repo.appendingPathComponent("Sources/Lucid/Resources/WebEngine/index.html")
        (hostedWeb.navigationDelegate as? PreviewWebView.Coordinator)?.allowedFileURL = index
        hostedWeb.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        for _ in 0..<200 {
            if let web = state.web, (try? await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth ?? 0")) as? Int == 1 { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let web = try #require(state.web)
        #expect((try await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth ?? 0")) as? Int == 1)
        state.url = dirs[1].appendingPathComponent("doc.md")
        for _ in 0..<200 {
            if (try? await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth ?? 0")) as? Int == 2 { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect((try await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth ?? 0")) as? Int == 2)
    }

}


@MainActor private final class AuditPreviewState: ObservableObject {
    @Published var url: URL
    var web: WKWebView?
    init(url: URL) { self.url = url }
}

@MainActor private struct AuditPreviewHarness: View {
    @ObservedObject var state: AuditPreviewState
    var body: some View {
        PreviewWebView(preferences: LucidPreferences.shared, markdown: "![Image](image.png)",
                       headings: .constant([]), activeHeading: .constant(nil),
                       webViewInstance: Binding(get: { state.web }, set: { state.web = $0 }),
                       documentFileURL: state.url)
    }
}
