import Foundation
import Testing
@testable import Lucid

@Suite("LucidDocument.decodeText")
struct DocumentDecodingTests {
    @Test func utf8() throws {
        let decoded = try #require(LucidDocument.decodeText(Data("# Héllo ’".utf8)))
        #expect(decoded.text == "# Héllo ’")
        #expect(decoded.encoding == .utf8)
    }

    @Test func utf8WithBOMKeepsTextIntact() throws {
        let decoded = try #require(LucidDocument.decodeText(Data([0xEF, 0xBB, 0xBF]) + Data("# Title".utf8)))
        #expect(decoded.encoding == .utf8)
        #expect(decoded.text.hasSuffix("# Title"))
    }

    @Test func emptyFile() throws {
        let decoded = try #require(LucidDocument.decodeText(Data()))
        #expect(decoded.text.isEmpty)
    }

    @Test(arguments: [String.Encoding.utf16LittleEndian, .utf16BigEndian])
    func utf16WithBOM(_ encoding: String.Encoding) throws {
        let bom: [UInt8] = encoding == .utf16LittleEndian ? [0xFF, 0xFE] : [0xFE, 0xFF]
        let data = Data(bom) + "# Überschrift\nText ✓".data(using: encoding)!
        let decoded = try #require(LucidDocument.decodeText(data))
        #expect(decoded.text == "# Überschrift\nText ✓")
        #expect(decoded.encoding == .utf16)
    }

    @Test func utf32LittleEndianWithBOM() throws {
        let data = Data([0xFF, 0xFE, 0x00, 0x00]) + "a ✓".data(using: .utf32LittleEndian)!
        let decoded = try #require(LucidDocument.decodeText(data))
        #expect(decoded.text == "a ✓")
        #expect(decoded.encoding == .utf32)
    }

    @Test func legacyWindows1252() throws {
        // "café – naïve" in Windows-1252: not valid UTF-8.
        let data = Data([0x63, 0x61, 0x66, 0xE9, 0x20, 0x96, 0x20, 0x6E, 0x61, 0xEF, 0x76, 0x65])
        let decoded = try #require(LucidDocument.decodeText(data))
        #expect(decoded.text == "café – naïve")
        #expect(decoded.encoding == .windowsCP1252)
    }

    @Test func binaryWithNULBytesIsRefused() {
        #expect(LucidDocument.decodeText(Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0xFF, 0x10])) == nil)
    }
}
