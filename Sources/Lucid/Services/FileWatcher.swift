import Foundation

/// Main-queue vnode observation. The directory watch reconnects the file watch
/// after an atomic replacement or a deletion followed by later recreation.
public final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var directorySource: DispatchSourceFileSystemObject?
    private var isStopped = false
    private var generation = 0
    private let url: URL
    private let onChange: () -> Void

    public init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        directorySource = Self.watch(url.deletingLastPathComponent(), events: [.write, .rename, .delete]) { [weak self] _ in
            guard let self, !self.isStopped, self.source == nil else { return }
            self.startWatchingFile()
            if self.source != nil { self.onChange() }
        }
        startWatchingFile()
    }

    deinit { stopWatching() }

    private static func watch(_ url: URL, events: DispatchSource.FileSystemEvent,
                              handler: @escaping (DispatchSource.FileSystemEvent) -> Void) -> DispatchSourceFileSystemObject? {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor,
                                                              eventMask: events, queue: .main)
        source.setEventHandler { [weak source] in
            if let source { handler(source.data) }
        }
        // Close this source's descriptor even after the watcher is gone. Never
        // close a mutable property that may already hold the replacement's fd.
        source.setCancelHandler { close(descriptor) }
        source.resume()
        return source
    }

    private func startWatchingFile() {
        guard !isStopped, source == nil else { return }
        generation += 1
        let token = generation
        source = Self.watch(url, events: [.write, .rename, .delete, .extend]) { [weak self] flags in
            guard let self, !self.isStopped, self.generation == token else { return }
            if flags.contains(.delete) || flags.contains(.rename) {
                self.source?.cancel()
                self.source = nil
                self.startWatchingFile()
            }
            self.onChange()
        }
    }

    public func stopWatching() {
        isStopped = true
        generation += 1
        source?.cancel()
        source = nil
        directorySource?.cancel()
        directorySource = nil
    }
}
