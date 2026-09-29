import Foundation
import AppKit
import Combine

/// A Codable snapshot of an individual tab session for cross-launch restoration.
public struct TabRestorationRecord: Codable, Equatable {
    public var id: UUID
    public var fileURL: URL?
    public var bookmarkData: Data?
    public var fallbackPath: String?
    public var title: String
    public var cursorLine: Int
    public var cursorCol: Int
    public var selectedRangeLocation: Int
    public var selectedRangeLength: Int
    public var readingPosition: ReadingPosition
    public var viewMode: ViewMode
    public var splitFraction: CGFloat
    public var draftText: String?

    public init(
        id: UUID = UUID(),
        fileURL: URL? = nil,
        bookmarkData: Data? = nil,
        fallbackPath: String? = nil,
        title: String = "Untitled",
        cursorLine: Int = 1,
        cursorCol: Int = 1,
        selectedRangeLocation: Int = 0,
        selectedRangeLength: Int = 0,
        readingPosition: ReadingPosition = .documentTop,
        viewMode: ViewMode = .reader,
        splitFraction: CGFloat = 0.5,
        draftText: String? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fallbackPath = fallbackPath
        self.title = title
        self.cursorLine = cursorLine
        self.cursorCol = cursorCol
        self.selectedRangeLocation = selectedRangeLocation
        self.selectedRangeLength = selectedRangeLength
        self.readingPosition = readingPosition
        self.viewMode = viewMode
        self.splitFraction = splitFraction
        self.draftText = draftText
    }

    public init(from session: DocumentSession) {
        self.id = session.id
        self.fileURL = session.fileURL
        if let url = session.fileURL {
            self.bookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            self.fallbackPath = url.standardizedFileURL.resolvingSymlinksInPath().path
            self.draftText = nil
        } else {
            self.bookmarkData = nil
            self.fallbackPath = nil
            // Save untitled tab draft if not empty
            self.draftText = session.text.isEmpty ? nil : session.text
        }
        self.title = session.displayName
        self.cursorLine = session.cursorLine
        self.cursorCol = session.cursorCol
        self.selectedRangeLocation = session.selectedRange.location
        self.selectedRangeLength = session.selectedRange.length
        self.readingPosition = session.readingPosition
        self.viewMode = session.viewMode
        self.splitFraction = session.splitFraction
    }

    /// Resolves the actual URL if the file exists on disk.
    /// Returns nil if the file was deleted or cannot be resolved, preventing modal error storms.
    public func resolveExistingURL() -> URL? {
        if let data = bookmarkData {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), FileManager.default.fileExists(atPath: resolved.path) {
                return resolved.standardizedFileURL.resolvingSymlinksInPath()
            }
        }
        if let path = fallbackPath, FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        }
        if let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            return url.standardizedFileURL.resolvingSymlinksInPath()
        }
        return nil
    }
}

/// A Codable snapshot of a window's tab set and active tab state.
public struct WindowRestorationRecord: Codable, Equatable {
    public var id: UUID
    public var activeTabID: UUID
    public var tabs: [TabRestorationRecord]

    public init(id: UUID = UUID(), activeTabID: UUID, tabs: [TabRestorationRecord]) {
        self.id = id
        self.activeTabID = activeTabID
        self.tabs = tabs
    }
}

/// The versioned root container for restored app sessions across launches.
public struct AppSessionSnapshot: Codable, Equatable {
    public var version: Int
    public var timestamp: Date
    public var windows: [WindowRestorationRecord]

    public init(version: Int = 1, timestamp: Date = Date(), windows: [WindowRestorationRecord] = []) {
        self.version = version
        self.timestamp = timestamp
        self.windows = windows
    }
}

/// Manages cross-launch session restoration for Lucid windows and tabs.
///
/// Implements lazy hydration: inactive tabs are restored as lightweight data objects without
/// spinning up WebViews or background renderers. Missing or deleted files are skipped gracefully
/// without showing modal error alerts.
@MainActor
public final class SessionRestorationManager: ObservableObject {
    public static let shared = SessionRestorationManager()

    public static let sessionDefaultsKey = "lucid.sessionRestoration.v1"
    private let userDefaults: UserDefaults

    /// Active window managers tracked for autosave upon termination
    private var registeredManagers: [UUID: WeakManagerRef] = [:]
    private var cancellables = Set<AnyCancellable>()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.saveCurrentSession()
            }
            .store(in: &cancellables)
    }

    // MARK: - Registration

    public func register(manager: WindowDocumentManager) {
        registeredManagers[manager.id] = WeakManagerRef(manager)
    }

    public func unregister(manager: WindowDocumentManager) {
        unregister(id: manager.id)
    }

    public func unregister(id: UUID) {
        registeredManagers.removeValue(forKey: id)
        if registeredManagers.isEmpty {
            clearSession()
        } else {
            saveCurrentSession()
        }
    }

    public var activeManagers: [WindowDocumentManager] {
        liveManagers
    }

    private var liveManagers: [WindowDocumentManager] {
        registeredManagers.values.compactMap { $0.manager }
    }

    // MARK: - Saving

    /// Captures the current open windows and tabs and persists them to UserDefaults.
    public func saveCurrentSession() {
        saveSession(managers: liveManagers)
    }

    /// Saves session state for the provided window managers.
    public func saveSession(managers: [WindowDocumentManager]) {
        guard LucidPreferences.shared.restoreSessionOnLaunch else {
            clearSession()
            return
        }

        var windowRecords: [WindowRestorationRecord] = []
        for manager in managers {
            let tabRecords = manager.sessions.compactMap { session -> TabRestorationRecord? in
                if let url = session.fileURL {
                    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                    return TabRestorationRecord(from: session)
                } else if !session.text.isEmpty {
                    // Retain untitled tab if it contains content
                    return TabRestorationRecord(from: session)
                }
                return nil
            }

            guard !tabRecords.isEmpty else { continue }
            let activeID = tabRecords.contains(where: { $0.id == manager.activeSessionID })
                ? manager.activeSessionID
                : tabRecords[0].id

            windowRecords.append(WindowRestorationRecord(
                id: manager.id,
                activeTabID: activeID,
                tabs: tabRecords
            ))
        }

        guard !windowRecords.isEmpty else {
            clearSession()
            return
        }

        let snapshot = AppSessionSnapshot(version: 1, timestamp: Date(), windows: windowRecords)
        if let data = try? JSONEncoder().encode(snapshot) {
            userDefaults.set(data, forKey: Self.sessionDefaultsKey)
        }
    }

    // MARK: - Loading & Restoration

    /// Loads the stored session snapshot from UserDefaults if available and valid.
    public func loadSavedSession() -> AppSessionSnapshot? {
        guard LucidPreferences.shared.restoreSessionOnLaunch else { return nil }
        guard let data = userDefaults.data(forKey: Self.sessionDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(AppSessionSnapshot.self, from: data)
    }

    /// Restores saved session tabs into the given window document manager.
    ///
    /// Preserves the lazy hydration invariant: inactive tabs are loaded into memory as data
    /// objects only; only the active tab drives the window's preview and editor.
    ///
    /// - Returns: `true` if one or more tabs were successfully restored; `false` otherwise.
    @discardableResult
    public func restoreInto(documentManager: WindowDocumentManager) -> Bool {
        guard LucidPreferences.shared.restoreSessionOnLaunch else { return false }
        if NSDocumentController.shared.documents.contains(where: { $0.fileURL != nil }) {
            return false
        }
        guard let snapshot = loadSavedSession(), let windowRecord = snapshot.windows.first else {
            return false
        }

        var restoredSessions: [DocumentSession] = []

        for tabRecord in windowRecord.tabs {
            if let existingURL = tabRecord.resolveExistingURL() {
                guard let data = try? Data(contentsOf: existingURL),
                      let decoded = LucidDocument.decodeText(data) else {
                    continue
                }

                let session = DocumentSession(
                    id: tabRecord.id,
                    fileURL: existingURL,
                    title: existingURL.lastPathComponent,
                    text: decoded.text,
                    savedBaselineText: decoded.text,
                    encoding: decoded.encoding,
                    cursorLine: tabRecord.cursorLine,
                    cursorCol: tabRecord.cursorCol,
                    selectedRange: NSRange(
                        location: tabRecord.selectedRangeLocation,
                        length: tabRecord.selectedRangeLength
                    ),
                    readingPosition: tabRecord.readingPosition,
                    viewMode: tabRecord.viewMode,
                    splitFraction: tabRecord.splitFraction
                )
                restoredSessions.append(session)
            } else if let draft = tabRecord.draftText {
                // Restore untitled tab with draft text
                let session = DocumentSession(
                    id: tabRecord.id,
                    title: tabRecord.title,
                    text: draft,
                    savedBaselineText: "",
                    cursorLine: tabRecord.cursorLine,
                    cursorCol: tabRecord.cursorCol,
                    selectedRange: NSRange(
                        location: tabRecord.selectedRangeLocation,
                        length: tabRecord.selectedRangeLength
                    ),
                    readingPosition: tabRecord.readingPosition,
                    viewMode: tabRecord.viewMode,
                    splitFraction: tabRecord.splitFraction
                )
                restoredSessions.append(session)
            }
        }

        guard !restoredSessions.isEmpty else {
            clearSession()
            return false
        }

        // Apply restored sessions to documentManager
        documentManager.replaceSessions(restoredSessions)

        // Select the active tab or fallback to the first
        if restoredSessions.contains(where: { $0.id == windowRecord.activeTabID }) {
            documentManager.activeSessionID = windowRecord.activeTabID
        } else {
            documentManager.activeSessionID = restoredSessions[0].id
        }

        return true
    }

    /// Clears any persisted session state.
    public func clearSession() {
        userDefaults.removeObject(forKey: Self.sessionDefaultsKey)
    }
}

/// A weak reference wrapper for WindowDocumentManager in the manager registry.
private final class WeakManagerRef {
    weak var manager: WindowDocumentManager?

    init(_ manager: WindowDocumentManager) {
        self.manager = manager
    }
}
