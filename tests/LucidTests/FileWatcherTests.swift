import Foundation
import Testing
@testable import Lucid

@Suite("FileWatcher lifecycle", .serialized)
@MainActor struct FileWatcherTests {
    @Test func observesRepeatedAtomicReplacementAndDelayedRecreation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("document.md")
        try Data("initial".utf8).write(to: file)
        var observed = Set<String>()
        let watcher = FileWatcher(url: file) {
            if let value = try? String(contentsOf: file, encoding: .utf8) { observed.insert(value) }
        }
        defer { watcher.stopWatching() }
        for value in ["one", "two", "three"] {
            try Data(value.utf8).write(to: file, options: .atomic)
            for _ in 0..<100 where !observed.contains(value) {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            #expect(observed.contains(value))
        }
        try FileManager.default.removeItem(at: file)
        try await Task.sleep(nanoseconds: 250_000_000)
        try Data("recreated".utf8).write(to: file)
        for _ in 0..<100 where !observed.contains("recreated") {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(observed.contains("recreated"))
        watcher.stopWatching()
        try Data("stopped".utf8).write(to: file, options: .atomic)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(!observed.contains("stopped"))
    }

    @Test func stoppingDuringReplacementCannotRearm() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("initial".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        var calls = 0
        var watcher: FileWatcher?
        watcher = FileWatcher(url: file) {
            calls += 1
            watcher?.stopWatching()
        }
        try Data("one".utf8).write(to: file, options: .atomic)
        try await Task.sleep(nanoseconds: 250_000_000)
        try Data("two".utf8).write(to: file, options: .atomic)
        try await Task.sleep(nanoseconds: 250_000_000)
        #expect(calls == 1)
        watcher = nil
    }
}
