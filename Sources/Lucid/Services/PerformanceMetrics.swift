import Foundation
import os

/// Performance instrumentation for Lucid operations using OSSignposter.
/// Active only during debugging and profiling.
public final class PerformanceMetrics {
    public static let shared = PerformanceMetrics()

    private let logger = Logger(subsystem: "com.ayushjain.lucid", category: "Performance")
    private let signposter: OSSignposter

    private init() {
        self.signposter = OSSignposter(logger: logger)
    }

    /// Measure an interval with signpost tracking.
    @discardableResult
    public func measure<T>(name: StaticString, block: () throws -> T) rethrows -> T {
        #if DEBUG
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return try block()
        #else
        return try block()
        #endif
    }
}
