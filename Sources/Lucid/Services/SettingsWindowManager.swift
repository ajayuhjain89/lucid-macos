import SwiftUI
import AppKit

@MainActor
public final class SettingsWindowManager: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowManager()
    private var window: NSWindow?

    private override init() {
        super.init()
    }

    public func showSettings(preferences: LucidPreferences = .shared) {
        // Reuse the one Settings window, whether it is open, minimized or was closed
        // (it is kept, not released): building a new one each time lost its state
        // and, for a minimized window, left a duplicate in the Dock.
        if let existing = window {
            if existing.isMiniaturized { existing.deminiaturize(nil) }
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(preferences: preferences)
        let hostingController = NSHostingController(rootView: settingsView)

        let win = NSWindow(contentViewController: hostingController)
        win.title = "Lucid Settings"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.titlebarAppearsTransparent = false
        win.isReleasedWhenClosed = false
        win.center()
        win.delegate = self
        self.window = win

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        // Keep window instance for fast re-opening
    }
}
