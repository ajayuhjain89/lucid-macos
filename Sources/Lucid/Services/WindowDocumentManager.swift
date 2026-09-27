import Foundation
import Combine
import AppKit

/// Coordinates tabs and document sessions for a single window.
///
/// Ensures each window maintains its own independent collection of document sessions,
/// isolated active session state, external file change tracking, and tab lifecycle operations.
@MainActor
public final class WindowDocumentManager: ObservableObject {
    public let id: UUID

    @Published public private(set) var sessions: [DocumentSession] = []
    @Published public var activeSessionID: UUID

    private var fileWatchers: [UUID: FileWatcher] = [:]
    private var cancellables = Set<AnyCancellable>()

    public var activeSession: DocumentSession {
        if let current = sessions.first(where: { $0.id == activeSessionID }) {
            return current
        }
        if let first = sessions.first {
            activeSessionID = first.id
            return first
        }
        // Fallback: create an initial untitled session
        let initial = DocumentSession()
        observeSession(initial)
        sessions = [initial]
        activeSessionID = initial.id
        return initial
    }

    public init(id: UUID = UUID(), initialSession: DocumentSession? = nil) {
        self.id = id
        let first = initialSession ?? DocumentSession()
        self.sessions = [first]
        self.activeSessionID = first.id
        observeSession(first)
        if let url = first.fileURL {
            setupWatcher(for: first)
            RecentDocumentsManager.shared.recordRecent(url: url)
        }
        SessionRestorationManager.shared.register(manager: self)
    }

    private func observeSession(_ session: DocumentSession) {
        session.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    /// Replaces the current sessions with a new collection (used during session restoration).
    public func replaceSessions(_ newSessions: [DocumentSession]) {
        guard !newSessions.isEmpty else { return }
        for (_, watcher) in fileWatchers {
            watcher.stopWatching()
        }
        fileWatchers.removeAll()
        cancellables.removeAll()

        for session in newSessions {
            observeSession(session)
            if let url = session.fileURL {
                setupWatcher(for: session)
                RecentDocumentsManager.shared.recordRecent(url: url)
            }
        }
        self.sessions = newSessions
        if !newSessions.contains(where: { $0.id == activeSessionID }) {
            self.activeSessionID = newSessions[0].id
        }
    }

    deinit {
        for (_, watcher) in fileWatchers {
            watcher.stopWatching()
        }
    }

    // MARK: - Tab Creation & Opening

    /// Creates a new untitled document session in the current window.
    @discardableResult
    public func newTab(title: String? = nil, text: String = "", viewMode: ViewMode = .reader) -> DocumentSession {
        let untitledCount = sessions.filter { $0.isUntitled }.count
        let defaultTitle = untitledCount == 0 ? "Untitled" : "Untitled \(untitledCount + 1)"
        let session = DocumentSession(
            title: title ?? defaultTitle,
            text: text,
            savedBaselineText: "",
            viewMode: viewMode
        )
        observeSession(session)
        sessions.append(session)
        activeSessionID = session.id
        return session
    }

    /// Opens a file at the given URL into this window.
    /// If the file is already open, activates the existing tab instead of creating a duplicate.
    @discardableResult
    public func openFile(url: URL, activate: Bool = true) -> DocumentSession? {
        let canonical = url.standardizedFileURL.resolvingSymlinksInPath()

        // Check if already open in this window
        if let existing = sessions.first(where: {
            $0.fileURL?.standardizedFileURL.resolvingSymlinksInPath().path == canonical.path
        }) {
            if activate {
                activeSessionID = existing.id
            }
            return existing
        }

        // Read and decode file contents
        guard let data = try? Data(contentsOf: canonical),
              let decoded = LucidDocument.decodeText(data) else {
            return nil
        }

        let session = DocumentSession(
            fileURL: canonical,
            title: canonical.lastPathComponent,
            text: decoded.text,
            savedBaselineText: decoded.text,
            encoding: decoded.encoding
        )
        observeSession(session)

        // If the current window only has a single pristine untitled session, replace it
        if sessions.count == 1,
           let only = sessions.first,
           only.isUntitled,
           only.text.isEmpty,
           !only.isDirty {
            stopWatcher(for: only.id)
            sessions = [session]
        } else {
            sessions.append(session)
        }

        if activate {
            activeSessionID = session.id
        }

        setupWatcher(for: session)
        RecentDocumentsManager.shared.recordRecent(url: canonical)
        return session
    }

    // MARK: - Tab Navigation

    /// Activates the tab immediately following the active tab.
    public func selectNextTab() {
        guard sessions.count > 1,
              let currentIndex = sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }
        let nextIndex = (currentIndex + 1) % sessions.count
        activeSessionID = sessions[nextIndex].id
    }

    /// Activates the tab immediately preceding the active tab.
    public func selectPreviousTab() {
        guard sessions.count > 1,
              let currentIndex = sessions.firstIndex(where: { $0.id == activeSessionID }) else { return }
        let prevIndex = (currentIndex - 1 + sessions.count) % sessions.count
        activeSessionID = sessions[prevIndex].id
    }

    /// Switches directly to the specified session ID.
    public func selectTab(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionID = id
    }

    // MARK: - Tab Closing & Save Confirmation

    /// Closes a tab, prompting to save if dirty.
    public func closeTab(
        id: UUID,
        window: NSWindow? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            completion(false)
            return
        }
        let session = sessions[index]

        if session.isDirty {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to “\(session.displayName)”?"
            alert.informativeText = "Your changes will be lost if you close without saving."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don’t Save")
            alert.addButton(withTitle: "Cancel")

            let response: NSApplication.ModalResponse
            if let window = window {
                alert.beginSheetModal(for: window) { resp in
                    self.handleClosePromptResponse(resp, session: session, index: index, window: window, completion: completion)
                }
                return
            } else {
                response = alert.runModal()
                handleClosePromptResponse(response, session: session, index: index, window: nil, completion: completion)
            }
        } else {
            removeSession(at: index)
            completion(true)
        }
    }

    private func handleClosePromptResponse(
        _ response: NSApplication.ModalResponse,
        session: DocumentSession,
        index: Int,
        window: NSWindow?,
        completion: @escaping (Bool) -> Void
    ) {
        switch response {
        case .alertFirstButtonReturn: // Save
            saveSession(session, window: window) { success in
                if success {
                    if let currentIndex = self.sessions.firstIndex(where: { $0.id == session.id }) {
                        self.removeSession(at: currentIndex)
                    }
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .alertSecondButtonReturn: // Don't Save
            removeSession(at: index)
            completion(true)
        default: // Cancel
            completion(false)
        }
    }

    private func removeSession(at index: Int) {
        let removed = sessions.remove(at: index)
        stopWatcher(for: removed.id)

        if activeSessionID == removed.id {
            if sessions.isEmpty {
                // Window will either close or receive a new tab
            } else if index < sessions.count {
                activeSessionID = sessions[index].id
            } else {
                activeSessionID = sessions[sessions.count - 1].id
            }
        }
    }

    /// Closes all tabs in the window, prompting for any dirty sessions sequentially.
    public func closeAllTabs(
        window: NSWindow? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let firstDirty = sessions.first(where: { $0.isDirty }) else {
            for session in sessions {
                stopWatcher(for: session.id)
            }
            sessions.removeAll()
            completion(true)
            return
        }

        closeTab(id: firstDirty.id, window: window) { success in
            if success {
                self.closeAllTabs(window: window, completion: completion)
            } else {
                completion(false)
            }
        }
    }

    // MARK: - Saving

    /// Saves a session. If untitled or saveAs is true, displays an NSSavePanel.
    public func saveSession(
        _ session: DocumentSession,
        saveAs: Bool = false,
        window: NSWindow? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        if let fileURL = session.fileURL, !saveAs {
            do {
                let data = session.text.data(using: session.encoding) ?? Data(session.text.utf8)
                try data.write(to: fileURL, options: .atomic)
                session.markSaved(at: fileURL, text: session.text)
                RecentDocumentsManager.shared.recordRecent(url: fileURL)
                completion(true)
            } catch {
                presentSaveError(error, for: fileURL)
                completion(false)
            }
        } else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.markdownDocument, .plainText]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.nameFieldStringValue = session.isUntitled ? "Untitled.md" : session.displayName

            let handler: (NSApplication.ModalResponse) -> Void = { response in
                guard response == .OK, let targetURL = panel.url else {
                    completion(false)
                    return
                }
                do {
                    let data = session.text.data(using: session.encoding) ?? Data(session.text.utf8)
                    try data.write(to: targetURL, options: .atomic)
                    session.markSaved(at: targetURL, text: session.text)
                    self.setupWatcher(for: session)
                    RecentDocumentsManager.shared.recordRecent(url: targetURL)
                    completion(true)
                } catch {
                    self.presentSaveError(error, for: targetURL)
                    completion(false)
                }
            }

            if let window = window {
                panel.beginSheetModal(for: window, completionHandler: handler)
            } else {
                handler(panel.runModal())
            }
        }
    }

    private func presentSaveError(_ error: Error, for url: URL) {
        let alert = NSAlert()
        alert.messageText = "The document “\(url.lastPathComponent)” could not be saved."
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
    }

    // MARK: - External File Observation

    private func setupWatcher(for session: DocumentSession) {
        guard let url = session.fileURL else { return }
        stopWatcher(for: session.id)

        let sessionId = session.id
        let watcher = FileWatcher(url: url) { [weak self, weak session] in
            guard let self = self, let session = session, self.sessions.contains(where: { $0.id == sessionId }) else { return }
            self.handleExternalFileChange(for: session, at: url)
        }
        fileWatchers[sessionId] = watcher
    }

    private func stopWatcher(for sessionId: UUID) {
        fileWatchers[sessionId]?.stopWatching()
        fileWatchers.removeValue(forKey: sessionId)
    }

    private func handleExternalFileChange(for session: DocumentSession, at url: URL) {
        guard let data = try? Data(contentsOf: url),
              let updatedText = LucidDocument.decodeText(data)?.text else { return }

        if updatedText == session.text {
            // Already matches current session text (e.g. Lucid's own save)
            session.savedBaselineText = updatedText
            session.hasExternalConflict = false
            session.lastExternalDiskText = nil
            return
        }

        if !session.isDirty {
            // Tab is clean -> safe to update directly from disk
            session.updateFromDisk(text: updatedText)
        } else {
            // Tab has local unsaved edits and disk also diverged -> record conflict!
            session.hasExternalConflict = true
            session.lastExternalDiskText = updatedText
            if session.id == activeSessionID {
                presentConflictAlert(for: session, diskText: updatedText)
            }
        }
    }

    public func resolveExternalConflictIfPresent(for session: DocumentSession) {
        guard session.hasExternalConflict, let diskText = session.lastExternalDiskText else { return }
        presentConflictAlert(for: session, diskText: diskText)
    }

    private func presentConflictAlert(for session: DocumentSession, diskText: String) {
        let alert = NSAlert()
        alert.messageText = "“\(session.displayName)” changed on disk"
        alert.informativeText = "This file was modified by another application, but you have unsaved changes here. Reload the version on disk (discarding your changes) or keep your version?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep My Changes")
        alert.addButton(withTitle: "Reload from Disk")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            session.updateFromDisk(text: diskText)
        } else {
            session.hasExternalConflict = false
            session.lastExternalDiskText = nil
        }
    }
}
