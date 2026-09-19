import SwiftUI

@main
struct LucidApp: App {
    @StateObject private var preferences = LucidPreferences.shared

    var body: some Scene {
        DocumentGroup(newDocument: LucidDocument()) { file in
            MainWindowView(document: file.$document, fileURL: file.fileURL)
                .frame(minWidth: 750, minHeight: 550)
        }
        .commands {
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

                Button(preferences.showOutline ? "Hide Table of Contents" : "Show Table of Contents") {
                    preferences.showOutline.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command, .option])

                Button(preferences.showInspector ? "Hide Inspector" : "Show Inspector") {
                    preferences.showInspector.toggle()
                }
                .keyboardShortcut("i", modifiers: .command)

                Divider()

                Button("Increase Font Size") {
                    preferences.fontSize = min(28, preferences.fontSize + 1)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    preferences.fontSize = max(11, preferences.fontSize - 1)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Font Size") {
                    preferences.fontSize = 16.0
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandMenu("Theme") {
                ForEach(ThemeMode.allCases) { mode in
                    Button(mode.displayName) {
                        preferences.theme = mode
                    }
                }
            }
        }
    }
}
