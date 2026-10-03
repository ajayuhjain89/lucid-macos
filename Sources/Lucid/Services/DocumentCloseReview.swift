import AppKit

enum DocumentCloseDecision {
    case save, discard, cancel
}

/// Reviews every dirty buffer before committing any tab/window removal.
/// Saves may finish during review; discard decisions remain reversible until
/// the entire operation succeeds, including across multiple windows.
@MainActor
final class DocumentCloseReview {
    typealias Prompt = @MainActor (DocumentSession, NSWindow?, @escaping (DocumentCloseDecision) -> Void) -> Void
    typealias Saver = @MainActor (WindowDocumentManager, DocumentSession, NSWindow?, @escaping (Bool) -> Void) -> Void

    struct Approval {
        let discarded: [DocumentSession]

        func discardChangesForTermination() {
            for session in discarded {
                if let url = session.fileURL,
                   let data = try? Data(contentsOf: url), let disk = LucidDocument.decodeText(data) {
                    session.encoding = disk.encoding
                    session.updateFromDisk(text: disk.text)
                } else {
                    session.updateFromDisk(text: "")
                }
            }
        }
    }

    static func review(
        managers: [WindowDocumentManager],
        sessions: [DocumentSession]? = nil,
        window: NSWindow? = nil,
        prompt: @escaping Prompt = presentPrompt,
        save: Saver? = nil,
        completion: @escaping (Approval?) -> Void
    ) {
        guard !managers.contains(where: { $0.isReviewingClose }) else { completion(nil); return }
        managers.forEach { $0.isReviewingClose = true }
        var approvedDiscards: [UUID: String] = [:]

        func finish(_ approval: Approval?) {
            managers.forEach { $0.isReviewingClose = false }
            completion(approval)
        }

        func advance() {
            let buffers = managers.flatMap { manager in
                manager.sessions.filter { session in sessions?.contains(where: { $0 === session }) ?? true }
                    .map { (manager, $0) }
            }
            guard let (manager, session) = buffers.first(where: {
                $0.1.isDirty && approvedDiscards[$0.1.id] != $0.1.text
            }) else {
                finish(Approval(discarded: buffers.map { $0.1 }.filter { approvedDiscards[$0.id] != nil }))
                return
            }
            prompt(session, window ?? manager.hostWindow) { decision in
                switch decision {
                case .cancel:
                    finish(nil)
                case .discard:
                    approvedDiscards[session.id] = session.text
                    advance()
                case .save:
                    let saved: (Bool) -> Void = { success in
                        if success { advance() } else { finish(nil) }
                    }
                    if let save { save(manager, session, window ?? manager.hostWindow, saved) }
                    else { manager.saveSession(session, window: window ?? manager.hostWindow, completion: saved) }
                }
            }
        }
        advance()
    }

    private static func presentPrompt(_ session: DocumentSession, _ window: NSWindow?, _ completion: @escaping (DocumentCloseDecision) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to “\(session.displayName)”?"
        alert.informativeText = "Your changes will be lost if you close without saving."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don’t Save")
        alert.addButton(withTitle: "Cancel")
        let respond: (NSApplication.ModalResponse) -> Void = { response in
            switch response {
            case .alertFirstButtonReturn: completion(.save)
            case .alertSecondButtonReturn: completion(.discard)
            default: completion(.cancel)
            }
        }
        if let window { alert.beginSheetModal(for: window, completionHandler: respond) }
        else { respond(alert.runModal()) }
    }
}
