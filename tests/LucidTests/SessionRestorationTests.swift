import Testing
import Foundation
@testable import Lucid

@Suite("SessionRestoration")
struct SessionRestorationTests {

    private func createIsolatedDefaults() -> UserDefaults {
        let suiteName = "test.lucid.sessionRestoration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func snapshotEncodingAndDecodingStability() throws {
        let tab1 = TabRestorationRecord(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/tmp/doc1.md"),
            fallbackPath: "/tmp/doc1.md",
            title: "doc1.md",
            cursorLine: 42,
            cursorCol: 8,
            selectedRangeLocation: 100,
            selectedRangeLength: 5,
            readingPosition: ReadingPosition(line: 40, top: true, end: false),
            viewMode: .split,
            splitFraction: 0.6
        )

        let tab2 = TabRestorationRecord(
            id: UUID(),
            fileURL: URL(fileURLWithPath: "/tmp/doc2.md"),
            fallbackPath: "/tmp/doc2.md",
            title: "doc2.md",
            cursorLine: 1,
            cursorCol: 1,
            selectedRangeLocation: 0,
            selectedRangeLength: 0,
            readingPosition: .documentTop,
            viewMode: .editor,
            splitFraction: 0.5
        )

        let window = WindowRestorationRecord(id: UUID(), activeTabID: tab1.id, tabs: [tab1, tab2])
        let originalSnapshot = AppSessionSnapshot(version: 1, timestamp: Date(), windows: [window])

        let data = try JSONEncoder().encode(originalSnapshot)
        let decoded = try JSONDecoder().decode(AppSessionSnapshot.self, from: data)

        #expect(decoded.version == 1)
        #expect(decoded.windows.count == 1)
        #expect(decoded.windows[0].activeTabID == tab1.id)
        #expect(decoded.windows[0].tabs.count == 2)
        #expect(decoded.windows[0].tabs[0].title == "doc1.md")
        #expect(decoded.windows[0].tabs[0].cursorLine == 42)
        #expect(decoded.windows[0].tabs[0].viewMode == ViewMode.split)
        #expect(decoded.windows[0].tabs[0].splitFraction == 0.6)
        #expect(decoded.windows[0].tabs[1].viewMode == ViewMode.editor)
    }

    @MainActor
    @Test
    func restorationSkipsMissingFilesGracefully() throws {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        // Create one real temporary file and one non-existent file
        let tempDir = FileManager.default.temporaryDirectory
        let existingURL = tempDir.appendingPathComponent("lucid-session-existing-\(UUID().uuidString).md")
        try "# Existing Document\nContent".write(to: existingURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: existingURL) }

        let missingURL = tempDir.appendingPathComponent("lucid-session-missing-\(UUID().uuidString).md")

        let tabExisting = TabRestorationRecord(
            id: UUID(),
            fileURL: existingURL,
            fallbackPath: existingURL.path,
            title: existingURL.lastPathComponent
        )
        let tabMissing = TabRestorationRecord(
            id: UUID(),
            fileURL: missingURL,
            fallbackPath: missingURL.path,
            title: missingURL.lastPathComponent
        )

        let windowRecord = WindowRestorationRecord(
            id: UUID(),
            activeTabID: tabMissing.id, // Active tab was the missing one!
            tabs: [tabMissing, tabExisting]
        )
        let snapshot = AppSessionSnapshot(version: 1, timestamp: Date(), windows: [windowRecord])
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: SessionRestorationManager.sessionDefaultsKey)

        let docManager = WindowDocumentManager()
        let restored = manager.restoreInto(documentManager: docManager)

        #expect(restored == true)
        // Missing tab was safely skipped without errors
        #expect(docManager.sessions.count == 1)
        #expect(docManager.sessions[0].fileURL?.path == existingURL.path)
        // Active tab fell back to the surviving valid tab
        #expect(docManager.activeSessionID == docManager.sessions[0].id)
    }

    @MainActor
    @Test
    func restorationHonorsPreferenceToggle() throws {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        let tempDir = FileManager.default.temporaryDirectory
        let existingURL = tempDir.appendingPathComponent("lucid-session-toggle-\(UUID().uuidString).md")
        try "Toggle test".write(to: existingURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: existingURL) }

        let tab = TabRestorationRecord(id: UUID(), fileURL: existingURL, fallbackPath: existingURL.path, title: "toggle.md")
        let window = WindowRestorationRecord(id: UUID(), activeTabID: tab.id, tabs: [tab])
        let snapshot = AppSessionSnapshot(version: 1, timestamp: Date(), windows: [window])
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: SessionRestorationManager.sessionDefaultsKey)

        let oldPref = LucidPreferences.shared.restoreSessionOnLaunch
        defer { LucidPreferences.shared.restoreSessionOnLaunch = oldPref }

        // Disable restoration
        LucidPreferences.shared.restoreSessionOnLaunch = false

        let docManager = WindowDocumentManager()
        let restored = manager.restoreInto(documentManager: docManager)

        #expect(restored == false)
        #expect(docManager.sessions.count == 1)
        #expect(docManager.sessions[0].isUntitled)
    }

    @MainActor
    @Test
    func restoresActiveTabAndCursorState() throws {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        let tempDir = FileManager.default.temporaryDirectory
        let doc1 = tempDir.appendingPathComponent("lucid-cursor-1-\(UUID().uuidString).md")
        let doc2 = tempDir.appendingPathComponent("lucid-cursor-2-\(UUID().uuidString).md")
        try "Line 1\nLine 2\nLine 3\nLine 4".write(to: doc1, atomically: true, encoding: .utf8)
        try "Alpha\nBeta\nGamma".write(to: doc2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: doc1)
            try? FileManager.default.removeItem(at: doc2)
        }

        let tab1 = TabRestorationRecord(
            id: UUID(),
            fileURL: doc1,
            fallbackPath: doc1.path,
            title: "doc1.md",
            cursorLine: 3,
            cursorCol: 2,
            viewMode: .editor,
            splitFraction: 0.4
        )
        let tab2 = TabRestorationRecord(
            id: UUID(),
            fileURL: doc2,
            fallbackPath: doc2.path,
            title: "doc2.md",
            cursorLine: 2,
            cursorCol: 5,
            viewMode: .split,
            splitFraction: 0.7
        )

        let window = WindowRestorationRecord(id: UUID(), activeTabID: tab2.id, tabs: [tab1, tab2])
        let snapshot = AppSessionSnapshot(version: 1, timestamp: Date(), windows: [window])
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: SessionRestorationManager.sessionDefaultsKey)

        let docManager = WindowDocumentManager()
        let restored = manager.restoreInto(documentManager: docManager)

        #expect(restored == true)
        #expect(docManager.sessions.count == 2)
        #expect(docManager.activeSessionID == tab2.id)

        let active = docManager.activeSession
        #expect(active.cursorLine == 2)
        #expect(active.cursorCol == 5)
        #expect(active.viewMode == ViewMode.split)
        #expect(active.splitFraction == 0.7)

        let inactive = docManager.sessions.first(where: { $0.id == tab1.id })!
        #expect(inactive.cursorLine == 3)
        #expect(inactive.cursorCol == 2)
        #expect(inactive.viewMode == ViewMode.editor)
    }

    @MainActor
    @Test
    func corruptedSessionDataHandledSafely() {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        defaults.set("garbage-corrupt-data".data(using: .utf8)!, forKey: SessionRestorationManager.sessionDefaultsKey)

        let loaded = manager.loadSavedSession()
        #expect(loaded == nil)

        let docManager = WindowDocumentManager()
        let restored = manager.restoreInto(documentManager: docManager)
        #expect(restored == false)
    }

    @MainActor
    @Test
    func unregisterClearsSessionWhenLastManagerUnregisters() throws {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        let tempDir = FileManager.default.temporaryDirectory
        let doc = tempDir.appendingPathComponent("lucid-unreg-\(UUID().uuidString).md")
        try "# Sample".write(to: doc, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: doc) }

        let docManager = WindowDocumentManager()
        docManager.openFile(url: doc)
        manager.register(manager: docManager)
        manager.saveCurrentSession()

        // Should have saved session
        #expect(manager.loadSavedSession() != nil)

        // When unregistering the manager
        manager.unregister(manager: docManager)

        // Session should be cleared
        #expect(manager.loadSavedSession() == nil)
    }

    @MainActor
    @Test
    func activeManagersExposesRegisteredManagers() throws {
        let defaults = createIsolatedDefaults()
        let manager = SessionRestorationManager(userDefaults: defaults)

        let docManager = WindowDocumentManager()
        manager.register(manager: docManager)
        #expect(manager.activeManagers.contains(where: { $0.id == docManager.id }))

        manager.unregister(manager: docManager)
        #expect(!manager.activeManagers.contains(where: { $0.id == docManager.id }))
    }
}
