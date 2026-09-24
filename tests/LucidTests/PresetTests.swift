import Foundation
import Testing
@testable import Lucid

// LucidPreferences stores through @AppStorage (UserDefaults.standard of the test
// runner, not Lucid's own domain). Serialized, and cleaned up afterwards.
extension UserDefaultsTests {
    @Suite("LucidPreferences.applyPreset")
    struct PresetTests {
        private func clearLucidKeys() {
            for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("lucid.") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        /// The preview preference payload as a dictionary (its key order varies).
        private func payload(_ prefs: LucidPreferences) -> NSDictionary {
            let data = Data(prefs.jsonPayload(systemColorScheme: .dark).utf8)
            return (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary ?? [:]
        }

        @Test func presetsDoNotInheritFromThePreviousPreset() {
            clearLucidKeys()
            defer { clearLucidKeys() }
            let prefs = LucidPreferences()

            prefs.applyPreset(.minimalWriter)
            #expect(prefs.focusMode)
            #expect(!prefs.showStatusBar)

            prefs.applyPreset(.compact)
            #expect(prefs.density == .compact)

            prefs.applyPreset(.lucidDefault)
            #expect(!prefs.focusMode)
            #expect(prefs.showStatusBar == LucidPreferences.Defaults.showStatusBar)
            #expect(prefs.density == LucidPreferences.Defaults.density)
            #expect(prefs.viewMode == .reader)
        }

        @Test(arguments: LucidPreset.allCases)
        func applyingAPresetTwiceIsStable(_ preset: LucidPreset) {
            clearLucidKeys()
            defer { clearLucidKeys() }
            let prefs = LucidPreferences()
            prefs.applyPreset(.minimalWriter)
            prefs.applyPreset(preset)
            let first = payload(prefs)
            prefs.applyPreset(.developer)
            prefs.applyPreset(preset)
            #expect(payload(prefs) == first)
            #expect(prefs.focusMode == (preset == .minimalWriter))
        }
    }
}
