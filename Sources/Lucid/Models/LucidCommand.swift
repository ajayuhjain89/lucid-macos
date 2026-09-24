import SwiftUI
import AppKit

/// Canonical identifiers for all user-accessible actions in Lucid.
public enum LucidCommandID: String, CaseIterable, Identifiable, Codable {
    // Navigation & View Modes
    case toggleSidebar = "view.toggleSidebar"
    case viewModeReader = "view.modeReader"
    case viewModeSplit = "view.modeSplit"
    case viewModeEditor = "view.modeEditor"
    case toggleFocusMode = "view.toggleFocusMode"
    case toggleTypewriterMode = "view.toggleTypewriterMode"
    case toggleStatusBar = "view.toggleStatusBar"

    // Typography & Zoom
    case increaseFontSize = "text.increaseFontSize"
    case decreaseFontSize = "text.decreaseFontSize"
    case resetFontSize = "text.resetFontSize"

    // Editing & Formatting
    case findInDocument = "edit.find"
    case findNext = "edit.findNext"
    case findPrevious = "edit.findPrevious"

    // Insert Templates
    case insertTable = "insert.table"
    case insertMath = "insert.math"
    case insertChemistry = "insert.chemistry"
    case insertMermaid = "insert.mermaid"

    // Document & Export
    case exportPDF = "file.exportPDF"
    case exportHTML = "file.exportHTML"
    case copyRichText = "file.copyRichText"

    // Application & Navigation
    case openCommandPalette = "app.commandPalette"
    case openSettings = "app.settings"

    public var id: String { rawValue }
}

/// Metadata definition for a canonical command.
public struct LucidCommandMetadata: Identifiable {
    public let id: LucidCommandID
    public let title: String
    public let subtitle: String
    public let icon: String
    public let defaultKeyEquivalent: KeyEquivalent?
    public let defaultModifiers: EventModifiers
    public let category: CommandCategory

    public enum CommandCategory: String, CaseIterable {
        case view = "View"
        case edit = "Edit"
        case insert = "Insert"
        case file = "File & Export"
        case application = "Application"
    }

    public var shortcutDisplayString: String? {
        guard let key = defaultKeyEquivalent else { return nil }
        var str = ""
        if defaultModifiers.contains(.control) { str += "⌃" }
        if defaultModifiers.contains(.option) { str += "⌥" }
        if defaultModifiers.contains(.shift) { str += "⇧" }
        if defaultModifiers.contains(.command) { str += "⌘" }

        switch key {
        case .upArrow: str += "↑"
        case .downArrow: str += "↓"
        case .leftArrow: str += "←"
        case .rightArrow: str += "→"
        case .escape: str += "⎋"
        case .delete: str += "⌫"
        case .return: str += "↩"
        default: str += String(key.character).uppercased()
        }
        return str
    }
}

/// Central registry of all canonical Lucid commands.
public final class LucidCommandRegistry {
    public static let shared = LucidCommandRegistry()

    public let commands: [LucidCommandID: LucidCommandMetadata]

    private init() {
        var map: [LucidCommandID: LucidCommandMetadata] = [:]

        func reg(
            _ id: LucidCommandID,
            _ title: String,
            _ subtitle: String,
            _ icon: String,
            _ key: KeyEquivalent? = nil,
            _ mods: EventModifiers = .command,
            _ category: LucidCommandMetadata.CommandCategory
        ) {
            map[id] = LucidCommandMetadata(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                defaultKeyEquivalent: key,
                defaultModifiers: mods,
                category: category
            )
        }

        // View commands (Standard macOS conventions: ⌘1/⌘2/⌘3 for view modes, ⌃⌘S for sidebar)
        reg(.toggleSidebar, "Toggle Sidebar", "Show or hide the outline navigation sidebar", "sidebar.leading", "s", [.command, .control], .view)
        reg(.viewModeReader, "Reader Mode", "Distraction-free rendered reading view", "book", "1", .command, .view)
        reg(.viewModeSplit, "Split Mode", "Side-by-side Markdown source and rendered preview", "rectangle.split.2x1", "2", .command, .view)
        reg(.viewModeEditor, "Editor Mode", "Full-width Markdown source editor", "pencil", "3", .command, .view)
        reg(.toggleFocusMode, "Toggle Focus Mode", "Dim inactive paragraphs to concentrate on the active block", "scope", "d", [.command, .shift], .view)
        reg(.toggleTypewriterMode, "Toggle Typewriter Mode", "Keep the active typing line vertically centered", "text.aligncenter", nil, [], .view)
        reg(.toggleStatusBar, "Toggle Status Bar", "Show or hide the bottom document metrics bar", "menubar.dock.rectangle", nil, [], .view)

        // Typography & Font size
        reg(.increaseFontSize, "Increase Font Size", "Make editor and preview text larger", "plus.magnifyingglass", "+", .command, .view)
        reg(.decreaseFontSize, "Decrease Font Size", "Make editor and preview text smaller", "minus.magnifyingglass", "-", .command, .view)
        reg(.resetFontSize, "Reset Font Size", "Restore default font size (18 pt)", "arrow.counterclockwise", "0", .command, .view)

        // Editing & Find
        reg(.findInDocument, "Find in Document…", "Search text within the current document", "magnifyingglass", "f", .command, .edit)
        reg(.findNext, "Find Next", "Jump to the next search match", "chevron.down", "g", .command, .edit)
        reg(.findPrevious, "Find Previous", "Jump to the previous search match", "chevron.up", "g", [.command, .shift], .edit)

        // Insert templates
        reg(.insertTable, "Insert Table", "Insert a formatted 3-column Markdown table", "tablecells", nil, [], .insert)
        reg(.insertMath, "Insert Math Block", "Insert a KaTeX display formula block", "function", nil, [], .insert)
        reg(.insertChemistry, "Insert Chemistry Formula", "Insert an mhchem chemical equation", "atom", nil, [], .insert)
        reg(.insertMermaid, "Insert Mermaid Diagram", "Insert an architecture/flowchart diagram", "chart.bar.doc.horizontal", nil, [], .insert)

        // File & Export (Standard macOS: ⌘P is Print; Export has no colliding shortcut)
        reg(.exportPDF, "Export as PDF…", "Export document as paginated vector PDF", "arrow.down.doc", nil, [], .file)
        reg(.exportHTML, "Export as Standalone HTML…", "Export self-contained HTML file with embedded styles", "chevron.left.forwardslash.chevron.right", nil, [], .file)
        reg(.copyRichText, "Copy Formatted Rich Text", "Copy formatted HTML/rich text to clipboard", "doc.on.doc", nil, [], .file)

        // Application
        reg(.openCommandPalette, "Command Palette…", "Search all commands, themes, and actions", "command", "k", .command, .application)
        reg(.openSettings, "Settings…", "Open Lucid Preferences", "gearshape", ",", .command, .application)

        self.commands = map
    }

    public func metadata(for id: LucidCommandID) -> LucidCommandMetadata? {
        commands[id]
    }
}
