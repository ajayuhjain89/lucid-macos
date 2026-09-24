import SwiftUI
import AppKit

@main
struct LucidApp: App {
    @StateObject private var preferences = LucidPreferences.shared
    @StateObject private var updateController = LucidUpdateController.shared
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
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updateController.checkForUpdates()
                }
                .disabled(!updateController.canCheckForUpdates)
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
                .keyboardShortcut("+", modifiers: .command)

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

            CommandMenu("Theme") {
                ForEach(ThemeMode.curatedThemes) { mode in
                    Toggle(mode.displayName, isOn: Binding(
                        get: { preferences.theme == mode },
                        set: { if $0 { preferences.theme = mode } }
                    ))
                }
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
        guard let launchDate, Date().timeIntervalSince(launchDate) < 5 else { return }
        let documents = NSDocumentController.shared.documents
        guard documents.contains(where: { $0.fileURL != nil }) else { return }
        for document in documents where document.fileURL == nil && !document.isDocumentEdited {
            document.close()
        }
    }
}
