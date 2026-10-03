import Foundation
import Combine

/// A lightweight, independent document session representing a single tab or buffer.
///
/// Inactive document sessions retain only lightweight metadata (text, URL, dirty flag,
/// cursor and reading position), consuming negligible CPU and memory, while the active
/// session drives the window's single editor and preview rendering pipeline.
public final class DocumentSession: Identifiable, ObservableObject {
    public let id: UUID
    /// The shared editor uses this tab's history while its buffer is displayed.
    public let undoManager = UndoManager()

    @Published public var fileURL: URL?
    @Published public var title: String
    @Published public var text: String
    @Published public var savedBaselineText: String
    @Published public var encoding: String.Encoding
    @Published public var cursorLine: Int
    @Published public var cursorCol: Int
    @Published public var selectedRange: NSRange
    @Published public var readingPosition: ReadingPosition
    @Published public var viewMode: ViewMode
    @Published public var splitFraction: CGFloat
    @Published public var hasExternalConflict: Bool
    public var lastExternalDiskText: String?

    public var isUntitled: Bool {
        fileURL == nil
    }

    public var isDirty: Bool {
        if isUntitled {
            return !text.isEmpty
        } else {
            return text != savedBaselineText
        }
    }

    public var displayName: String {
        if let fileURL = fileURL {
            return fileURL.lastPathComponent
        }
        return title
    }

    public init(
        id: UUID = UUID(),
        fileURL: URL? = nil,
        title: String? = nil,
        text: String = "",
        savedBaselineText: String = "",
        encoding: String.Encoding = .utf8,
        cursorLine: Int = 1,
        cursorCol: Int = 1,
        selectedRange: NSRange = NSRange(location: 0, length: 0),
        readingPosition: ReadingPosition = .documentTop,
        viewMode: ViewMode = .reader,
        splitFraction: CGFloat = 0.5,
        hasExternalConflict: Bool = false
    ) {
        self.id = id
        self.fileURL = fileURL
        self.title = title ?? (fileURL?.lastPathComponent ?? "Untitled")
        self.text = text
        self.savedBaselineText = savedBaselineText
        self.encoding = encoding
        self.cursorLine = cursorLine
        self.cursorCol = cursorCol
        self.selectedRange = selectedRange
        self.readingPosition = readingPosition
        self.viewMode = viewMode
        self.splitFraction = splitFraction
        self.hasExternalConflict = hasExternalConflict
    }

    /// Updates session state when a file is successfully saved to disk.
    public func markSaved(at url: URL? = nil, text: String? = nil) {
        if let url = url {
            self.fileURL = url
            self.title = url.lastPathComponent
        }
        if let text = text {
            self.text = text
            self.savedBaselineText = text
        } else {
            self.savedBaselineText = self.text
        }
        self.hasExternalConflict = false
        self.lastExternalDiskText = nil
    }

    /// Updates session text from external disk reload without marking dirty.
    public func updateFromDisk(text: String) {
        undoManager.removeAllActions()
        self.text = text
        self.savedBaselineText = text
        self.hasExternalConflict = false
        self.lastExternalDiskText = nil
    }
}
