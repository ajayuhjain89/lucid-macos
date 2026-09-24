import Foundation
import SwiftUI
import Sparkle
import Combine

/// Single-lifetime owner of Sparkle updater infrastructure.
///
/// Manages the `SPUStandardUpdaterController`, binds reactive update state,
/// and exposes native properties and actions for the menu bar and Settings UI.
@MainActor
public final class LucidUpdateController: ObservableObject {
    public static let shared = LucidUpdateController()

    private let updaterController: SPUStandardUpdaterController
    public var updater: SPUUpdater { updaterController.updater }

    @Published public private(set) var canCheckForUpdates: Bool = false
    @Published public private(set) var lastUpdateCheckDate: Date? = nil

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Observe canCheckForUpdates from SPUUpdater
        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: \.canCheckForUpdates, on: self)
            .store(in: &cancellables)

        // Observe lastUpdateCheckDate from SPUUpdater
        updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastUpdateCheckDate, on: self)
            .store(in: &cancellables)
    }

    /// Whether automatic background checks are enabled. Backed directly by Sparkle defaults.
    public var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            updater.automaticallyChecksForUpdates = newValue
        }
    }

    /// Whether updates are automatically downloaded in the background. Backed directly by Sparkle defaults.
    public var automaticallyDownloadsUpdates: Bool {
        get { updater.automaticallyDownloadsUpdates }
        set {
            objectWillChange.send()
            updater.automaticallyDownloadsUpdates = newValue
        }
    }

    /// User-facing short version string from Info.plist (e.g. "1.0.4").
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Machine-readable build number from Info.plist (e.g. "5").
    public var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Detects whether Lucid is running from a mounted read-only disk image or external volume.
    public var isMountedFromDiskImage: Bool {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.path.hasPrefix("/Volumes/") {
            return true
        }
        if let isReadOnly = (try? bundleURL.resourceValues(forKeys: [.volumeIsReadOnlyKey]))?.volumeIsReadOnly {
            return isReadOnly
        }
        return false
    }

    /// Triggers a user-initiated update check via Sparkle's standard user interface.
    public func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
