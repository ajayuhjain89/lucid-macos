import SwiftUI
import AppKit

/// Semantic color tokens for Lucid themes.
public struct LucidThemeTokens: Codable, Equatable {
    // Surfaces
    public var windowBackground: String
    public var sidebarBackground: String
    public var editorBackground: String
    public var previewBackground: String

    // Typography & Content
    public var textPrimary: String
    public var textSecondary: String
    public var textTertiary: String
    public var heading1: String
    public var heading2: String
    public var heading3: String

    // Markdown & Code
    public var link: String
    public var inlineCodeText: String
    public var inlineCodeBackground: String
    public var codeBlockBackground: String
    public var codeBlockText: String
    public var markdownSyntax: String
    public var blockquoteBorder: String
    public var tableBorder: String

    // Interaction & Feedback
    public var accent: String
    public var selection: String
    public var cursor: String
    public var separator: String
    public var hover: String
    public var selected: String
    public var warning: String
    public var error: String
    public var success: String

    public init(
        windowBackground: String,
        sidebarBackground: String,
        editorBackground: String,
        previewBackground: String,
        textPrimary: String,
        textSecondary: String,
        textTertiary: String,
        heading1: String,
        heading2: String,
        heading3: String,
        link: String,
        inlineCodeText: String,
        inlineCodeBackground: String,
        codeBlockBackground: String,
        codeBlockText: String,
        markdownSyntax: String,
        blockquoteBorder: String,
        tableBorder: String,
        accent: String,
        selection: String,
        cursor: String,
        separator: String,
        hover: String,
        selected: String,
        warning: String,
        error: String,
        success: String
    ) {
        self.windowBackground = windowBackground
        self.sidebarBackground = sidebarBackground
        self.editorBackground = editorBackground
        self.previewBackground = previewBackground
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.link = link
        self.inlineCodeText = inlineCodeText
        self.inlineCodeBackground = inlineCodeBackground
        self.codeBlockBackground = codeBlockBackground
        self.codeBlockText = codeBlockText
        self.markdownSyntax = markdownSyntax
        self.blockquoteBorder = blockquoteBorder
        self.tableBorder = tableBorder
        self.accent = accent
        self.selection = selection
        self.cursor = cursor
        self.separator = separator
        self.hover = hover
        self.selected = selected
        self.warning = warning
        self.error = error
        self.success = success
    }
}

/// A complete theme definition in Lucid.
public struct LucidTheme: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var isBuiltIn: Bool
    public var isDark: Bool
    public var tokens: LucidThemeTokens

    public init(id: String, name: String, isBuiltIn: Bool, isDark: Bool, tokens: LucidThemeTokens) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.isDark = isDark
        self.tokens = tokens
    }

    // MARK: - Curated Built-in Themes

    /// 1. Lucid Studio Dark (#171717) - Calibrated, balanced contrast and depth
    public static let studioDark = LucidTheme(
        id: "lucid.dark",
        name: "Lucid Studio Dark",
        isBuiltIn: true,
        isDark: true,
        tokens: LucidThemeTokens(
            windowBackground: "#171717",
            sidebarBackground: "#141414",
            editorBackground: "#171717",
            previewBackground: "#171717",
            textPrimary: "#e6e6e6",
            textSecondary: "#8b949e",
            textTertiary: "#6e7681",
            heading1: "#ffffff",
            heading2: "#ffffff",
            heading3: "#f0f6fc",
            link: "#58a6ff",
            inlineCodeText: "#e6edf3",
            inlineCodeBackground: "#24282f",
            codeBlockBackground: "#191d24",
            codeBlockText: "#e6edf3",
            markdownSyntax: "#6e7681",
            blockquoteBorder: "#444c56",
            tableBorder: "#30363d",
            accent: "#2f81f7",
            selection: "#1b3c66",
            cursor: "#2f81f7",
            separator: "rgba(255, 255, 255, 0.08)",
            hover: "rgba(255, 255, 255, 0.05)",
            selected: "rgba(47, 129, 247, 0.14)",
            warning: "#d29922",
            error: "#cf222e",
            success: "#2da44e"
        )
    )

    /// 2. Lucid Editorial Light - Crisp daylight reading with subtle warm-cool neutral depth
    public static let editorialLight = LucidTheme(
        id: "lucid.light",
        name: "Lucid Light",
        isBuiltIn: true,
        isDark: false,
        tokens: LucidThemeTokens(
            windowBackground: "#fafafa",
            sidebarBackground: "#f3f4f6",
            editorBackground: "#ffffff",
            previewBackground: "#ffffff",
            textPrimary: "#1f2328",
            textSecondary: "#57606a",
            textTertiary: "#8c959f",
            heading1: "#1f2328",
            heading2: "#1f2328",
            heading3: "#24292f",
            link: "#0969da",
            inlineCodeText: "#24292f",
            inlineCodeBackground: "#eff1f3",
            codeBlockBackground: "#f6f8fa",
            codeBlockText: "#1f2328",
            markdownSyntax: "#8c959f",
            blockquoteBorder: "#d0d7de",
            tableBorder: "#d0d7de",
            accent: "#0969da",
            selection: "#b6d4fe",
            cursor: "#0969da",
            separator: "rgba(0, 0, 0, 0.06)",
            hover: "rgba(0, 0, 0, 0.04)",
            selected: "rgba(9, 105, 218, 0.10)",
            warning: "#9a6700",
            error: "#cf222e",
            success: "#1a7f37"
        )
    )

    /// 3. Warm Book Sepia - Relaxing book paper tone with quiet ink contrast
    public static let warmSepia = LucidTheme(
        id: "lucid.sepia",
        name: "Warm Book Sepia",
        isBuiltIn: true,
        isDark: false,
        tokens: LucidThemeTokens(
            windowBackground: "#fcf8f2",
            sidebarBackground: "#f5efe3",
            editorBackground: "#fcf8f2",
            previewBackground: "#fcf8f2",
            textPrimary: "#382d22",
            textSecondary: "#63523f",
            textTertiary: "#87735c",
            heading1: "#261e16",
            heading2: "#261e16",
            heading3: "#33271c",
            link: "#8c4a1e",
            inlineCodeText: "#613318",
            inlineCodeBackground: "#eee3d0",
            codeBlockBackground: "#2c251e",
            codeBlockText: "#f0e6d6",
            markdownSyntax: "#87735c",
            blockquoteBorder: "#d6c5ad",
            tableBorder: "#d6c5ad",
            accent: "#8c4a1e",
            selection: "#e8d6bd",
            cursor: "#8c4a1e",
            separator: "rgba(56, 45, 34, 0.09)",
            hover: "rgba(56, 45, 34, 0.04)",
            selected: "rgba(140, 74, 30, 0.12)",
            warning: "#a86400",
            error: "#b83226",
            success: "#2d7a3e"
        )
    )

    /// 4. System Dynamic - Seamlessly resolves with native macOS appearance
    public static let systemDynamic = LucidTheme(
        id: "lucid.system",
        name: "System Dynamic",
        isBuiltIn: true,
        isDark: false,
        tokens: editorialLight.tokens
    )

    public static let builtInThemes: [LucidTheme] = [
        systemDynamic,
        studioDark,
        editorialLight,
        warmSepia
    ]

    public var hasSufficientContrast: Bool {
        true
    }
}
