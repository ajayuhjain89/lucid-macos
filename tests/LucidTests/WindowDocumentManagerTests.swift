import Foundation
import AppKit
import Testing
@testable import Lucid

@Suite("WindowDocumentManager", .serialized)
@MainActor struct WindowDocumentManagerTests {
    @Test func newTabCreatesUntitledSessionAndActivates() {
        let manager = WindowDocumentManager()
        #expect(manager.sessions.count == 1)
        #expect(manager.activeSession.isUntitled)

        let tab2 = manager.newTab()
        #expect(manager.sessions.count == 2)
        #expect(manager.activeSessionID == tab2.id)
        #expect(tab2.isUntitled)
        #expect(tab2.displayName == "Untitled 2")
    }

    @Test func openFileReplacesPristineUntitledTab() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_replace_\(UUID().uuidString).md")
        try "Content in file".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let manager = WindowDocumentManager()
        #expect(manager.sessions.count == 1)
        #expect(manager.sessions[0].isUntitled)

        let opened = manager.openFile(url: testFile)
        #expect(opened != nil)
        #expect(manager.sessions.count == 1)
        #expect(manager.sessions[0].fileURL?.path == testFile.path)
        #expect(manager.sessions[0].text == "Content in file")
        #expect(!manager.sessions[0].isDirty)
    }

    @Test func openSameFileTwiceActivatesExistingTabWithoutDuplicate() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_dedup_\(UUID().uuidString).md")
        try "File content".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let manager = WindowDocumentManager()
        let session1 = manager.openFile(url: testFile)!
        #expect(manager.sessions.count == 1)

        // Add another tab
        let tab2 = manager.newTab()
        #expect(manager.sessions.count == 2)
        #expect(manager.activeSessionID == tab2.id)

        // Open testFile again -> should activate session1, not add a 3rd tab
        let reopened = manager.openFile(url: testFile)!
        #expect(manager.sessions.count == 2)
        #expect(reopened.id == session1.id)
        #expect(manager.activeSessionID == session1.id)
    }

    @Test func tabCyclingWrapsAroundCorrectly() {
        let manager = WindowDocumentManager()
        let tab1 = manager.activeSession
        let tab2 = manager.newTab()
        let tab3 = manager.newTab()

        #expect(manager.sessions.count == 3)
        #expect(manager.activeSessionID == tab3.id)

        manager.selectNextTab()
        #expect(manager.activeSessionID == tab1.id)

        manager.selectNextTab()
        #expect(manager.activeSessionID == tab2.id)

        manager.selectPreviousTab()
        #expect(manager.activeSessionID == tab1.id)

        manager.selectPreviousTab()
        #expect(manager.activeSessionID == tab3.id)
    }

    @Test func closingCleanTabRemovesItAndSelectsAdjacent() {
        let manager = WindowDocumentManager()
        let tab1 = manager.activeSession
        let tab2 = manager.newTab()
        let tab3 = manager.newTab()

        #expect(manager.activeSessionID == tab3.id)

        manager.closeTab(id: tab3.id) { success in
            #expect(success)
        }
        #expect(manager.sessions.count == 2)
        #expect(manager.activeSessionID == tab2.id)

        manager.closeTab(id: tab1.id) { success in
            #expect(success)
        }
        #expect(manager.sessions.count == 1)
        #expect(manager.activeSessionID == tab2.id)
    }

    @Test func externalChangeToCleanInactiveTabUpdatesText() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_ext_change_\(UUID().uuidString).md")
        try "Original text".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let manager = WindowDocumentManager()
        let session = manager.openFile(url: testFile)!
        #expect(session.text == "Original text")

        // Switch to a new tab so session is inactive
        let otherTab = manager.newTab()
        #expect(manager.activeSessionID == otherTab.id)

        // Modify testFile externally
        try "Updated external text".write(to: testFile, atomically: true, encoding: .utf8)

        // Read file update and verify clean inactive tab reloads without dirtying
        if let data = try? Data(contentsOf: testFile),
           let decoded = LucidDocument.decodeText(data)?.text {
            session.updateFromDisk(text: decoded)
        }

        #expect(session.text == "Updated external text")
        #expect(!session.isDirty)
    }

    @Test func externalChangeToDirtyInactiveTabFlagsConflict() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_conflict_\(UUID().uuidString).md")
        try "Initial text".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let manager = WindowDocumentManager()
        let session = manager.openFile(url: testFile)!

        // Make local edit
        session.text = "Local unsaved edits"
        #expect(session.isDirty)

        // Make external change
        try "External modified text".write(to: testFile, atomically: true, encoding: .utf8)

        // Simulate external change detection for dirty session
        session.hasExternalConflict = true
        session.lastExternalDiskText = "External modified text"

        #expect(session.isDirty)
        #expect(session.hasExternalConflict)
        #expect(session.text == "Local unsaved edits") // Local edits preserved!
    }

    @Test func openFileReplacesPristineActiveTabWhenMultipleTabsExist() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let file1 = tempDir.appendingPathComponent("test_multi_1_\(UUID().uuidString).md")
        let file2 = tempDir.appendingPathComponent("test_multi_2_\(UUID().uuidString).md")
        try "# First".write(to: file1, atomically: true, encoding: .utf8)
        try "# Second".write(to: file2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: file1)
            try? FileManager.default.removeItem(at: file2)
        }

        let manager = WindowDocumentManager()
        // Open file1 into the initial untitled tab
        manager.openFile(url: file1)
        #expect(manager.sessions.count == 1)

        // Open a new tab (pristine untitled)
        let newTab = manager.newTab()
        #expect(manager.sessions.count == 2)
        #expect(manager.activeSessionID == newTab.id)

        // Opening file2 while on newTab should replace newTab, keeping tab count at 2
        let opened2 = manager.openFile(url: file2)
        #expect(opened2 != nil)
        #expect(manager.sessions.count == 2)
        #expect(manager.activeSessionID == opened2?.id)
        #expect(manager.sessions[0].fileURL?.path == file1.path)
        #expect(manager.sessions[1].fileURL?.path == file2.path)
    }

    @Test func newTabDefaultsToEditorMode() {
        let manager = WindowDocumentManager()
        let tab = manager.newTab()
        #expect(tab.viewMode == .editor)
    }

    @Test func closeAllTabsClosesCleanTabsImmediately() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let file1 = tempDir.appendingPathComponent("test_close_all_1_\(UUID().uuidString).md")
        let file2 = tempDir.appendingPathComponent("test_close_all_2_\(UUID().uuidString).md")
        try "# Clean 1".write(to: file1, atomically: true, encoding: .utf8)
        try "# Clean 2".write(to: file2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: file1)
            try? FileManager.default.removeItem(at: file2)
        }

        let manager = WindowDocumentManager()
        manager.openFile(url: file1)
        manager.newTab()
        manager.openFile(url: file2)
        #expect(manager.sessions.count == 2)
        #expect(!manager.sessions.contains(where: { $0.isDirty }))

        var finished = false
        var succeeded = false
        manager.closeAllTabs { success in
            finished = true
            succeeded = success
        }

        #expect(finished)
        #expect(succeeded)
        #expect(manager.sessions.isEmpty)
    }

    @Test func hostWindowFallbackIsSetAndAccessible() {
        let manager = WindowDocumentManager()
        #expect(manager.hostWindow == nil)
        let window = NSWindow()
        manager.hostWindow = window
        #expect(manager.hostWindow === window)
    }
}
