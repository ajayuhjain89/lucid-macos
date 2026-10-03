import Foundation
import Darwin

/// An open vnode follows same-volume moves even before watcher callbacks run.
/// A deleted/replaced vnode must never authorize a write to its former pathname.
final class DocumentFileIdentity {
    private let descriptor: Int32

    init?(url: URL) {
        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
    }

    deinit { close(descriptor) }

    var currentURL: URL? {
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard fcntl(descriptor, F_GETPATH, &path) == 0 else { return nil }
        var opened = stat(), current = stat()
        guard fstat(descriptor, &opened) == 0, opened.st_nlink > 0,
              lstat(path, &current) == 0,
              opened.st_dev == current.st_dev, opened.st_ino == current.st_ino else { return nil }
        return URL(fileURLWithPath: String(cString: path)).standardizedFileURL
    }
}
