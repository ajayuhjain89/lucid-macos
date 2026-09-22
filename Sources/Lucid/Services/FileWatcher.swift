import Foundation

public final class FileWatcher {
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let url: URL
    private let onChange: () -> Void

    public init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        startWatching()
    }

    deinit {
        stopWatching()
    }

    private func startWatching() {
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: DispatchQueue.main
        )

        dispatchSource.setEventHandler { [weak self, weak dispatchSource] in
            guard let self = self else { return }
            let flags = dispatchSource?.data ?? []
            self.onChange()
            // Atomic saves (write-temp-then-rename, as vim/VS Code do) replace the
            // watched inode, leaving this vnode source dead. Re-establish the watch
            // on the same path so live reload keeps working after the first such save.
            if flags.contains(.delete) || flags.contains(.rename) {
                self.rearm()
            }
        }

        dispatchSource.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        self.source = dispatchSource
        dispatchSource.resume()
    }

    public func stopWatching() {
        source?.cancel()
        source = nil
    }

    /// Tears down the dead vnode source and re-attaches to the current file at
    /// the same path once it reappears (the rename gap is typically sub-millisecond).
    private func rearm() {
        stopWatching()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.source == nil else { return }
            if FileManager.default.fileExists(atPath: self.url.path) {
                self.startWatching()
                // A change almost certainly landed during the re-arm gap.
                self.onChange()
            }
        }
    }
}
