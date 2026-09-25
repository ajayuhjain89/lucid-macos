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

    /// User-facing short version string from Info.plist (e.g. "1.0.5").
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Machine-readable build number from Info.plist (e.g. "6").
    public var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Whether Lucid runs from somewhere it can't replace itself: a read-only
    /// volume (a mounted disk image) or macOS App Translocation (a downloaded app
    /// opened in place). An app on a writable external drive can update, so
    /// `/Volumes/` alone doesn't count.
    public var isMountedFromDiskImage: Bool {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.path.contains("/AppTranslocation/") {
            return true
        }
        if let isReadOnly = (try? bundleURL.resourceValues(forKeys: [.volumeIsReadOnlyKey]))?.volumeIsReadOnly {
            return isReadOnly
        }
        return false
    }

    /// Whether "Check for Updates…" can do anything: Sparkle is ready and Lucid
    /// can replace itself where it is.
    public var isUpdateCheckAvailable: Bool {
        canCheckForUpdates && !isMountedFromDiskImage
    }

    /// Triggers a user-initiated update check via Sparkle's standard user interface.
    public func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
