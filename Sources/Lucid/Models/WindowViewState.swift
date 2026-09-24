import Foundation
import Combine

/// View state that belongs to one document window: its view mode, sidebar and
/// Focus Mode. Changing it in one window no longer changes every other window.
///
/// New windows start from the app-wide values in `LucidPreferences`, and each
/// change is written back there, so the next window opens the way the user last
/// worked. Applying a preset resets every open window to the preset's values.
public final class WindowViewState: ObservableObject {
    @Published public var viewMode: ViewMode {
        didSet { if viewMode != oldValue { preferences.viewMode = viewMode } }
    }
    @Published public var showOutline: Bool {
        didSet { if showOutline != oldValue { preferences.showOutline = showOutline } }
    }
    @Published public var focusMode: Bool {
        didSet { if focusMode != oldValue { preferences.focusMode = focusMode } }
    }

    private let preferences: LucidPreferences
    private var presetObserver: NSObjectProtocol?

    public init(preferences: LucidPreferences = .shared) {
        self.preferences = preferences
        self.viewMode = preferences.viewMode
        self.showOutline = preferences.showOutline
        self.focusMode = preferences.focusMode
        presetObserver = NotificationCenter.default.addObserver(
            forName: LucidPreferences.presetAppliedNotification, object: preferences, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.viewMode = self.preferences.viewMode
            self.showOutline = self.preferences.showOutline
            self.focusMode = self.preferences.focusMode
        }
    }

    deinit {
        if let presetObserver { NotificationCenter.default.removeObserver(presetObserver) }
    }
}
