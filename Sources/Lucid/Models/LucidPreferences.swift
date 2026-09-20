import SwiftUI
import Combine
import AppKit

public enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case dark = "dark"
    case light = "light"
    case sepia = "sepia"
    // Preserved for backward compatibility
    case oled = "oled"
    case nord = "nord"
    case dracula = "dracula"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "System Dynamic"
        case .dark: return "Lucid Studio Dark (#171717)"
        case .light: return "Lucid Editorial Light"
        case .sepia: return "Warm Book Sepia"
        case .oled: return "OLED Pure Black"
        case .nord: return "Nord Arctic"
        case .dracula: return "Dracula"
        }
    }

    /// Curated first-party themes for default interface
    public static var curatedThemes: [ThemeMode] {
        [.system, .dark, .light, .sepia]
    }
}

public enum FontFamily: String, CaseIterable, Identifiable, Codable {
    case sans = "sans"
    case serif = "serif"
    case mono = "mono"
    case custom = "custom"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sans: return "SF Pro (System Sans)"
        case .serif: return "New York (Editorial Serif)"
        case .mono: return "SF Mono (Code)"
        case .custom: return "Custom System Font…"
        }
    }

    public func cssValue(customName: String) -> String {
        switch self {
        case .sans:
            return "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        case .serif:
            return "'New York', Charter, 'Times New Roman', serif"
        case .mono:
            return "'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace"
        case .custom:
            return customName.isEmpty ? "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" : "'\(customName)', sans-serif"
        }
    }

    public func nsFont(size: CGFloat, customName: String = "") -> NSFont {
        switch self {
        case .sans:
            return NSFont.systemFont(ofSize: size, weight: .regular)
        case .serif:
            let descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif) ?? NSFontDescriptor()
            return NSFont(descriptor: descriptor, size: size) ?? NSFont.systemFont(ofSize: size)
        case .mono:
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case .custom:
            if !customName.isEmpty, let font = NSFont(name: customName, size: size) {
                return font
            }
            return NSFont.systemFont(ofSize: size)
        }
    }
}

public enum ContentWidth: String, CaseIterable, Identifiable, Codable {
    case standard = "min(1200px, 90vw)"
    case compact = "min(980px, 90vw)"
    case narrow = "min(760px, 92vw)"
    case full = "100%"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .compact: return "Compact"
        case .narrow: return "Narrow"
        case .full: return "Full Width"
        }
    }

    public var maxWidthPoints: CGFloat {
        switch self {
        case .standard: return 1200
        case .compact: return 980
        case .narrow: return 760
        case .full: return .infinity
        }
    }
}

public enum ViewMode: String, CaseIterable, Identifiable, Codable {
    case reader = "reader"
    case split = "split"
    case editor = "editor"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .reader: return "Reader"
        case .split: return "Split"
        case .editor: return "Editor"
        }
    }

    public var systemImage: String {
        switch self {
        case .reader: return "book"
        case .split: return "rectangle.split.2x1"
        case .editor: return "square.and.pencil"
        }
    }
}

public enum TableDensity: String, CaseIterable, Identifiable, Codable {
    case compact = "compact"
    case `default` = "default"
    case comfortable = "comfortable"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .default: return "Default"
        case .comfortable: return "Comfortable"
        }
    }
}

public enum LucidPreset: String, CaseIterable, Identifiable {
    case lucidDefault = "default"
    case minimalWriter = "writer"
    case technicalDoc = "techDoc"
    case developer = "developer"
    case academic = "academic"
    case compact = "compact"
    case reading = "reading"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .lucidDefault: return "Lucid Default"
        case .minimalWriter: return "Minimal Writer"
        case .technicalDoc: return "Technical Documentation"
        case .developer: return "Developer"
        case .academic: return "Academic / Scientific"
        case .compact: return "Compact"
        case .reading: return "Reading Focus"
        }
    }

    public var description: String {
        switch self {
        case .lucidDefault: return "Signature balanced environment with Studio Dark and SF Pro."
        case .minimalWriter: return "Zero-distraction centered writing with no line numbers or sidebar."
        case .technicalDoc: return "Wide canvas with breakout layout, outline sidebar, and full STEM support."
        case .developer: return "SF Mono editor with line numbers, compact density, and live diagrams."
        case .academic: return "Editorial serif typography, warm paper tones, and comfortable leading."
        case .compact: return "High-density layout optimized for smaller displays or multitasking."
        case .reading: return "Reader-only presentation with large type and warm book sepia."
        }
    }
}

public final class LucidPreferences: ObservableObject {
    public static let shared = LucidPreferences()

    // MARK: - Appearance
    @AppStorage("lucid.theme") public var theme: ThemeMode = .dark
    @AppStorage("lucid.accentColor") public var accentColor: String = "#2f81f7"
    @AppStorage("lucid.density") public var density: InterfaceDensity = .default

    // MARK: - Typography & Layout
    @AppStorage("lucid.fontFamily") public var fontFamily: FontFamily = .sans
    @AppStorage("lucid.customFontName") public var customFontName: String = "Helvetica Neue"
    @AppStorage("lucid.fontSize") public var fontSize: Double = 18.0
    @AppStorage("lucid.lineHeight") public var lineHeight: Double = 1.75
    @AppStorage("lucid.contentWidth") public var contentWidth: ContentWidth = .standard
    @AppStorage("lucid.breakoutEnabled") public var breakoutEnabled: Bool = true

    // MARK: - Editor
    @AppStorage("lucid.lineNumbers") public var lineNumbers: Bool = false
    @AppStorage("lucid.highlightCurrentLine") public var highlightCurrentLine: Bool = true
    @AppStorage("lucid.autoPairDelimiters") public var autoPairDelimiters: Bool = true
    @AppStorage("lucid.autoIndent") public var autoIndent: Bool = true
    @AppStorage("lucid.wordWrap") public var wordWrap: Bool = true
    @AppStorage("lucid.syntaxDimming") public var syntaxDimming: Bool = false

    // MARK: - Preview & Technical
    @AppStorage("lucid.tableDensity") public var tableDensity: TableDensity = .default
    @AppStorage("lucid.mathScale") public var mathScale: Double = 1.0
    @AppStorage("lucid.mermaidScale") public var mermaidScale: Double = 1.0
    @AppStorage("lucid.enableKaTeX") public var enableKaTeX: Bool = true
    @AppStorage("lucid.enableMhchem") public var enableMhchem: Bool = true
    @AppStorage("lucid.enableMermaid") public var enableMermaid: Bool = true
    @AppStorage("lucid.enableSyntaxHighlighting") public var enableSyntaxHighlighting: Bool = true
    @AppStorage("lucid.customCSS") public var customCSS: String = ""

    // MARK: - Modes & Workspace
    @AppStorage("lucid.focusMode") public var focusMode: Bool = false
    @AppStorage("lucid.typewriterMode") public var typewriterMode: Bool = false
    @AppStorage("lucid.viewMode") public var viewMode: ViewMode = .reader
    @AppStorage("lucid.showOutline") public var showOutline: Bool = false
    @AppStorage("lucid.showInspector") public var showInspector: Bool = false
    @AppStorage("lucid.showStatusBar") public var showStatusBar: Bool = true

    // MARK: - Status Bar Metrics Customization
    @AppStorage("lucid.statusWordCount") public var statusWordCount: Bool = true
    @AppStorage("lucid.statusReadingTime") public var statusReadingTime: Bool = true
    @AppStorage("lucid.statusLineCol") public var statusLineCol: Bool = false
    @AppStorage("lucid.statusCharCount") public var statusCharCount: Bool = false

    public init() {}

    public func effectiveTheme(systemColorScheme: ColorScheme) -> String {
        if theme == .system {
            return systemColorScheme == .dark ? "dark" : "light"
        }
        return theme.rawValue
    }

    public func jsonPayload(systemColorScheme: ColorScheme) -> String {
        let dict: [String: Any] = [
            "theme": effectiveTheme(systemColorScheme: systemColorScheme),
            "fontFamily": fontFamily.cssValue(customName: customFontName),
            "fontSize": fontSize,
            "lineHeight": lineHeight,
            "contentWidth": contentWidth.rawValue,
            "accentColor": accentColor,
            "breakout": breakoutEnabled,
            "focusMode": focusMode,
            "typewriterMode": typewriterMode,
            "tableDensity": tableDensity.rawValue,
            "mathScale": mathScale,
            "mermaidScale": mermaidScale,
            "enableKaTeX": enableKaTeX,
            "enableMhchem": enableMhchem,
            "enableMermaid": enableMermaid,
            "enableSyntaxHighlighting": enableSyntaxHighlighting,
            "customCSS": customCSS
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }

    // MARK: - Presets Application
    public func applyPreset(_ preset: LucidPreset) {
        switch preset {
        case .lucidDefault:
            theme = .dark
            fontFamily = .sans
            fontSize = 18.0
            lineHeight = 1.75
            contentWidth = .standard
            breakoutEnabled = true
            lineNumbers = false
            highlightCurrentLine = true
            showOutline = false
            viewMode = .reader

        case .minimalWriter:
            theme = .dark
            fontFamily = .sans
            fontSize = 19.0
            lineHeight = 1.85
            contentWidth = .narrow
            breakoutEnabled = false
            lineNumbers = false
            highlightCurrentLine = true
            showOutline = false
            showStatusBar = false
            focusMode = true
            viewMode = .editor

        case .technicalDoc:
            theme = .dark
            fontFamily = .sans
            fontSize = 17.0
            lineHeight = 1.70
            contentWidth = .standard
            breakoutEnabled = true
            lineNumbers = true
            highlightCurrentLine = true
            showOutline = true
            showStatusBar = true
            viewMode = .split

        case .developer:
            theme = .dark
            fontFamily = .mono
            fontSize = 15.0
            lineHeight = 1.60
            contentWidth = .full
            breakoutEnabled = true
            lineNumbers = true
            highlightCurrentLine = true
            showOutline = true
            showStatusBar = true
            viewMode = .split

        case .academic:
            theme = .sepia
            fontFamily = .serif
            fontSize = 18.0
            lineHeight = 1.80
            contentWidth = .standard
            breakoutEnabled = true
            lineNumbers = false
            highlightCurrentLine = false
            showOutline = true
            showStatusBar = true
            viewMode = .reader

        case .compact:
            theme = .dark
            fontFamily = .sans
            fontSize = 14.0
            lineHeight = 1.50
            contentWidth = .full
            breakoutEnabled = false
            lineNumbers = true
            density = .compact
            showStatusBar = true
            viewMode = .split

        case .reading:
            theme = .sepia
            fontFamily = .serif
            fontSize = 20.0
            lineHeight = 1.85
            contentWidth = .compact
            breakoutEnabled = true
            showOutline = false
            showStatusBar = false
            viewMode = .reader
        }
    }

    // MARK: - Domain Resets
    public func resetEditor() {
        fontFamily = .sans
        fontSize = 18.0
        lineHeight = 1.75
        contentWidth = .standard
        lineNumbers = false
        highlightCurrentLine = true
        autoPairDelimiters = true
        autoIndent = true
        wordWrap = true
        syntaxDimming = false
    }

    public func resetAppearance() {
        theme = .dark
        accentColor = "#2f81f7"
        density = .default
    }

    public func resetPreview() {
        breakoutEnabled = true
        tableDensity = .default
        mathScale = 1.0
        mermaidScale = 1.0
        enableKaTeX = true
        enableMhchem = true
        enableMermaid = true
        enableSyntaxHighlighting = true
    }

    public func resetAll() {
        resetAppearance()
        resetEditor()
        resetPreview()
        showOutline = false
        showInspector = false
        showStatusBar = true
        statusWordCount = true
        statusReadingTime = true
        statusLineCol = false
        statusCharCount = false
        focusMode = false
        typewriterMode = false
        customCSS = ""
    }
}
