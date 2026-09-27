import Testing
import Foundation
@testable import Lucid

@Suite("ImageAssetManager")
struct ImageAssetTests {

    private func createTempDocumentURL() -> (docURL: URL, cleanup: () -> Void) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("lucid-img-test-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let docURL = tempDir.appendingPathComponent("document.md")
        try? "# Document".write(to: docURL, atomically: true, encoding: .utf8)

        let cleanup: () -> Void = {
            _ = try? FileManager.default.removeItem(at: tempDir)
        }
        return (docURL, cleanup)
    }

    @Test
    func savePastedImageCreatesAssetsFolderAndReturnsRelativePath() throws {
        let (docURL, cleanup) = createTempDocumentURL()
        defer { cleanup() }

        let samplePNGData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00])

        let manager = ImageAssetManager()
        let result = try manager.savePastedImageData(samplePNGData, preferredBaseName: "screenshot", documentURL: docURL)

        #expect(result.relativePath.hasPrefix("assets/screenshot-"))
        #expect(result.relativePath.hasSuffix(".png"))

        let expectedAssetsDir = docURL.deletingLastPathComponent().appendingPathComponent("assets", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: expectedAssetsDir.path))
        #expect(FileManager.default.fileExists(atPath: result.absoluteURL.path))

        let readData = try Data(contentsOf: result.absoluteURL)
        #expect(readData == samplePNGData)

        let markdown = manager.markdownImageReference(altText: "Diagram", relativePath: result.relativePath)
        #expect(markdown == "![Diagram](\(result.relativePath))")
    }

    @Test
    func collisionResistantFilenameGeneration() {
        let manager = ImageAssetManager()
        let tempDir = FileManager.default.temporaryDirectory

        let file1 = tempDir.appendingPathComponent("test-collision.png")
        try? "first".write(to: file1, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file1) }

        let resolved = manager.findNonCollidingFilename(
            directory: tempDir,
            baseName: "test-collision",
            extension: "png"
        )

        #expect(resolved == "test-collision-1.png")
    }

    @Test
    func rejectsUntitledDocumentWithoutURL() {
        let manager = ImageAssetManager()
        let dummyData = Data([0x01, 0x02, 0x03])

        #expect(throws: ImageAssetError.documentNotSaved) {
            try manager.savePastedImageData(dummyData, documentURL: nil)
        }

        let dummyURL = URL(fileURLWithPath: "/tmp/sample.png")
        #expect(throws: ImageAssetError.documentNotSaved) {
            try manager.saveDroppedImage(from: dummyURL, documentURL: nil)
        }
    }

    @Test
    func saveDroppedImageCopiesFileAndPreservesExtension() throws {
        let (docURL, cleanup) = createTempDocumentURL()
        defer { cleanup() }

        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("source-photo-\(UUID().uuidString).jpg")
        let sourceContent = "JPEG_DATA_MOCK".data(using: .utf8)!
        try sourceContent.write(to: sourceURL)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let manager = ImageAssetManager()
        let result = try manager.saveDroppedImage(from: sourceURL, documentURL: docURL)

        #expect(result.relativePath.hasPrefix("assets/source-photo"))
        #expect(result.relativePath.hasSuffix(".jpg"))
        #expect(FileManager.default.fileExists(atPath: result.absoluteURL.path))

        let copiedData = try Data(contentsOf: result.absoluteURL)
        #expect(copiedData == sourceContent)
    }

    @Test
    func unsupportedImageTypeThrowsError() {
        let (docURL, cleanup) = createTempDocumentURL()
        defer { cleanup() }

        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("script.sh")
        try? "echo hello".write(to: sourceURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let manager = ImageAssetManager()
        #expect(throws: ImageAssetError.unsupportedImageType("sh")) {
            try manager.saveDroppedImage(from: sourceURL, documentURL: docURL)
        }
    }

    @Test
    func sanitizesSpecialCharactersInBaseName() {
        let manager = ImageAssetManager()
        let sanitized = manager.sanitize("my screenshot (v2) / test*final!")
        #expect(sanitized == "myscreenshotv2testfinal")

        let emptyResult = manager.sanitize("???///")
        #expect(emptyResult == "image")
    }
}
