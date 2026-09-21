import SwiftUI

@main
struct LucidApp: App {
    @StateObject private var preferences = LucidPreferences.shared
    @StateObject private var updateController = LucidUpdateController.shared

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
            }

            CommandMenu("View") {
                Button("Reader Mode") {
                    preferences.viewMode = .reader
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Split Mode") {
                    preferences.viewMode = .split
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Editor Mode") {
                    preferences.viewMode = .editor
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button(preferences.focusMode ? "Disable Focus Mode" : "Enable Focus Mode") {
                    preferences.focusMode.toggle()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button(preferences.typewriterMode ? "Disable Typewriter Mode" : "Enable Typewriter Mode") {
                    preferences.typewriterMode.toggle()
                }

                Divider()

                Button(preferences.showOutline ? "Hide Sidebar" : "Show Sidebar") {
                    preferences.showOutline.toggle()
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
            }

            CommandMenu("Theme") {
                ForEach(ThemeMode.curatedThemes) { mode in
                    Button(mode.displayName) {
                        preferences.theme = mode
                    }
                }
            }
        }
    }
}
