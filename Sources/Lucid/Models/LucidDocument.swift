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

    public init(text: String = "") {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}
