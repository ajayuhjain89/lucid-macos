import Foundation
import AppKit

public enum ImageAssetError: LocalizedError, Equatable {
    case documentNotSaved
    case unsupportedImageType(String)
    case unreadableImageData
    case fileWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .documentNotSaved:
            return "Please save your document before adding images so Lucid can store them in an 'assets' folder alongside your file."
        case .unsupportedImageType(let ext):
            return "Unsupported image type “.\(ext)”. Lucid supports PNG, JPEG, GIF, WebP, SVG, TIFF, and BMP."
        case .unreadableImageData:
            return "Could not read valid image data."
        case .fileWriteFailed(let reason):
            return "Failed to save image asset: \(reason)"
        }
    }
}

/// Manages saving and referencing image assets in a document's local `assets/` directory.
///
/// Images pasted or dropped into Lucid are saved to `<document-dir>/assets/` with collision-resistant
/// naming and referenced via portable relative paths (`![Image](assets/filename.png)`).
public final class ImageAssetManager {
    public static let shared = ImageAssetManager()

    public static let supportedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "svg", "tiff", "bmp"
    ]

    public init() {}

    /// Checks if a given file URL points to a supported image file.
    public func isImageFile(url: URL) -> Bool {
        Self.supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Converts raw image data (converting TIFF to PNG if needed) and saves it into `<document-dir>/assets/`.
    ///
    /// - Parameters:
    ///   - data: The raw image data (PNG or TIFF).
    ///   - preferredBaseName: An optional preferred base filename (defaults to "image").
    ///   - documentURL: The file URL of the document being edited.
    /// - Returns: A tuple of `(relativePath, absoluteURL)` where relativePath is e.g. `"assets/image-1718000.png"`.
    @discardableResult
    public func savePastedImageData(
        _ data: Data,
        preferredBaseName: String = "image",
        documentURL: URL?
    ) throws -> (relativePath: String, absoluteURL: URL) {
        guard let docURL = documentURL else {
            throw ImageAssetError.documentNotSaved
        }

        // Determine if data is already PNG or needs conversion
        let pngData: Data
        if let rep = NSBitmapImageRep(data: data),
           let converted = rep.representation(using: .png, properties: [:]) {
            pngData = converted
        } else {
            pngData = data
        }

        let assetsDirectory = docURL.deletingLastPathComponent().appendingPathComponent("assets", isDirectory: true)
        try ensureDirectoryExists(assetsDirectory)

        let timestamp = Int(Date().timeIntervalSince1970)
        let sanitizedBase = sanitize(preferredBaseName)
        let uniqueFilename = findNonCollidingFilename(
            directory: assetsDirectory,
            baseName: "\(sanitizedBase)-\(timestamp)",
            extension: "png"
        )

        let targetURL = assetsDirectory.appendingPathComponent(uniqueFilename)
        do {
            try pngData.write(to: targetURL, options: .atomic)
        } catch {
            throw ImageAssetError.fileWriteFailed(error.localizedDescription)
        }

        let relativePath = "assets/\(uniqueFilename)"
        return (relativePath: relativePath, absoluteURL: targetURL)
    }

    /// Copies a dropped image file into `<document-dir>/assets/`.
    ///
    /// - Parameters:
    ///   - sourceURL: The source file URL of the dropped image.
    ///   - documentURL: The file URL of the document being edited.
    /// - Returns: A tuple of `(relativePath, absoluteURL)`.
    @discardableResult
    public func saveDroppedImage(
        from sourceURL: URL,
        documentURL: URL?
    ) throws -> (relativePath: String, absoluteURL: URL) {
        guard let docURL = documentURL else {
            throw ImageAssetError.documentNotSaved
        }

        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedExtensions.contains(ext) else {
            throw ImageAssetError.unsupportedImageType(ext)
        }

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ImageAssetError.unreadableImageData
        }

        let assetsDirectory = docURL.deletingLastPathComponent().appendingPathComponent("assets", isDirectory: true)
        try ensureDirectoryExists(assetsDirectory)

        let originalBase = sourceURL.deletingPathExtension().lastPathComponent
        let sanitizedBase = sanitize(originalBase.isEmpty ? "image" : originalBase)
        let uniqueFilename = findNonCollidingFilename(
            directory: assetsDirectory,
            baseName: sanitizedBase,
            extension: ext
        )

        let targetURL = assetsDirectory.appendingPathComponent(uniqueFilename)

        // Avoid copying a file onto itself if already in the target assets folder
        if sourceURL.standardizedFileURL.resolvingSymlinksInPath() == targetURL.standardizedFileURL.resolvingSymlinksInPath() {
            return (relativePath: "assets/\(uniqueFilename)", absoluteURL: targetURL)
        }

        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        } catch {
            throw ImageAssetError.fileWriteFailed(error.localizedDescription)
        }

        let relativePath = "assets/\(uniqueFilename)"
        return (relativePath: relativePath, absoluteURL: targetURL)
    }

    /// Generates standard Markdown image syntax `![altText](relativePath)`.
    public func markdownImageReference(altText: String = "Image", relativePath: String) -> String {
        "![\(altText)](\(relativePath))"
    }

    // MARK: - Internal Helpers

    private func ensureDirectoryExists(_ directory: URL) throws {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir) || !isDir.boolValue {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw ImageAssetError.fileWriteFailed("Could not create assets directory: \(error.localizedDescription)")
            }
        }
    }

    public func findNonCollidingFilename(directory: URL, baseName: String, `extension` ext: String) -> String {
        let initial = "\(baseName).\(ext)"
        if !FileManager.default.fileExists(atPath: directory.appendingPathComponent(initial).path) {
            return initial
        }

        var counter = 1
        while true {
            let candidate = "\(baseName)-\(counter).\(ext)"
            if !FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
                return candidate
            }
            counter += 1
        }
    }

    public func sanitize(_ string: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = string.unicodeScalars.filter { allowed.contains($0) }
        let result = String(filtered).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return result.isEmpty ? "image" : result
    }
}
