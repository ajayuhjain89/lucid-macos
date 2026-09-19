import SwiftUI
import Combine

public enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"
    case oled = "oled"
    case nord = "nord"
    case dracula = "dracula"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .oled: return "OLED Black"
        case .nord: return "Nord"
        case .dracula: return "Dracula"
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
        case .sans: return "SF Pro (Sans)"
        case .serif: return "New York (Serif)"
        case .mono: return "SF Mono (Code)"
        }
    }

    public var cssValue: String {
        switch self {
        case .sans:
            return "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif"
        case .serif:
            return "'New York', Charter, 'Times New Roman', serif"
        case .mono:
            return "'SF Mono', Menlo, Monaco, 'Cascadia Code', monospace"
        }
    }
}

public enum ContentWidth: String, CaseIterable, Identifiable, Codable {
    case narrow = "680px"
    case standard = "820px"
    case wide = "980px"
    case full = "100%"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .narrow: return "Narrow (680px)"
        case .standard: return "Standard (820px)"
        case .wide: return "Wide (980px)"
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

    @AppStorage("lucid.theme") public var theme: ThemeMode = .system
    @AppStorage("lucid.fontFamily") public var fontFamily: FontFamily = .sans
    @AppStorage("lucid.fontSize") public var fontSize: Double = 16.0
    @AppStorage("lucid.lineHeight") public var lineHeight: Double = 1.7
    @AppStorage("lucid.contentWidth") public var contentWidth: ContentWidth = .standard
    @AppStorage("lucid.accentColor") public var accentColor: String = "#0969da"
    @AppStorage("lucid.breakoutEnabled") public var breakoutEnabled: Bool = true
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
            "breakout": breakoutEnabled
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }
}
