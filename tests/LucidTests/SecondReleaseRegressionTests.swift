import Foundation
import AppKit
import SwiftUI
import WebKit
import Testing
@testable import Lucid

@Suite("Second release regressions", .serialized)
@MainActor struct SecondReleaseRegressionTests {
    @Test func keyEventBeforeCoordinatorRefreshMustStayInDisplayedTab() throws {
        _ = NSApplication.shared
        for iteration in 0..<25 {
            let a = DocumentSession(text: "Document A \(iteration)")
            let manager = WindowDocumentManager(initialSession: a)
            let b = manager.newTab(text: "Document B \(iteration)")
            manager.selectTab(id: a.id)
            // This is the dynamic binding used by MainWindowView.activeDocumentText.
            let view = EditorView(text: Binding(get: { manager.activeSession.text },
                                               set: { manager.activeSession.text = $0 }),
                                  documentSession: a)
            let coordinator = view.makeCoordinator()
            let editor = LucidTextView(frame: .zero)
            editor.allowsUndo = true
            editor.displaySession(a)
            editor.delegate = coordinator
            // Publish selection, then deliver a native edit before SwiftUI's
            // onChange/updateNSView can refresh either the editor or coordinator.
            manager.selectTab(id: b.id)
            editor.insertText("!", replacementRange: NSRange(location: (a.text as NSString).length, length: 0))
            #expect(a.text == "Document A \(iteration)!")
            #expect(b.text == "Document B \(iteration)")
            #expect(a.undoManager.canUndo)
            #expect(!b.undoManager.canUndo)
            editor.delegate = nil
            a.undoManager.removeAllActions()
        }
    }

    @Test func rapidEditsUndoRedoDelayedCallbacksAndSnapshotsKeepSessionIdentity() throws {
        _ = NSApplication.shared
        let suite = "second-routing-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("routing-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for iteration in 0..<25 {
            let url = root.appendingPathComponent("\(iteration).md")
            let base = "Named A 👩🏽‍💻 \(iteration)"
            try base.write(to: url, atomically: true, encoding: .utf8)
            let manager = WindowDocumentManager()
            let a = try #require(manager.openFile(url: url))
            let b = manager.newTab(text: "B")
            manager.selectTab(id: a.id)
            let view = EditorView(text: Binding(get: { manager.activeSession.text }, set: { manager.activeSession.text = $0 }), documentSession: a)
            let coordinator = view.makeCoordinator()
            let editor = LucidTextView(frame: .zero)
            editor.allowsUndo = true
            editor.displaySession(a)
            editor.delegate = coordinator
            manager.selectTab(id: b.id)
            editor.insertText("!", replacementRange: NSRange(location: (base as NSString).length, length: 0))
            editor.breakUndoCoalescing()
            editor.undo(nil)
            #expect(a.text == base && b.text == "B")
            editor.redo(nil)
            #expect(a.text == base + "!" && b.text == "B")
            manager.saveSession(a) { #expect($0) }
            #expect(try String(contentsOf: url, encoding: .utf8) == base + "!")
            // The coordinator still holds A's callbacks when B is displayed.
            editor.displaySession(b)
            editor.insertText("?", replacementRange: NSRange(location: 1, length: 0))
            coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
            coordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: editor))
            #expect(a.text == base + "!" && b.text == "B?")
            #expect(a.cursorCol == base.count + 2 && b.cursorCol == 3)
            editor.breakUndoCoalescing()
            editor.undo(nil)
            #expect(b.text == "B" && a.text == base + "!")
            editor.redo(nil)
            restorer.saveSession(managers: [manager])
            let record = try #require(restorer.loadSavedSession()?.windows.flatMap(\.tabs).first(where: { $0.id == b.id }))
            #expect(record.draftText == "B?")
            editor.delegate = nil
            a.undoManager.removeAllActions(); b.undoManager.removeAllActions()
            restorer.clearSession()
        }
    }

    @Test func fileFirstSnapshotsWithoutRestoreAndInterruptedHydrationSurviveRelaunches() throws {
        let suite = "second-pending-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let seed = SessionRestorationManager(userDefaults: defaults)
        let a = WindowDocumentManager(initialSession: DocumentSession(text: "Recovery A"))
        let b = WindowDocumentManager(initialSession: DocumentSession(text: "Recovery B"))
        seed.saveSession(managers: [a, b])
        let originalIDs = [a.activeSession.id, b.activeSession.id]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("file-first-\(UUID()).md")
        try "Launch file".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let named = NSDocument(); named.fileURL = url
        NSDocumentController.shared.addDocument(named)
        defer { NSDocumentController.shared.removeDocument(named) }
        // Pending recovery is visible before any window manager exists.
        #expect(SessionRestorationManager(userDefaults: defaults).hasPendingRestorationWindows)
        // Repeated explicit launches that never invoke restoreInto.
        for _ in 0..<3 {
            let restorer = SessionRestorationManager(userDefaults: defaults)
            let opened = WindowDocumentManager()
            _ = opened.openFile(url: url)
            restorer.register(manager: opened)
            restorer.saveCurrentSession()
            let drafts = try #require(restorer.loadSavedSession()).windows.flatMap(\.tabs).filter { originalIDs.contains($0.id) }
            #expect(drafts.map(\.draftText) == ["Recovery A", "Recovery B"])
            #expect(Set(drafts.map(\.id)).count == 2)
            restorer.prepareForTermination()
        }
        let firstLaunch = SessionRestorationManager(userDefaults: defaults)
        var firstWindows: [WindowDocumentManager] = []
        repeat {
            let window = WindowDocumentManager()
            firstLaunch.register(manager: window)
            #expect(firstLaunch.restoreInto(documentManager: window))
            firstWindows.append(window)
        } while firstWindows.last?.activeSession.id != originalIDs[0] && firstLaunch.hasPendingRestorationWindows
        let firstDraft = try #require(firstWindows.flatMap(\.sessions).first(where: { $0.id == originalIDs[0] }))
        #expect(firstDraft.text == "Recovery A")
        firstDraft.text = "Recovery A edited"
        firstLaunch.prepareForTermination() // stop before Recovery B hydrates
        let secondLaunch = SessionRestorationManager(userDefaults: defaults)
        var recovered: [WindowDocumentManager] = []
        while secondLaunch.hasPendingRestorationWindows || recovered.isEmpty {
            let window = WindowDocumentManager()
            secondLaunch.register(manager: window)
            guard secondLaunch.restoreInto(documentManager: window) else { break }
            recovered.append(window)
        }
        #expect(recovered.flatMap(\.sessions).filter { originalIDs.contains($0.id) }.map(\.text) == ["Recovery A edited", "Recovery B"])
        secondLaunch.saveCurrentSession()
        let tabs = try #require(secondLaunch.loadSavedSession()).windows.flatMap(\.tabs)
        #expect(originalIDs.allSatisfy { id in tabs.filter { $0.id == id }.count == 1 })
        secondLaunch.prepareForTermination()
    }

    @Test func fileLaunchCleanupCannotCloseAWindowAwaitingRecovery() throws {
        _ = NSApplication.shared
        let suite = "second-cleanup-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let seed = WindowDocumentManager(initialSession: DocumentSession(text: "Pending recovery"))
        restorer.saveSession(managers: [seed])
        let pending = WindowDocumentManager()
        restorer.register(manager: pending)
        let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let document = NSDocument()
        document.addWindowController(NSWindowController(window: window))
        pending.hostWindow = window
        let named = NSDocument()
        named.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("launch-cleanup-\(UUID()).md")
        NSDocumentController.shared.addDocument(document)
        NSDocumentController.shared.addDocument(named)
        defer {
            NSDocumentController.shared.removeDocument(document)
            NSDocumentController.shared.removeDocument(named)
            window.close()
            LaunchUntitledCleanup.finishLaunch()
        }
        LaunchUntitledCleanup.markLaunch()
        LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile(restorationManager: restorer)
        #expect(NSDocumentController.shared.documents.contains(where: { $0 === document }))
        #expect(restorer.restoreInto(documentManager: pending))
        LaunchUntitledCleanup.closeUntouchedUntitledIfOpeningFile(restorationManager: restorer)
        #expect(NSDocumentController.shared.documents.contains(where: { $0 === document }))
        #expect(pending.activeSession.text == "Pending recovery")
        restorer.prepareForTermination()
    }

    @Test func immediateMoveAndReplacementAtOldPathSaveOnlyTheOriginalVnode() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("identity-\(UUID())")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("other"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for round in 0..<25 {
            let old = root.appendingPathComponent("old-\(round).md")
            let moved = root.appendingPathComponent("other/renamed-\(round).md")
            try "Baseline".write(to: old, atomically: true, encoding: .utf8)
            let manager = WindowDocumentManager()
            let session = try #require(manager.openFile(url: old))
            session.text = "Unsaved \(round)"
            _ = manager.newTab(text: "Other buffer")
            try FileManager.default.moveItem(at: old, to: moved)
            try "Unrelated replacement".write(to: old, atomically: true, encoding: .utf8)
            // Do not yield: save must resolve identity without waiting for events.
            manager.saveSession(session) { #expect($0) }
            #expect(try String(contentsOf: old, encoding: .utf8) == "Unrelated replacement")
            #expect(try String(contentsOf: moved, encoding: .utf8) == "Unsaved \(round)")
            #expect(session.fileURL == moved && !session.isDirty)
            #expect(manager.activeSession.text == "Other buffer")
        }
    }

    @Test func deletionAndAmbiguousReplacementRequireDestinationAndPreserveCancelledEdits() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("destination-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for replacement in [false, true] {
            let old = root.appendingPathComponent("old-\(replacement).md")
            let target = root.appendingPathComponent("chosen-\(replacement).md")
            try "Baseline".write(to: old, atomically: true, encoding: .utf8)
            let manager = WindowDocumentManager()
            let session = try #require(manager.openFile(url: old))
            session.text = "Must survive cancellation"
            try FileManager.default.removeItem(at: old)
            if replacement { try "Replacement".write(to: old, atomically: true, encoding: .utf8) }
            var decisions = 0
            manager.chooseSaveDestination = { candidate, _, reply in
                #expect(candidate === session)
                decisions += 1
                reply(nil)
            }
            manager.saveSession(session) { #expect(!$0) }
            manager.saveSession(session, saveAs: true) { #expect(!$0) }
            DocumentCloseReview.review(managers: [manager], prompt: { _, _, reply in reply(.save) }) { #expect($0 == nil) }
            #expect(decisions == 3)
            #expect(session.text == "Must survive cancellation" && session.savedBaselineText == "Baseline" && session.isDirty)
            #expect(session.fileURL == old && manager.sessions.contains(where: { $0 === session }))
            if replacement { #expect(try String(contentsOf: old, encoding: .utf8) == "Replacement") }
            else { #expect(!FileManager.default.fileExists(atPath: old.path)) }
            manager.chooseSaveDestination = { _, _, reply in reply(target) }
            manager.saveSession(session) { #expect($0) }
            #expect(try String(contentsOf: target, encoding: .utf8) == "Must survive cancellation")
            #expect(session.fileURL == target && !session.isDirty)
        }
    }

    @Test func delayedAssetRequestUsesItsOriginatingDocument() throws {
        let a = URL(fileURLWithPath: "/tmp/a space # % café/doc.md")
        var parts = URLComponents(string: "lucid-asset://doc/image.png")!
        parts.queryItems = [URLQueryItem(name: "document", value: a.path), URLQueryItem(name: "generation", value: "42")]
        let url = try #require(parts.url)
        #expect(LocalAssetSchemeHandler.resolve(url, documentDirectory: URL(fileURLWithPath: "/tmp/b")) == a.deletingLastPathComponent().appendingPathComponent("image.png"))
    }

    @Test func explicitFileLaunchMustRetainUnhydratedRecovery() throws {
        _ = NSApplication.shared
        let suite = "second-audit-launch-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let recovery = WindowDocumentManager(initialSession: DocumentSession(text: "UNSAVED RECOVERY DRAFT"))
        restorer.saveSession(managers: [recovery])
        let named = NSDocument()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("explicit-launch-\(UUID()).md")
        try "Explicitly opened document".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        named.fileURL = url
        NSDocumentController.shared.addDocument(named)
        defer { NSDocumentController.shared.removeDocument(named) }
        let launched = WindowDocumentManager(initialSession: DocumentSession(fileURL: url, text: "Explicitly opened document", savedBaselineText: "Explicitly opened document"))
        restorer.register(manager: launched)
        #expect(!restorer.restoreInto(documentManager: launched))
        // Same autosnapshot invoked after onAppear publishes view-mode state.
        restorer.saveCurrentSession()
        #expect(restorer.loadSavedSession()?.windows.flatMap(\.tabs).contains(where: { $0.draftText == "UNSAVED RECOVERY DRAFT" }) == true)
    }

    @Test func undoRedoSurvivesSaveAndSwitchButIsClearedByReload() async throws {
        _ = NSApplication.shared
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("undo-save-\(UUID()).md")
        try "Base 👩🏽‍💻 é".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let a = try #require(manager.openFile(url: url))
        let b = manager.newTab(text: "Other")
        let editor = LucidTextView(frame: .zero)
        editor.allowsUndo = true
        editor.displaySession(a)
        editor.insertText("!", replacementRange: NSRange(location: (a.text as NSString).length, length: 0))
        a.text = editor.string
        editor.breakUndoCoalescing()
        manager.saveSession(a) { #expect($0) }
        editor.displaySession(b)
        editor.displaySession(a)
        editor.undo(nil)
        a.text = editor.string
        #expect(a.isDirty)
        #expect(a.text == "Base 👩🏽‍💻 é")
        editor.redo(nil)
        a.text = editor.string
        #expect(!a.isDirty)
        #expect(try String(contentsOf: url, encoding: .utf8) == a.text)
        // Clean inactive reload must invalidate range-based history.
        editor.displaySession(b)
        try "External replacement".write(to: url, atomically: true, encoding: .utf8)
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(a.text == "External replacement")
        #expect(!a.undoManager.canUndo && !a.undoManager.canRedo)
    }

    @Test func emptyDirtyDraftAndUnavailableFileSurviveRecovery() throws {
        let suite = "second-audit-empty-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("空 白 # %-\(UUID()).md")
        try "Nonempty baseline".write(to: url, atomically: true, encoding: .utf16)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let a = try #require(manager.openFile(url: url))
        a.text = ""
        restorer.saveSession(managers: [manager])
        try FileManager.default.removeItem(at: url)
        let restored = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: restored))
        #expect(restored.activeSession.text == "")
        #expect(restored.activeSession.savedBaselineText == "Nonempty baseline")
        #expect(restored.activeSession.isDirty)
        #expect(restored.activeSession.encoding == .utf16)
    }

    @Test func legacySnapshotWithoutNewFieldsStillRestores() throws {
        let suite = "second-audit-legacy-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let a = DocumentSession(text: "Old untitled draft", viewMode: .split, splitFraction: 0.7)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(AppSessionSnapshot(windows: [WindowRestorationRecord(activeTabID: a.id, tabs: [TabRestorationRecord(from: a)])]))) as? [String: Any])
        var windows = json["windows"] as! [[String: Any]]
        var tabs = windows[0]["tabs"] as! [[String: Any]]
        tabs[0].removeValue(forKey: "savedBaselineText")
        tabs[0].removeValue(forKey: "encodingRawValue")
        windows[0]["tabs"] = tabs
        json["windows"] = windows
        defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: SessionRestorationManager.sessionDefaultsKey)
        let manager = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: manager))
        #expect(manager.activeSession.text == a.text)
        #expect(manager.activeSession.viewMode == .split)
        #expect(manager.activeSession.splitFraction == 0.7)
    }

    @Test func largeUnicodeMultiWindowRecoveryAndUnusualFilenameRoundTrip() throws {
        let suite = "second-audit-large-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let restorer = SessionRestorationManager(userDefaults: defaults)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("空 白 # % café-\(UUID()).md")
        let large = String(repeating: "# 👩🏽‍💻 é 漢字\nUnicode contents with tabs\tand CRLF\r\n", count: 20000)
        try "Original".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let a = WindowDocumentManager()
        let draft = try #require(a.openFile(url: url))
        draft.text = large
        let b = WindowDocumentManager(initialSession: DocumentSession(text: "Second distinct window"))
        restorer.saveSession(managers: [a,b])
        let x = WindowDocumentManager(), y = WindowDocumentManager()
        #expect(restorer.restoreInto(documentManager: x))
        #expect(restorer.restoreInto(documentManager: y))
        #expect(x.activeSession.text == large && x.activeSession.isDirty)
        #expect(y.activeSession.text == "Second distinct window")
        x.saveSession(x.activeSession) { #expect($0) }
        #expect(try String(contentsOf: url, encoding: .utf8) == large)
        #expect(!x.activeSession.isDirty)
    }

    @Test func repeatedExternalDivergenceAndBaselineReversionPreserveLocalWork() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("second-conflict-\(UUID()).md")
        try "Baseline".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = WindowDocumentManager()
        let a = try #require(manager.openFile(url: url))
        _ = manager.newTab()
        a.text = "Local edits"
        for round in 0..<5 {
            try "External \(round)".write(to: url, atomically: true, encoding: .utf8)
            try await Task.sleep(nanoseconds: 300_000_000)
            #expect(a.text == "Local edits" && a.savedBaselineText == "Baseline")
            #expect(a.hasExternalConflict && a.lastExternalDiskText == "External \(round)")
            try "Baseline".write(to: url, atomically: true, encoding: .utf8)
            try await Task.sleep(nanoseconds: 300_000_000)
            #expect(!a.hasExternalConflict && a.lastExternalDiskText == nil)
            #expect(a.text == "Local edits" && a.isDirty)
        }
    }

    @Test func externalRenameMustNotSilentlySaveToAbandonedPath() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("second-move-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let old = root.appendingPathComponent("old.md")
        let moved = root.appendingPathComponent("moved.md")
        try "Original".write(to: old, atomically: true, encoding: .utf8)
        let manager = WindowDocumentManager()
        let a = try #require(manager.openFile(url: old))
        _ = manager.newTab()
        try FileManager.default.moveItem(at: old, to: moved)
        try await Task.sleep(nanoseconds: 400_000_000)
        a.text = "Edit after move"
        manager.saveSession(a) { #expect($0) }
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(try String(contentsOf: moved, encoding: .utf8) == "Edit after move")
    }
}

@MainActor private final class SecondPreviewState: ObservableObject {
    @Published var url: URL
    @Published var markdown = "![Image](image.png)"
    @Published var visible = true
    var web: WKWebView?
    init(url: URL) { self.url = url }
}
@MainActor private struct SecondPreviewHarness: View {
    @ObservedObject var state: SecondPreviewState
    var body: some View {
        PreviewWebView(preferences: LucidPreferences.shared, markdown: state.markdown,
                       headings: .constant([]), activeHeading: .constant(nil),
                       webViewInstance: Binding(get: { state.web }, set: { state.web = $0 }),
                       documentFileURL: state.url, isActive: state.visible)
    }
}
@Suite("Second release WebKit regressions", .serialized)
@MainActor struct SecondPreviewRegressionTests {
    @Test func replacedImagesStayCurrentAcrossRepeatedNavigation() async throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("second-images-\(UUID())")
        let dirs = [root.appendingPathComponent("a space # % café"), root.appendingPathComponent("b")]
        defer { try? FileManager.default.removeItem(at: root) }
        func writeImage(_ dir: URL, width: Int) throws {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let img = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: width + 1,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            try img.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent("image.png"), options: .atomic)
        }
        try writeImage(dirs[0], width: 1)
        try writeImage(dirs[1], width: 2)
        try writeImage(root, width: 20)
        let state = SecondPreviewState(url: dirs[0].appendingPathComponent("doc.md"))
        state.markdown = "![Image](image.png) ![Absolute](\(root.path)/image.png) ![Shared](../image.png)"
        let window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 600,height: 400), styleMask: [.titled],backing: .buffered,defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SecondPreviewHarness(state: state))
        window.orderBack(nil)
        defer { window.contentView = nil; window.close() }
        for _ in 0..<100 where state.web == nil { try await Task.sleep(nanoseconds: 20_000_000) }
        let web = try #require(state.web)
        let host = try #require(web.superview as? LucidWebContainerView)
        func hidePreview() async throws {
            state.visible = false
            // SwiftUI can coalesce a false/true pair under concurrent suite load.
            // Observe the native transition before exercising hidden asset replacement.
            for _ in 0..<200 {
                if !host.isPaneActive { break }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            try #require(!host.isPaneActive)
        }
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let index = repo.appendingPathComponent("Sources/Lucid/Resources/WebEngine/index.html")
        (web.navigationDelegate as? PreviewWebView.Coordinator)?.allowedFileURL = index
        web.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
        var initialWidth: Int?
        for _ in 0..<200 {
            initialWidth = (try? await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth")) as? Int
            if initialWidth == 1 { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(initialWidth == 1)
        for round in 0..<10 {
            let width = round + 3
            let dir = dirs[(round + 1) % 2]
            try writeImage(dir, width: width)
            try writeImage(root, width: width + 20)
            try await hidePreview()
            state.url = dir.appendingPathComponent(round % 3 == 0 ? "saved-as.md" : "doc.md")
            state.visible = true
            var actualIdentity: String?
            var dimensions: [[Int]]?
            for _ in 0..<250 {
                // Read identity and dimensions in one WebKit transaction. A new
                // render can replace image nodes between separate IPC calls.
                let snapshot = try await web.evaluateJavaScript("({identity: lucid.documentIdentity, dimensions: Array.from(document.querySelectorAll('#lucid-content img')).map(i => [i.naturalWidth, i.naturalHeight])})") as? [String: Any]
                actualIdentity = snapshot?["identity"] as? String
                dimensions = snapshot?["dimensions"] as? [[Int]]
                if actualIdentity == state.url.standardizedFileURL.path && dimensions == [[width, width + 1], [width + 20, width + 21], [width + 20, width + 21]] { break }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            #expect(actualIdentity == state.url.standardizedFileURL.path)
            #expect(dimensions == [[width, width + 1], [width + 20, width + 21], [width + 20, width + 21]])
            // Same document and Markdown, changed assets while the preview is hidden.
            try await hidePreview()
            try writeImage(dir, width: width + 40)
            state.visible = true
            var revealedWidth: Int?
            for _ in 0..<250 {
                revealedWidth = (try? await web.evaluateJavaScript("document.querySelector('#lucid-content img')?.naturalWidth")) as? Int
                if revealedWidth == width + 40 { break }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            #expect(revealedWidth == width + 40)
        }
    }
}
