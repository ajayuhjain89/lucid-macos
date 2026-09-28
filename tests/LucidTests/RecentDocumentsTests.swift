import Foundation
import Testing
@testable import Lucid

@Suite("RecentDocuments", .serialized)
@MainActor struct RecentDocumentsTests {
    private func createTestDefaults() -> UserDefaults {
        let suiteName = "test.lucid.recents.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func recordingRecentFilesPreservesOrderingAndDeduplicates() {
        let defaults = createTestDefaults()
        let manager = RecentDocumentsManager(userDefaults: defaults)

        let urlA = URL(fileURLWithPath: "/tmp/test_a.md")
        let urlB = URL(fileURLWithPath: "/tmp/test_b.md")
        let urlC = URL(fileURLWithPath: "/tmp/test_c.md")

        manager.recordRecent(url: urlA)
        manager.recordRecent(url: urlB)
        manager.recordRecent(url: urlC)

        #expect(manager.recentURLs.count == 3)
        #expect(manager.recentURLs[0].lastPathComponent == "test_c.md")
        #expect(manager.recentURLs[1].lastPathComponent == "test_b.md")
        #expect(manager.recentURLs[2].lastPathComponent == "test_a.md")

        // Reopen A -> A should move to the front without duplicating
        manager.recordRecent(url: urlA)
        #expect(manager.recentURLs.count == 3)
        #expect(manager.recentURLs[0].lastPathComponent == "test_a.md")
        #expect(manager.recentURLs[1].lastPathComponent == "test_c.md")
        #expect(manager.recentURLs[2].lastPathComponent == "test_b.md")
    }

    @Test func recentsAreBoundedToMaxCapacity() {
        let defaults = createTestDefaults()
        let manager = RecentDocumentsManager(userDefaults: defaults)

        for i in 0..<30 {
            let url = URL(fileURLWithPath: "/tmp/file_\(i).md")
            manager.recordRecent(url: url)
        }

        #expect(manager.recentURLs.count == RecentDocumentsManager.maxRecents)
        #expect(manager.recentURLs[0].lastPathComponent == "file_29.md")
    }

    @Test func clearRecentsEmptiesListAndStorage() {
        let defaults = createTestDefaults()
        let manager = RecentDocumentsManager(userDefaults: defaults)

        manager.recordRecent(url: URL(fileURLWithPath: "/tmp/doc.md"))
        #expect(!manager.recentURLs.isEmpty)

        manager.clearRecents()
        #expect(manager.recentURLs.isEmpty)

        // New manager instance reading the same defaults should also be empty
        let reloaded = RecentDocumentsManager(userDefaults: defaults)
        #expect(reloaded.recentURLs.isEmpty)
    }

    @Test func initDoesNotPolluteIsolatedDefaultsFromSystemController() {
        let defaults = createTestDefaults()
        let freshManager = RecentDocumentsManager(userDefaults: defaults)
        // Fresh isolated defaults with no recorded recents must be empty and not contaminated by system-wide document controller
        #expect(freshManager.recentURLs.isEmpty)
    }

    @Test func disambiguatesDuplicateFilenamesWithParentFolder() {
        let defaults = createTestDefaults()
        let manager = RecentDocumentsManager(userDefaults: defaults)

        let url1 = URL(fileURLWithPath: "/tmp/project1/notes.md")
        let url2 = URL(fileURLWithPath: "/tmp/project2/notes.md")
        let url3 = URL(fileURLWithPath: "/tmp/unique.md")

        manager.recordRecent(url: url1)
        manager.recordRecent(url: url2)
        manager.recordRecent(url: url3)

        #expect(manager.displayName(for: url3) == "unique.md")
        #expect(manager.displayName(for: url1) == "notes.md — project1")
        #expect(manager.displayName(for: url2) == "notes.md — project2")
    }

    @Test func missingFileDoesNotCrashAndReturnsFalse() {
        let defaults = createTestDefaults()
        let manager = RecentDocumentsManager(userDefaults: defaults)

        let nonExistentURL = URL(fileURLWithPath: "/tmp/definitely_does_not_exist_\(UUID().uuidString).md")
        manager.recordRecent(url: nonExistentURL)

        var opened = false
        let success = manager.openRecent(url: nonExistentURL, openHandler: { _ in opened = true }, showMissingAlert: false)

        #expect(!success)
        #expect(!opened)

        // Can remove recent entry
        manager.removeRecent(url: nonExistentURL)
        #expect(!manager.recentURLs.contains(where: { $0.path == nonExistentURL.path }))
    }

    @Test func documentSessionTracksDirtyStateAccurately() {
        // Untitled session
        let untitled = DocumentSession()
        #expect(!untitled.isDirty)
        untitled.text = "Hello world"
        #expect(untitled.isDirty)

        // Saved session
        let saved = DocumentSession(
            fileURL: URL(fileURLWithPath: "/tmp/doc.md"),
            text: "Initial baseline",
            savedBaselineText: "Initial baseline"
        )
        #expect(!saved.isDirty)

        saved.text = "Changed text"
        #expect(saved.isDirty)

        saved.markSaved(text: "Changed text")
        #expect(!saved.isDirty)

        saved.updateFromDisk(text: "Disk reload")
        #expect(!saved.isDirty)
        #expect(saved.text == "Disk reload")
    }
}
