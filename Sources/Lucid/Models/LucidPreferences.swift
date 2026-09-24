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
        case .dark: return "Studio Dark"
        case .light: return "Editorial Light"
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
        case .developer: return "SF Mono editor with line numbers, split view, and live diagrams."
        case .academic: return "Editorial serif typography, warm paper tones, and comfortable leading."
        case .compact: return "High-density layout optimized for smaller displays or multitasking."
        case .reading: return "Reader-only presentation with large type and warm book sepia."
        }
    }
}

public final class LucidPreferences: ObservableObject {
    public static let shared = LucidPreferences()

    // MARK: - Canonical Defaults
    public enum Defaults {
        // Appearance
        public static let theme: ThemeMode = .dark
        public static let accentColor: String = "#2f81f7"
        public static let density: InterfaceDensity = .default

        // Typography & Layout
        public static let fontFamily: FontFamily = .sans
        public static let customFontName: String = "Helvetica Neue"
        public static let fontSize: Double = 18.0
        public static let lineHeight: Double = 1.75
        public static let contentWidth: ContentWidth = .standard
        public static let breakoutEnabled: Bool = true

        // Editor
        public static let lineNumbers: Bool = false
        public static let highlightCurrentLine: Bool = true
        public static let autoPairDelimiters: Bool = true
        public static let autoIndent: Bool = true
        public static let wordWrap: Bool = true

        // Preview & Technical
        public static let tableDensity: TableDensity = .default
        public static let mathScale: Double = 1.0
        public static let mermaidScale: Double = 1.0
        public static let enableKaTeX: Bool = true
        public static let enableMhchem: Bool = true
        public static let enableMermaid: Bool = true
        public static let enableSyntaxHighlighting: Bool = true
        public static let customCSS: String = ""

        // Modes & Workspace
        public static let focusMode: Bool = false
        public static let typewriterMode: Bool = false
        public static let viewMode: ViewMode = .reader
        public static let showOutline: Bool = false
        public static let showStatusBar: Bool = true

        // Status Bar Metrics
        public static let statusWordCount: Bool = true
        public static let statusReadingTime: Bool = true
        public static let statusLineCol: Bool = false
        public static let statusCharCount: Bool = false
    }

    // MARK: - Canonical Limits & Ranges
    public enum Limits {
        public static let fontSizeRange: ClosedRange<Double> = 12.0...28.0
        public static let fontSizeStep: Double = 1.0
        public static let lineHeightRange: ClosedRange<Double> = 1.3...2.4
        public static let lineHeightStep: Double = 0.05
        public static let mathScaleRange: ClosedRange<Double> = 0.8...1.5
        public static let mathScaleStep: Double = 0.1
        public static let mermaidScaleRange: ClosedRange<Double> = 0.8...1.5
        public static let mermaidScaleStep: Double = 0.1
    }

    // MARK: - Appearance
    @AppStorage("lucid.theme") public var theme: ThemeMode = Defaults.theme
    @AppStorage("lucid.accentColor") public var accentColor: String = Defaults.accentColor
    @AppStorage("lucid.density") public var density: InterfaceDensity = Defaults.density

    // MARK: - Typography & Layout
    @AppStorage("lucid.fontFamily") public var fontFamily: FontFamily = Defaults.fontFamily
    @AppStorage("lucid.customFontName") public var customFontName: String = Defaults.customFontName
    @AppStorage("lucid.fontSize") public var fontSize: Double = Defaults.fontSize
    @AppStorage("lucid.lineHeight") public var lineHeight: Double = Defaults.lineHeight
    @AppStorage("lucid.contentWidth") public var contentWidth: ContentWidth = Defaults.contentWidth
    @AppStorage("lucid.breakoutEnabled") public var breakoutEnabled: Bool = Defaults.breakoutEnabled

    // MARK: - Editor
    @AppStorage("lucid.lineNumbers") public var lineNumbers: Bool = Defaults.lineNumbers
    @AppStorage("lucid.highlightCurrentLine") public var highlightCurrentLine: Bool = Defaults.highlightCurrentLine
    @AppStorage("lucid.autoPairDelimiters") public var autoPairDelimiters: Bool = Defaults.autoPairDelimiters
    @AppStorage("lucid.autoIndent") public var autoIndent: Bool = Defaults.autoIndent
    @AppStorage("lucid.wordWrap") public var wordWrap: Bool = Defaults.wordWrap

    // MARK: - Preview & Technical
    @AppStorage("lucid.tableDensity") public var tableDensity: TableDensity = Defaults.tableDensity
    @AppStorage("lucid.mathScale") public var mathScale: Double = Defaults.mathScale
    @AppStorage("lucid.mermaidScale") public var mermaidScale: Double = Defaults.mermaidScale
    @AppStorage("lucid.enableKaTeX") public var enableKaTeX: Bool = Defaults.enableKaTeX
    @AppStorage("lucid.enableMhchem") public var enableMhchem: Bool = Defaults.enableMhchem
    @AppStorage("lucid.enableMermaid") public var enableMermaid: Bool = Defaults.enableMermaid
    @AppStorage("lucid.enableSyntaxHighlighting") public var enableSyntaxHighlighting: Bool = Defaults.enableSyntaxHighlighting
    @AppStorage("lucid.customCSS") public var customCSS: String = Defaults.customCSS

    // MARK: - Modes & Workspace
    @AppStorage("lucid.focusMode") public var focusMode: Bool = Defaults.focusMode
    @AppStorage("lucid.typewriterMode") public var typewriterMode: Bool = Defaults.typewriterMode
    @AppStorage("lucid.viewMode") public var viewMode: ViewMode = Defaults.viewMode
    @AppStorage("lucid.showOutline") public var showOutline: Bool = Defaults.showOutline
    @AppStorage("lucid.showStatusBar") public var showStatusBar: Bool = Defaults.showStatusBar

    // MARK: - Status Bar Metrics Customization
    @AppStorage("lucid.statusWordCount") public var statusWordCount: Bool = Defaults.statusWordCount
    @AppStorage("lucid.statusReadingTime") public var statusReadingTime: Bool = Defaults.statusReadingTime
    @AppStorage("lucid.statusLineCol") public var statusLineCol: Bool = Defaults.statusLineCol
    @AppStorage("lucid.statusCharCount") public var statusCharCount: Bool = Defaults.statusCharCount

    public init() {
        // Left behind by an old "click to edit" setting that no longer exists.
        UserDefaults.standard.removeObject(forKey: "lucid.clickToEdit")
    }

    public func effectiveTheme(systemColorScheme: ColorScheme) -> String {
        switch theme {
        case .system:
            return systemColorScheme == .dark ? "dark" : "light"
        case .oled, .nord, .dracula:
            // Legacy themes (no longer offered) have no preview styles: use dark.
            return "dark"
        default:
            return theme.rawValue
        }
    }

    /// Posted (object: the preferences) after `applyPreset`, so open windows adopt it.
    public static let presetAppliedNotification = Notification.Name("LucidPresetApplied")

    /// The preview's preference payload. `focusMode` overrides the app-wide value
    /// with the window's own (see WindowViewState).
    public func jsonPayload(systemColorScheme: ColorScheme, focusMode: Bool? = nil) -> String {
        let dict: [String: Any] = [
            "theme": effectiveTheme(systemColorScheme: systemColorScheme),
            "fontFamily": fontFamily.cssValue(customName: customFontName),
            "fontSize": fontSize,
            "lineHeight": lineHeight,
            "contentWidth": contentWidth.rawValue,
            "accentColor": accentColor,
            "breakout": breakoutEnabled,
            "focusMode": focusMode ?? self.focusMode,
            "typewriterMode": typewriterMode,
            "tableDensity": tableDensity.rawValue,
            "mathScale": mathScale,
            "mermaidScale": mermaidScale,
            "enableKaTeX": enableKaTeX,
            "enableMhchem": enableMhchem,
            "enableMermaid": enableMermaid,
            "enableSyntaxHighlighting": enableSyntaxHighlighting,
            "customCSS": customCSS,
            "topInset": LucidChrome.contentTopInset,
            // The in-app preview sits under the floating toolbar; exports set 0.
            "chromeHeight": LucidChrome.toolbarHeight
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }

    // MARK: - Presets Application
    public func applyPreset(_ preset: LucidPreset) {
        // A preset defines the whole configuration: start the settings that any
        // preset controls from their defaults, so nothing from the previous
        // preset (Focus Mode, a hidden status bar, compact density) lingers.
        density = Defaults.density
        focusMode = Defaults.focusMode
        typewriterMode = Defaults.typewriterMode
        showStatusBar = Defaults.showStatusBar
        highlightCurrentLine = Defaults.highlightCurrentLine
        lineNumbers = Defaults.lineNumbers
        showOutline = Defaults.showOutline

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
        NotificationCenter.default.post(name: Self.presetAppliedNotification, object: self)
    }

    // MARK: - Domain Resets
    public func resetEditor() {
        fontFamily = Defaults.fontFamily
        customFontName = Defaults.customFontName
        fontSize = Defaults.fontSize
        lineHeight = Defaults.lineHeight
        contentWidth = Defaults.contentWidth
        lineNumbers = Defaults.lineNumbers
        highlightCurrentLine = Defaults.highlightCurrentLine
        autoPairDelimiters = Defaults.autoPairDelimiters
        autoIndent = Defaults.autoIndent
        wordWrap = Defaults.wordWrap
    }

    public func resetAppearance() {
        theme = Defaults.theme
        accentColor = Defaults.accentColor
        density = Defaults.density
    }

    public func resetPreview() {
        breakoutEnabled = Defaults.breakoutEnabled
        tableDensity = Defaults.tableDensity
        mathScale = Defaults.mathScale
        mermaidScale = Defaults.mermaidScale
        enableKaTeX = Defaults.enableKaTeX
        enableMhchem = Defaults.enableMhchem
        enableMermaid = Defaults.enableMermaid
        enableSyntaxHighlighting = Defaults.enableSyntaxHighlighting
    }

    public func resetAll() {
        resetAppearance()
        resetEditor()
        resetPreview()
        showOutline = Defaults.showOutline
        showStatusBar = Defaults.showStatusBar
        statusWordCount = Defaults.statusWordCount
        statusReadingTime = Defaults.statusReadingTime
        statusLineCol = Defaults.statusLineCol
        statusCharCount = Defaults.statusCharCount
        focusMode = Defaults.focusMode
        typewriterMode = Defaults.typewriterMode
        viewMode = Defaults.viewMode
        customCSS = Defaults.customCSS
    }
}
