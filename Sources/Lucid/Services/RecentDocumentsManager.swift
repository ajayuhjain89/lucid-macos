import Foundation
import AppKit
import Combine

/// Manages recent documents with native macOS integration (`NSDocumentController`),
/// persistent storage, deduplication, path disambiguation, and graceful handling of missing files.
@MainActor
public final class RecentDocumentsManager: ObservableObject {
    public static let shared = RecentDocumentsManager()

    public static let maxRecents: Int = 20
    private static let userDefaultsKey = "lucid.recentDocuments.bookmarks"
    private static let legacyUserDefaultsKey = "lucid.recentDocuments.paths"

    @Published public private(set) var recentURLs: [URL] = []

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadRecents()
    }

    /// Records a document URL as recently opened.
    /// Deduplicates existing entries and promotes the URL to index 0.
    public func recordRecent(url: URL) {
        let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
        guard canonical.isFileURL else { return }

        // Forward to native AppKit recent documents system
        NSDocumentController.shared.noteNewRecentDocumentURL(canonical)

        // Update in-memory list
        var updated = recentURLs.filter {
            $0.standardizedFileURL.resolvingSymlinksInPath().path != canonical.path
        }
        updated.insert(canonical, at: 0)
        if updated.count > Self.maxRecents {
            updated = Array(updated.prefix(Self.maxRecents))
        }
        recentURLs = updated
        saveRecents()
    }

    /// Clears all recent documents in both Lucid and AppKit.
    public func clearRecents() {
        NSDocumentController.shared.clearRecentDocuments(nil)
        recentURLs = []
        userDefaults.removeObject(forKey: Self.userDefaultsKey)
        userDefaults.removeObject(forKey: Self.legacyUserDefaultsKey)
    }

    /// Removes a specific URL from the recent documents list.
    public func removeRecent(url: URL) {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        recentURLs.removeAll { $0.standardizedFileURL.resolvingSymlinksInPath().path == path }
        saveRecents()
    }

    /// Validates whether a file exists at the given recent URL.
    public func fileExists(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
    }

    /// Generates a disambiguated display name for a recent URL.
    /// If duplicate filenames exist in the recents list, appends the immediate parent folder name.
    public func displayName(for url: URL) -> String {
        let filename = url.lastPathComponent
        let duplicates = recentURLs.filter { $0.lastPathComponent == filename }
        if duplicates.count > 1 {
            let parentFolder = url.deletingLastPathComponent().lastPathComponent
            if !parentFolder.isEmpty && parentFolder != "/" {
                return "\(filename) — \(parentFolder)"
            }
        }
        return filename
    }

    /// Attempts to open a recent document. If the file is missing, presents a non-crashing alert
    /// offering to remove the stale entry.
    @discardableResult
    public func openRecent(
        url: URL,
        openHandler: (URL) -> Void,
        showMissingAlert: Bool = true
    ) -> Bool {
        let resolvedURL = resolveBookmarkOrPath(url: url)
        if fileExists(at: resolvedURL) {
            recordRecent(url: resolvedURL)
            openHandler(resolvedURL)
            return true
        }

        // File is missing or deleted
        if showMissingAlert {
            presentMissingFileAlert(for: resolvedURL)
        }
        return false
    }

    private func presentMissingFileAlert(for url: URL) {
        let alert = NSAlert()
        alert.messageText = "“\(url.lastPathComponent)” couldn’t be opened."
        alert.informativeText = "The file no longer exists at:\n\(url.path)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Remove from Recents")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            removeRecent(url: url)
        }
    }

    private func resolveBookmarkOrPath(url: URL) -> URL {
        return url.standardizedFileURL.resolvingSymlinksInPath()
    }

    private func loadRecents() {
        var urls: [URL] = []
        var seenPaths = Set<String>()

        // 1. Try resolving bookmarks from UserDefaults
        if let bookmarkDataArray = userDefaults.array(forKey: Self.userDefaultsKey) as? [Data] {
            for data in bookmarkDataArray {
                var isStale = false
                if let resolved = try? URL(
                    resolvingBookmarkData: data,
                    options: [.withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ) {
                    let canonical = resolved.standardizedFileURL.resolvingSymlinksInPath()
                    if !seenPaths.contains(canonical.path) {
                        seenPaths.insert(canonical.path)
                        urls.append(canonical)
                    }
                }
            }
        }

        // 2. Fallback to path strings if bookmarks were empty
        if urls.isEmpty, let pathArray = userDefaults.stringArray(forKey: Self.legacyUserDefaultsKey) {
            for path in pathArray {
                let url = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
                if !seenPaths.contains(url.path) {
                    seenPaths.insert(url.path)
                    urls.append(url)
                }
            }
        }

        if urls.count > Self.maxRecents {
            urls = Array(urls.prefix(Self.maxRecents))
        }
        self.recentURLs = urls
    }

    private func saveRecents() {
        var bookmarkDataArray: [Data] = []
        var pathArray: [String] = []

        for url in recentURLs {
            pathArray.append(url.path)
            if let bookmark = try? url.bookmarkData(
                options: .suitableForBookmarkFile,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                bookmarkDataArray.append(bookmark)
            }
        }

        userDefaults.set(bookmarkDataArray, forKey: Self.userDefaultsKey)
        userDefaults.set(pathArray, forKey: Self.legacyUserDefaultsKey)
    }
}
