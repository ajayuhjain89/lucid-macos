import SwiftUI
import AppKit

@main
struct LucidApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences = LucidPreferences.shared
    @StateObject private var updateController = LucidUpdateController.shared
    @ObservedObject private var recentDocs = RecentDocumentsManager.shared
    /// The key document window's view state; view commands act on that window only.
    @FocusedObject private var windowState: WindowViewState?

    init() {
        LaunchUntitledCleanup.markLaunch()
    }

    var body: some Scene {
        DocumentGroup(newDocument: LucidDocument()) { file in
            MainWindowView(document: file.$document, fileURL: file.fileURL)
                .frame(minWidth: 780, minHeight: 560)
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidNewTab"), object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Open…") {
                    let hasKeyDocument = NSApp.windows.contains(where: { $0.isKeyWindow })
                    if hasKeyDocument {
                        NotificationCenter.default.post(name: NSNotification.Name("LucidOpenFile"), object: nil)
                    } else {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.markdownDocument, .plainText]
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            for url in panel.urls {
                                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                            }
                        }
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Menu("Open Recent") {
                    if recentDocs.recentURLs.isEmpty {
                        Button("No Recent Documents") {}
                            .disabled(true)
                    } else {
                        ForEach(recentDocs.recentURLs, id: \.self) { url in
                            Button(recentDocs.displayName(for: url)) {
                                recentDocs.openRecent(url: url) { targetURL in
                                    NSDocumentController.shared.openDocument(withContentsOf: targetURL, display: true) { _, _, _ in }
                                }
                            }
                            .help(url.path)
                        }
                        Divider()
                        Button("Clear Menu") {
                            recentDocs.clearRecents()
                        }
                    }
                }
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidSaveDocument"), object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As…") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidSaveDocumentAs"), object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Close Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidCloseTab"), object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Close Window") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidCloseWindow"), object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }

            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updateController.checkForUpdates()
                }
                .disabled(!updateController.isUpdateCheckAvailable)
                Divider()
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsWindowManager.shared.showSettings(preferences: preferences)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Find in Document…") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidToggleFind"), object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Next") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidFindNext"), object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidFindPrevious"), object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidToggleCommandPalette"), object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }

            // Added to the system View menu (a CommandMenu("View") made a second one).
            // Toggles show the current mode with a checkmark.
            CommandGroup(before: .toolbar) {
                Toggle("Reader Mode", isOn: viewModeBinding(.reader))
                    .keyboardShortcut("1", modifiers: .command)

                Toggle("Split Mode", isOn: viewModeBinding(.split))
                    .keyboardShortcut("2", modifiers: .command)

                Toggle("Editor Mode", isOn: viewModeBinding(.editor))
                    .keyboardShortcut("3", modifiers: .command)

                Divider()

                Toggle("Focus Mode", isOn: focusModeBinding)
                    .keyboardShortcut("d", modifiers: [.command, .shift])

                Toggle("Typewriter Mode", isOn: $preferences.typewriterMode)

                Divider()

                Button((windowState?.showOutline ?? preferences.showOutline) ? "Hide Sidebar" : "Show Sidebar") {
                    if let windowState {
                        windowState.showOutline.toggle()
                    } else {
                        preferences.showOutline.toggle()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .control])

                Button(preferences.showStatusBar ? "Hide Status Bar" : "Show Status Bar") {
                    preferences.showStatusBar.toggle()
                }

                Divider()

                Menu("Presets") {
                    ForEach(LucidPreset.allCases) { preset in
                        Button(preset.displayName) {
                            preferences.applyPreset(preset)
                        }
                    }
                }

                Divider()

                Button("Increase Font Size") {
                    preferences.fontSize = min(LucidPreferences.Limits.fontSizeRange.upperBound, preferences.fontSize + LucidPreferences.Limits.fontSizeStep)
                }
                .keyboardShortcut("=", modifiers: .command)

                Button("Decrease Font Size") {
                    preferences.fontSize = max(LucidPreferences.Limits.fontSizeRange.lowerBound, preferences.fontSize - LucidPreferences.Limits.fontSizeStep)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Font Size") {
                    preferences.fontSize = LucidPreferences.Defaults.fontSize
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()
            }

            // The default Help item only said help isn't available.
            CommandGroup(replacing: .help) {
                Button("Lucid on GitHub") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/ajayuhjain89/lucid-macos")!)
                }
                Button("Report an Issue…") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/ajayuhjain89/lucid-macos/issues/new")!)
                }
                Button("Release Notes") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/ajayuhjain89/lucid-macos/releases")!)
                }
            }

            CommandMenu("Theme") {
                ForEach(ThemeMode.curatedThemes) { mode in
                    Toggle(mode.displayName, isOn: Binding(
                        get: { preferences.theme == mode },
                        set: { if $0 { preferences.theme = mode } }
                    ))
                }
            }

            CommandGroup(after: .windowArrangement) {
                Divider()
                Button("Show Next Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidNextTab"), object: nil)
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Show Previous Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("LucidPreviousTab"), object: nil)
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            }
        }
    }

    /// A menu checkmark binding for one view mode: on when it is the current
    /// mode; choosing it selects that mode (choosing the current one keeps it).
    private func viewModeBinding(_ mode: ViewMode) -> Binding<Bool> {
        Binding(
            get: { (windowState?.viewMode ?? preferences.viewMode) == mode },
            set: {
                guard $0 else { return }
                if let windowState { windowState.viewMode = mode } else { preferences.viewMode = mode }
            }
        )
    }

    private var focusModeBinding: Binding<Bool> {
        Binding(
            get: { windowState?.focusMode ?? preferences.focusMode },
            set: { value in
                if let windowState { windowState.focusMode = value } else { preferences.focusMode = value }
            }
        )
    }
}

/// Opening a file at launch (Finder, `open -a`) makes DocumentGroup create an
/// empty Untitled window as well, on top of the file. Shortly after launch,
/// close such an Untitled document once a real file is open, as long as the
/// user hasn't touched it.
enum LaunchUntitledCleanup {
    private static var launchDate: Date?

    static func markLaunch() {
        launchDate = Date()
    }

    @MainActor
    static func closeUntouchedUntitledIfOpeningFile() {
        let documents = NSDocumentController.shared.documents
        guard documents.contains(where: { $0.fileURL != nil }) else { return }

        let managers = SessionRestorationManager.shared.activeManagers
        for manager in managers {
            if manager.sessions.count == 1,
               let session = manager.sessions.first,
               session.isUntitled,
               session.text.isEmpty,
               !session.isDirty {
                if let win = manager.hostWindow,
                   let doc = (win.windowController?.document as? NSDocument) ?? NSDocumentController.shared.document(for: win) {
                    doc.updateChangeCount(.changeCleared)
                    doc.close()
                }
            }
        }

        for document in documents where document.fileURL == nil {
            if document.windowControllers.isEmpty || !document.isDocumentEdited {
                document.updateChangeCount(.changeCleared)
                document.close()
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let managers = SessionRestorationManager.shared.activeManagers
        let dirtyManagers = managers.filter { $0.sessions.contains(where: { $0.isDirty }) }

        guard !dirtyManagers.isEmpty else {
            for doc in NSDocumentController.shared.documents {
                doc.updateChangeCount(.changeCleared)
            }
            return .terminateNow
        }

        closeDirtyManagersSequentially(dirtyManagers, sender: sender)
        return .terminateLater
    }

    @MainActor
    private func closeDirtyManagersSequentially(_ remaining: [WindowDocumentManager], sender: NSApplication) {
        guard let first = remaining.first else {
            for doc in NSDocumentController.shared.documents {
                doc.updateChangeCount(.changeCleared)
            }
            sender.reply(toApplicationShouldTerminate: true)
            return
        }

        first.closeAllTabs(window: first.hostWindow) { [weak self] success in
            if success {
                self?.closeDirtyManagersSequentially(Array(remaining.dropFirst()), sender: sender)
            } else {
                sender.reply(toApplicationShouldTerminate: false)
            }
        }
    }

    @MainActor
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSDocumentController.shared.newDocument(nil)
            return true
        }
        return true
    }
}
