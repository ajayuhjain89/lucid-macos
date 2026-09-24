import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static var markdownDocument: UTType {
        UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
    }
}

public struct LucidDocument: FileDocument {
    public static var readableContentTypes: [UTType] {
        [
            .markdownDocument,
            .plainText,
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            UTType(filenameExtension: "mdown") ?? .plainText
        ]
    }

    public static var writableContentTypes: [UTType] {
        [
            .markdownDocument,
            .plainText,
            UTType(filenameExtension: "md") ?? .plainText
        ]
    }

    public var text: String
    /// The encoding the file was read in; saves write it back the same way.
    public var encoding: String.Encoding = .utf8

    public init(text: String = "") {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let decoded = Self.decodeText(data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = decoded.text
        self.encoding = decoded.encoding
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Keep the file's own encoding; fall back to UTF-8 when the text now
        // holds characters that encoding can't represent.
        let data = text.data(using: encoding) ?? Data(text.utf8)
        return .init(regularFileWithContents: data)
    }

    /// Decodes a text file: UTF-8 first, then UTF-16/32 when a byte-order mark
    /// says so, then Windows-1252 for legacy 8-bit files. Data containing NUL
    /// bytes without a BOM is treated as binary and refused.
    public static func decodeText(_ data: Data) -> (text: String, encoding: String.Encoding)? {
        if let text = String(data: data, encoding: .utf8) {
            return (text, .utf8)
        }
        let boms: [([UInt8], String.Encoding)] = [
            ([0xFF, 0xFE, 0x00, 0x00], .utf32LittleEndian), ([0x00, 0x00, 0xFE, 0xFF], .utf32BigEndian),
            ([0xFF, 0xFE], .utf16LittleEndian), ([0xFE, 0xFF], .utf16BigEndian)
        ]
        for (bom, encoding) in boms where data.starts(with: bom) {
            if let text = String(data: data.dropFirst(bom.count), encoding: encoding) {
                return (text, encoding == .utf16LittleEndian || encoding == .utf16BigEndian ? .utf16 : .utf32)
            }
        }
        if data.contains(0) { return nil }
        if let text = String(data: data, encoding: .windowsCP1252) {
            return (text, .windowsCP1252)
        }
        return nil
    }
}
