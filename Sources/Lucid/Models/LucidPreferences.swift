import SwiftUI
import Combine

public enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case dark = "dark"
    case light = "light"
    case sepia = "sepia"
    case oled = "oled"
    case nord = "nord"
    case dracula = "dracula"
    case system = "system"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dark: return "Lucid Dark (Studio #171717)"
        case .light: return "Pure White"
        case .sepia: return "Warm Book Sepia"
        case .oled: return "OLED Pure Black"
        case .nord: return "Nord Arctic"
        case .dracula: return "Dracula"
        case .system: return "System Dynamic"
        }
    }
}

public enum FontFamily: String, CaseIterable, Identifiable, Codable {
    case sans = "sans"
    case serif = "serif"
    case mono = "mono"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sans: return "SF Pro (System Sans)"
        case .serif: return "New York (Editorial Serif)"
        case .mono: return "SF Mono (Code)"
        }
    }

    public var cssValue: String {
        switch self {
        case .sans:
            return "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        case .serif:
            return "'New York', Charter, 'Times New Roman', serif"
        case .mono:
            return "'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace"
        }
    }
}

public enum ContentWidth: String, CaseIterable, Identifiable, Codable {
    case standard = "1040px"
    case compact = "820px"
    case narrow = "680px"
    case full = "100%"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard: return "Standard (1040px - Extension Default)"
        case .compact: return "Compact (820px)"
        case .narrow: return "Narrow (680px)"
        case .full: return "Full Width"
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

public final class LucidPreferences: ObservableObject {
    public static let shared = LucidPreferences()

    @AppStorage("lucid.theme") public var theme: ThemeMode = .dark
    @AppStorage("lucid.fontFamily") public var fontFamily: FontFamily = .sans
    @AppStorage("lucid.fontSize") public var fontSize: Double = 18.0
    @AppStorage("lucid.lineHeight") public var lineHeight: Double = 1.75
    @AppStorage("lucid.contentWidth") public var contentWidth: ContentWidth = .standard
    @AppStorage("lucid.accentColor") public var accentColor: String = "#2f81f7"
    @AppStorage("lucid.breakoutEnabled") public var breakoutEnabled: Bool = true
    @AppStorage("lucid.clickToEdit") public var clickToEdit: Bool = true
    @AppStorage("lucid.viewMode") public var viewMode: ViewMode = .reader
    @AppStorage("lucid.showOutline") public var showOutline: Bool = false
    @AppStorage("lucid.showInspector") public var showInspector: Bool = false

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
            "fontFamily": fontFamily.cssValue,
            "fontSize": fontSize,
            "lineHeight": lineHeight,
            "contentWidth": contentWidth.rawValue,
            "accentColor": accentColor,
            "breakout": breakoutEnabled,
            "clickToEdit": clickToEdit
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }
}
