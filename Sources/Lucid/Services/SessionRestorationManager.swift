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
    public var savedBaselineText: String?
    public var encodingRawValue: UInt?

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
        draftText: String? = nil,
        savedBaselineText: String? = nil,
        encodingRawValue: UInt? = nil
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
        self.savedBaselineText = savedBaselineText
        self.encodingRawValue = encodingRawValue
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
            self.draftText = session.isDirty ? session.text : nil
        } else {
            self.bookmarkData = nil
            self.fallbackPath = nil
            // Save untitled tab draft if not empty
            self.draftText = session.text.isEmpty ? nil : session.text
        }
        self.savedBaselineText = session.isDirty ? session.savedBaselineText : nil
        self.encodingRawValue = session.encoding.rawValue
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
    private var managerOrder: [UUID] = []
    private var managerObservers: [UUID: AnyCancellable] = [:]
    private var pendingSaveTask: Task<Void, Never>?
    private var remainingRestorationWindows: [WindowRestorationRecord]?
    private var restoredWindowCount = 0
    private var nativeWindowRestorationFinished = false
    private var isTerminating = false
    private var cancellables = Set<AnyCancellable>()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Native restoration may finish without creating a Lucid manager (for
        // example when its named document was deleted). Recovery must already
        // be known so the launch notification can request a fresh window.
        protectPendingRecovery()
        NotificationCenter.default.publisher(for: NSApplication.didFinishRestoringWindowsNotification)
            .sink { [weak self] _ in
                self?.nativeWindowRestorationFinished = true
                self?.requestAdditionalRestorationWindow()
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.saveCurrentSession()
            }
            .store(in: &cancellables)
    }

    // MARK: - Registration

    private func protectPendingRecovery() {
        if remainingRestorationWindows == nil {
            remainingRestorationWindows = loadSavedSession()?.windows
        }
    }

    public func register(manager: WindowDocumentManager) {
        protectPendingRecovery()
        if registeredManagers[manager.id] == nil { managerOrder.append(manager.id) }
        registeredManagers[manager.id] = WeakManagerRef(manager)
        managerObservers[manager.id] = manager.objectWillChange.sink { [weak self] _ in
            self?.scheduleRecoverySave()
        }
    }

    public func unregister(manager: WindowDocumentManager) {
        unregister(id: manager.id)
    }

    public func unregister(id: UUID) {
        registeredManagers.removeValue(forKey: id)
        managerOrder.removeAll { $0 == id }
        managerObservers.removeValue(forKey: id)
        guard !isTerminating else { return }
        saveCurrentSession()
    }

    public var activeManagers: [WindowDocumentManager] {
        liveManagers
    }

    private var liveManagers: [WindowDocumentManager] {
        managerOrder.compactMap { registeredManagers[$0]?.manager }
    }

    // MARK: - Saving

    /// Captures the current open windows and tabs and persists them to UserDefaults.
    public func saveCurrentSession() {
        guard !isTerminating else { return }
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        saveSession(managers: liveManagers)
        // Future saves must not mistake our own live snapshot for old recovery.
        if remainingRestorationWindows == nil { remainingRestorationWindows = [] }
    }

    private func scheduleRecoverySave() {
        guard !isTerminating else { return }
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled, let self else { return }
            self.saveCurrentSession()
        }
    }

    /// Preserve the approved session before native document windows tear down.
    public func prepareForTermination() {
        saveCurrentSession()
        isTerminating = true
    }

    public var hasPendingRestorationWindows: Bool {
        !(remainingRestorationWindows ?? []).isEmpty
    }

    /// Native restoration can create several windows before their SwiftUI
    /// content appears. Wait for those windows to hydrate before creating more.
    public func requestAdditionalRestorationWindow() {
        guard nativeWindowRestorationFinished else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.hasPendingRestorationWindows else { return }
            let nativeWindows = NSDocumentController.shared.documents.filter { $0.fileURL == nil }.count
            guard self.needsAdditionalRestorationWindow(nativeWindowCount: nativeWindows) else { return }
            NSDocumentController.shared.newDocument(nil)
        }
    }

    func needsAdditionalRestorationWindow(nativeWindowCount: Int) -> Bool {
        hasPendingRestorationWindows && nativeWindowCount <= restoredWindowCount
    }

    func isExtraRestorationWindow(_ manager: WindowDocumentManager) -> Bool {
        restoredWindowCount > 0 && !hasPendingRestorationWindows &&
            manager.sessions.allSatisfy { $0.isUntitled && $0.text.isEmpty }
    }

    /// Saves session state for the provided window managers.
    public func saveSession(managers: [WindowDocumentManager]) {
        guard LucidPreferences.shared.restoreSessionOnLaunch else {
            clearSession()
            return
        }

        protectPendingRecovery()
        var windowRecords: [WindowRestorationRecord] = []
        for manager in managers {
            let tabRecords = manager.sessions.compactMap { session -> TabRestorationRecord? in
                if let url = session.fileURL {
                    guard session.isDirty || FileManager.default.fileExists(atPath: url.path) else { return nil }
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

        // New windows can publish while launch restoration is still in progress.
        // Never overwrite records that have not yet been hydrated into a window.
        // A snapshot seeded in this process may also be represented by live
        // sessions. Keep only records that have not been adopted by a manager.
        let liveIDs = Set(windowRecords.flatMap { $0.tabs.map(\.id) })
        remainingRestorationWindows = remainingRestorationWindows.map { records in
            records.compactMap { record in
                var pending = record
                pending.tabs.removeAll { liveIDs.contains($0.id) }
                guard !pending.tabs.isEmpty else { return nil }
                if !pending.tabs.contains(where: { $0.id == pending.activeTabID }) {
                    pending.activeTabID = pending.tabs[0].id
                }
                return pending
            }
        }
        windowRecords.append(contentsOf: remainingRestorationWindows ?? [])

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
        protectPendingRecovery()
        // Never replace an explicitly opened file or a buffer already in use.
        guard documentManager.sessions.allSatisfy({ $0.isUntitled && $0.text.isEmpty }) else { return false }
        if remainingRestorationWindows == nil { remainingRestorationWindows = [] }
        while var remaining = remainingRestorationWindows, !remaining.isEmpty {
            let windowRecord = remaining.removeFirst()
            remainingRestorationWindows = remaining
            if restore(windowRecord, into: documentManager) {
                restoredWindowCount += 1
                return true
            }
        }
        return false
    }

    private func restore(_ windowRecord: WindowRestorationRecord, into documentManager: WindowDocumentManager) -> Bool {

        var restoredSessions: [DocumentSession] = []

        for tabRecord in windowRecord.tabs {
            let existingURL = tabRecord.resolveExistingURL()
            let disk = existingURL.flatMap { try? Data(contentsOf: $0) }.flatMap { LucidDocument.decodeText($0) }
            guard let text = tabRecord.draftText ?? disk?.text else { continue }
            let originalURL = tabRecord.fileURL ?? tabRecord.fallbackPath.map { URL(fileURLWithPath: $0) }
            let recoveredURL = existingURL ?? originalURL
            var baseline = tabRecord.draftText == nil ? (disk?.text ?? "") : (tabRecord.savedBaselineText ?? "")
            if disk?.text == text { baseline = text }
            let conflict = tabRecord.draftText != nil && disk != nil && disk?.text != baseline && disk?.text != text
            let encoding = tabRecord.draftText == nil ? (disk?.encoding ?? .utf8)
                : (tabRecord.encodingRawValue.map { String.Encoding(rawValue: $0) } ?? disk?.encoding ?? .utf8)
            let session = DocumentSession(
                id: tabRecord.id,
                fileURL: recoveredURL,
                title: tabRecord.title,
                text: text,
                savedBaselineText: baseline,
                encoding: encoding,
                cursorLine: tabRecord.cursorLine,
                cursorCol: tabRecord.cursorCol,
                selectedRange: NSRange(location: max(0, tabRecord.selectedRangeLocation), length: max(0, tabRecord.selectedRangeLength)),
                readingPosition: tabRecord.readingPosition,
                viewMode: tabRecord.viewMode,
                splitFraction: tabRecord.splitFraction,
                hasExternalConflict: conflict
            )
            session.lastExternalDiskText = conflict ? disk?.text : nil
            restoredSessions.append(session)
        }

        guard !restoredSessions.isEmpty else {
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
        remainingRestorationWindows = []
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
