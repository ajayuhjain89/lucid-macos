import Foundation
import Testing
@testable import Lucid

// Uses UserDefaults.standard of the test runner (via LucidPreferences' @AppStorage).
extension UserDefaultsTests {
    @Suite("WindowViewState")
    struct WindowViewStateTests {
        private func clearLucidKeys() {
            for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("lucid.") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        @Test func windowsChangeIndependentlyAndRememberTheLastChoice() {
            clearLucidKeys()
            defer { clearLucidKeys() }
            let prefs = LucidPreferences()
            prefs.viewMode = .reader
            let a = WindowViewState(preferences: prefs)
            let b = WindowViewState(preferences: prefs)

            b.viewMode = .editor
            b.showOutline = true
            b.focusMode = true
            #expect(a.viewMode == .reader)
            #expect(!a.showOutline && !a.focusMode)
            // The last choice becomes the default for the next window.
            #expect(prefs.viewMode == .editor)
            #expect(WindowViewState(preferences: prefs).viewMode == .editor)
        }

        @Test func applyingAPresetUpdatesEveryWindow() async throws {
            clearLucidKeys()
            defer { clearLucidKeys() }
            let prefs = LucidPreferences()
            let a = WindowViewState(preferences: prefs)
            let b = WindowViewState(preferences: prefs)
            a.viewMode = .split

            prefs.applyPreset(.minimalWriter)
            // The observer is delivered on the main queue.
            for _ in 0..<50 where b.viewMode != .editor {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            #expect(a.viewMode == .editor && b.viewMode == .editor)
            #expect(a.focusMode && b.focusMode)
        }
    }
}
