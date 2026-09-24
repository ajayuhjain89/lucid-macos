import SwiftUI
import AppKit

// MARK: - Spacing Tokens
/// Restrained, mathematically disciplined spacing scale with semantic tokens.
public enum LucidSpacing {
    // Restrained scale
    public static let xxxSmall: CGFloat = 2
    public static let xxSmall: CGFloat = 4
    public static let xSmall: CGFloat = 6
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xLarge: CGFloat = 20
    public static let xxLarge: CGFloat = 24
    public static let xxxLarge: CGFloat = 32
    public static let huge: CGFloat = 40
    public static let colossal: CGFloat = 48

    // Semantic usages
    public static let controlInnerPadding: CGFloat = 6
    public static let toolbarSpacing: CGFloat = 8
    public static let sidebarRowPadding: CGFloat = 6
    public static let panelPadding: CGFloat = 16
    public static let sectionSpacing: CGFloat = 20
    public static let contentSpacing: CGFloat = 12
    public static let popoverPadding: CGFloat = 12
}

// MARK: - Chrome Metrics
/// Fixed dimensions for the window chrome that both the SwiftUI layer and the
/// web/editor content insets are derived from, so the floating glass toolbar
/// and the content scrolling beneath it always agree on where the top edge is.
public enum LucidChrome {
    /// Height of the compact titlebar/toolbar row (optically aligned with traffic lights).
    public static let toolbarHeight: CGFloat = 36
    /// Breathing room between the toolbar and the first block of
    /// content when the document is scrolled to the very top.
    public static let readerTopBreathingRoom: CGFloat = 12
    /// Combined top inset applied to scrollable content so the first line sits
    /// clear of the toolbar at rest, then travels beneath it as the reader scrolls.
    public static var contentTopInset: CGFloat { toolbarHeight + readerTopBreathingRoom }
}

// MARK: - Corner Radius Tokens
/// Disciplined corner radius hierarchy for desktop software.
public enum LucidRadius {
    public static let micro: CGFloat = 4
    public static let xSmall: CGFloat = 5
    public static let small: CGFloat = 6
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 10
    public static let surface: CGFloat = 12
    public static let pill: CGFloat = 999
}

// MARK: - Interface Density
public enum InterfaceDensity: String, CaseIterable, Identifiable, Codable {
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

    public var sidebarRowHeight: CGFloat {
        switch self {
        case .compact: return 22
        case .default: return 26
        case .comfortable: return 30
        }
    }

    public var toolbarPadding: CGFloat {
        switch self {
        case .compact: return 4
        case .default: return 6
        case .comfortable: return 8
        }
    }

    public var statusBarHeight: CGFloat {
        switch self {
        case .compact: return 22
        case .default: return 26
        case .comfortable: return 30
        }
    }
}

// MARK: - Typography Tokens
/// Central semantic typography roles for Application Chrome.
public enum LucidTypography {
    public static let windowTitle: Font = .system(size: 13, weight: .medium)
    public static let sectionTitle: Font = .system(size: 12, weight: .semibold)
    public static let label: Font = .system(size: 13, weight: .regular)
    public static let labelMedium: Font = .system(size: 13, weight: .medium)
    public static let secondaryLabel: Font = .system(size: 12, weight: .regular)
    public static let caption: Font = .system(size: 11, weight: .regular)
    public static let metadata: Font = .system(size: 11, weight: .regular, design: .monospaced)
    public static let shortcut: Font = .system(size: 11, weight: .medium, design: .monospaced)
    public static let monoCode: Font = .system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Color & Surface Tokens
/// Semantic colors and surface materials that resolve dynamically.
public enum LucidColors {
    // Window & Surfaces
    public static var windowBackground: Color {
        Color(nsColor: NSColor.windowBackgroundColor)
    }

    public static var sidebarBackground: Color {
        Color(nsColor: NSColor.controlBackgroundColor)
    }

    public static var elevatedSurface: Color {
        Color(nsColor: NSColor.underPageBackgroundColor)
    }

    public static var hoverSurface: Color {
        Color(nsColor: NSColor.textColor).opacity(0.05)
    }

    public static var pressedSurface: Color {
        Color(nsColor: NSColor.textColor).opacity(0.09)
    }

    public static var softSelection: Color {
        Color.accentColor.opacity(0.12)
    }

    public static var subtleSeparator: Color {
        Color(nsColor: NSColor.separatorColor).opacity(0.35)
    }

    public static var subtleBorder: Color {
        Color(nsColor: NSColor.separatorColor).opacity(0.4)
    }

    // Text Hierarchy
    public static var textPrimary: Color {
        Color(nsColor: NSColor.labelColor)
    }

    public static var textSecondary: Color {
        Color(nsColor: NSColor.secondaryLabelColor)
    }

    public static var textTertiary: Color {
        Color(nsColor: NSColor.tertiaryLabelColor)
    }

    // Feedback
    public static var warning: Color {
        Color(hex: "#d29922")
    }

    public static var error: Color {
        Color(hex: "#cf222e")
    }

    public static var success: Color {
        Color(hex: "#1a7f37")
    }
}

// MARK: - Subtle Elevation Shadows
public enum LucidShadow {
    public static func popover<V: View>(_ content: V) -> some View {
        content.shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
    }

    public static func commandPalette<V: View>(_ content: V) -> some View {
        content.shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 10)
    }

    public static func floatingBar<V: View>(_ content: V) -> some View {
        content.shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Motion Tokens
/// Consistent, restrained animation curves so every interaction feels part of one system.
/// A deliberately small vocabulary: micro (hover/press), state, panel, modal, and
/// the near-subconscious `glass` used to fade chrome depth in on scroll.
public enum LucidMotion {
    /// Quick hover / focus tints (100–140ms micro-interaction).
    public static let hover: Animation = .easeOut(duration: 0.13)
    /// Springy press feedback.
    public static let press: Animation = .spring(response: 0.24, dampingFraction: 0.7)
    /// Selection / state changes.
    public static let state: Animation = .spring(response: 0.32, dampingFraction: 0.84)
    /// Panel / mode transitions (160–220ms smooth ease).
    public static let panel: Animation = .easeInOut(duration: 0.19)
    /// Modal / palette entrances (140–180ms ease-out).
    public static let modal: Animation = .easeOut(duration: 0.16)
    /// Near-subconscious chrome depth fade tied to scroll position.
    public static let glass: Animation = .easeOut(duration: 0.22)

    /// Returns the given animation, or `nil` when the system asks to reduce motion,
    /// so callers can keep state changes instant for accessibility.
    public static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - Interaction Styles

/// A universal press style: subtle spring scale + dim, applied to plain custom buttons
/// so every clickable surface responds with the same tactile feedback.
public struct LucidPressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat
    var pressedOpacity: Double

    public init(pressedScale: CGFloat = 0.97, pressedOpacity: Double = 0.85) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(LucidMotion.press, value: configuration.isPressed)
    }
}

// MARK: - Reusable Visual Components

/// 1. LucidIconButton: Standardized icon button with optical centering, quiet states, and tooltips.
public struct LucidIconButton: View {
    let icon: String
    var size: CGFloat = 26
    var iconSize: CGFloat = 12
    var weight: Font.Weight = .medium
    var isActive: Bool = false
    var helpText: String? = nil
    var shortcutText: String? = nil
    let action: () -> Void

    @State private var isHovered = false

    public init(
        icon: String,
        size: CGFloat = 26,
        iconSize: CGFloat = 12,
        weight: Font.Weight = .medium,
        isActive: Bool = false,
        helpText: String? = nil,
        shortcutText: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconSize = iconSize
        self.weight = weight
        self.isActive = isActive
        self.helpText = helpText
        self.shortcutText = shortcutText
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: weight))
                .foregroundColor(isActive ? .accentColor : (isHovered ? LucidColors.textPrimary : LucidColors.textSecondary))
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: LucidRadius.small)
                        .fill(isActive ? LucidColors.softSelection : (isHovered ? LucidColors.hoverSurface : Color.clear))
                )
                .contentShape(Rectangle())
                .animation(LucidMotion.hover, value: isHovered)
                .animation(LucidMotion.state, value: isActive)
        }
        .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.86))
        .onHover { isHovered = $0 }
        .help(tooltipString)
        .accessibilityLabel(helpText ?? "")
    }

    private var tooltipString: String {
        var text = helpText ?? ""
        if let shortcut = shortcutText, !shortcut.isEmpty {
            text = text.isEmpty ? shortcut : "\(text) (\(shortcut))"
        }
        return text
    }
}

/// 2. LucidSearchField: Unified, elegant search input across Outline, Command Palette, Settings, and Find.
public struct LucidSearchField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 28
    var fontSize: CGFloat = 12
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    public init(
        placeholder: String,
        text: Binding<String>,
        height: CGFloat = 28,
        fontSize: CGFloat = 12,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.height = height
        self.fontSize = fontSize
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: LucidSpacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isFocused ? LucidColors.textPrimary : LucidColors.textSecondary)
                .font(.system(size: fontSize - 1, weight: .medium))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: fontSize, weight: .regular))
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(LucidColors.textSecondary)
                        .font(.system(size: fontSize - 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LucidSpacing.small)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: LucidRadius.small)
                .fill(isFocused ? Color.accentColor.opacity(0.05) : Color(nsColor: NSColor.controlBackgroundColor).opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LucidRadius.small)
                .stroke(isFocused ? Color.accentColor.opacity(0.45) : LucidColors.subtleBorder, lineWidth: 1)
        )
    }
}

/// 3. LucidSidebarRow: Soft native selection, quiet level indicator, and hover highlight.
public struct LucidSidebarRow: View {
    let title: String
    let level: Int
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    public init(
        title: String,
        level: Int,
        isActive: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.level = level
        self.isActive = isActive
        self.action = action
    }

    private var activeIndicator: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.accentColor)
            .frame(width: 2.5, height: 14)
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: LucidSpacing.xSmall) {
                // Active indicator pill
                if isActive {
                    activeIndicator
                        .transition(.scale.combined(with: .opacity))
                }

                // Quiet level indicator
                Text("H\(level)")
                    .font(.system(size: 9, weight: isActive ? .semibold : .medium, design: .monospaced))
                    .foregroundColor(isActive ? Color.accentColor : (isHovered ? LucidColors.textSecondary : LucidColors.textTertiary))
                    .frame(width: 18, alignment: .leading)

                // Dual-layer ghost geometry anchor:
                // The invisible ghost layer at maximum font weight (.semibold) sets the exact layout width and height,
                // ensuring the visible layer never causes horizontal or vertical layout shifting (0px shift)
                // when changing between regular, medium, and semibold.
                ZStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(0)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.system(size: 12, weight: isActive ? .semibold : (isHovered ? .medium : (level <= 2 ? .medium : .regular))))
                        .foregroundColor(isActive ? LucidColors.textPrimary : (isHovered ? LucidColors.textPrimary : LucidColors.textSecondary))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
            .padding(.leading, CGFloat((level - 1) * 8))
            .padding(.horizontal, LucidSpacing.controlInnerPadding)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: LucidRadius.xSmall)
                    .fill(
                        isActive
                            ? LucidColors.softSelection
                            : (isHovered ? LucidColors.hoverSurface : Color.clear)
                    )
            )
            .contentShape(Rectangle())
            .animation(LucidMotion.hover, value: isHovered)
            .animation(LucidMotion.state, value: isActive)
        }
        .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.98))
        .onHover { isHovered = $0 }
    }
}

/// 4. LucidSectionHeader: Clean section title and optional subtle separator.
public struct LucidSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var showsDivider: Bool = false

    public init(title: String, subtitle: String? = nil, showsDivider: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.showsDivider = showsDivider
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LucidSpacing.xxSmall) {
            if showsDivider {
                LucidDivider()
                    .padding(.bottom, LucidSpacing.xxSmall)
            }

            Text(title)
                .font(LucidTypography.sectionTitle)
                .foregroundColor(LucidColors.textPrimary)

            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(LucidTypography.caption)
                    .foregroundColor(LucidColors.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

/// 5. LucidSettingRow: Standard macOS setting row with primary label, secondary quiet description, and aligned controls.
public struct LucidSettingRow<Content: View>: View {
    let title: String
    var description: String? = nil
    let content: Content

    public init(
        title: String,
        description: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: LucidSpacing.large) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LucidTypography.label)
                    .foregroundColor(LucidColors.textPrimary)

                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(LucidTypography.caption)
                        .foregroundColor(LucidColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: LucidSpacing.medium)

            content
        }
        .padding(.vertical, 4)
    }
}

/// 6. LucidShortcutBadge: Quiet keyboard shortcut badge with monospaced typography.
public struct LucidShortcutBadge: View {
    let shortcut: String
    var isSelected: Bool = false

    public init(_ shortcut: String, isSelected: Bool = false) {
        self.shortcut = shortcut
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(shortcut)
            .font(LucidTypography.shortcut)
            .foregroundColor(isSelected ? LucidColors.textPrimary : LucidColors.textSecondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: LucidRadius.micro)
                    .fill(isSelected ? Color.white.opacity(0.16) : Color(nsColor: NSColor.separatorColor).opacity(0.22))
            )
    }
}

/// 7. LucidEmptyState: Restrained empty state with quiet SF Symbol, concise title, and single sentence.
public struct LucidEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    public init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: LucidSpacing.small) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(LucidColors.textTertiary)

            Text(title)
                .font(LucidTypography.labelMedium)
                .foregroundColor(LucidColors.textSecondary)

            Text(subtitle)
                .font(LucidTypography.caption)
                .foregroundColor(LucidColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(LucidTypography.caption)
                    .buttonStyle(.link)
                    .padding(.top, LucidSpacing.xxSmall)
            }
        }
        .padding(LucidSpacing.large)
        .frame(maxWidth: .infinity)
    }
}

/// 8. LucidDivider: 0.5pt subtle separator.
public struct LucidDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(LucidColors.subtleSeparator)
            .frame(height: 0.5)
    }
}

/// 9. LucidPopoverContainer: Popover card wrapper with consistent padding, radius, and subtle border.
public struct LucidPopoverContainer<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(LucidSpacing.popoverPadding)
            .background(.ultraThinMaterial)
            .cornerRadius(LucidRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: LucidRadius.large)
                    .stroke(LucidColors.subtleBorder, lineWidth: 0.5)
            )
    }
}

/// 10. LucidTextButton: A quiet, properly-padded text action button with a smooth hover tint.
/// Replaces bare `.buttonStyle(.link)` uses so labels never crowd their hit-target and
/// destructive actions read consistently.
public struct LucidTextButton: View {
    let title: String
    var systemImage: String? = nil
    var role: Role = .normal
    let action: () -> Void

    @State private var isHovered = false

    public enum Role { case normal, prominent, destructive }

    public init(_ title: String, systemImage: String? = nil, role: Role = .normal, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    private var baseColor: Color {
        switch role {
        case .normal: return LucidColors.textSecondary
        case .prominent: return .accentColor
        case .destructive: return LucidColors.error
        }
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: LucidSpacing.xxSmall) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(title)
                    .font(LucidTypography.caption)
                    .fixedSize()
            }
            .foregroundColor(isHovered ? (role == .normal ? LucidColors.textPrimary : baseColor) : baseColor)
            .opacity(role == .normal ? 1 : (isHovered ? 1 : 0.9))
            .padding(.horizontal, LucidSpacing.small)
            .padding(.vertical, LucidSpacing.xxSmall)
            .background(
                RoundedRectangle(cornerRadius: LucidRadius.xSmall)
                    .fill(isHovered ? baseColor.opacity(role == .normal ? 0.08 : 0.12) : Color.clear)
            )
            .contentShape(Rectangle())
            .animation(LucidMotion.hover, value: isHovered)
        }
        .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.95))
        .onHover { isHovered = $0 }
    }
}

/// 11. LucidSelectableCard: A polished, animated container for grid choices (presets, themes).
/// Manages its own hover lift, press feedback, and selected emphasis so cards feel alive.
public struct LucidSelectableCard<Content: View>: View {
    var isSelected: Bool
    let accessibilityName: String
    let accessibilityHint: String?
    let action: () -> Void
    let content: Content

    @State private var isHovered = false

    /// `accessibilityName` is what VoiceOver reads for the card (its visible title);
    /// `accessibilityHint` can carry the card's description.
    public init(
        isSelected: Bool = false,
        accessibilityName: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.accessibilityName = accessibilityName
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.content = content()
    }

    private var fill: Color {
        if isSelected { return LucidColors.softSelection }
        return Color(nsColor: NSColor.controlBackgroundColor).opacity(isHovered ? 0.9 : 0.5)
    }

    private var strokeColor: Color {
        if isSelected { return Color.accentColor.opacity(0.55) }
        return isHovered ? LucidColors.subtleBorder.opacity(1.4) : LucidColors.subtleBorder
    }

    public var body: some View {
        Button(action: action) {
            content
                .padding(LucidSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: LucidRadius.medium)
                        .fill(fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LucidRadius.medium)
                        .stroke(strokeColor, lineWidth: isSelected ? 1 : 0.5)
                )
                .shadow(color: Color.black.opacity(isHovered && !isSelected ? 0.10 : 0), radius: 6, y: 2)
                .scaleEffect(isHovered ? 1.012 : 1.0)
                .contentShape(Rectangle())
                .animation(LucidMotion.state, value: isHovered)
                .animation(LucidMotion.state, value: isSelected)
        }
        .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.985))
        .onHover { isHovered = $0 }
        .accessibilityLabel(Text(accessibilityName))
        .accessibilityHint(accessibilityHint.map { Text($0) } ?? Text(""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 12a. LucidAppearance: Maps ThemeMode to semantic AppKit NSAppearance for native vibrancy.
public enum LucidAppearance {
    public static func appearance(for theme: ThemeMode) -> NSAppearance? {
        guard let isDark = theme.explicitDarkness else { return nil }
        return NSAppearance(named: isDark ? .darkAqua : .aqua)
    }
}

/// 12b. LucidVisualEffectView: Real macOS vibrancy (NSVisualEffectView) for chrome
/// surfaces. Prefer this over `.ultraThinMaterial` for the toolbar and floating
/// panels so blur, blending, and the automatic Reduce Transparency fallback all
/// behave natively. `blendingMode` defaults to `.behindWindow` so document content
/// is genuinely visible through the glass.
public struct LucidVisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    var emphasized: Bool
    var appearance: NSAppearance?

    public init(
        material: NSVisualEffectView.Material = .headerView,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState,
        emphasized: Bool = false,
        appearance: NSAppearance? = nil
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.emphasized = emphasized
        self.appearance = appearance
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = emphasized
        view.appearance = appearance
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.isEmphasized = emphasized
        nsView.appearance = appearance
    }
}

/// 12. LucidAccentSwatch: An accent color chip with a springy hover scale and animated selection ring.
public struct LucidAccentSwatch: View {
    let hex: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    public init(hex: String, name: String, isSelected: Bool, action: @escaping () -> Void) {
        self.hex = hex
        self.name = name
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .overlay(
                    Circle()
                        .stroke(LucidColors.textPrimary, lineWidth: isSelected ? 2 : 0)
                        .padding(-3)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .contentShape(Circle())
                .animation(LucidMotion.state, value: isSelected)
                .animation(LucidMotion.press, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(name)
        .accessibilityLabel(Text("\(name) accent color"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Window Drag Area
/// Transparent drag region that forwards mouse drag to window performDrag and
/// handles titlebar double-click (zoom or minimize according to AppleActionOnDoubleClick).
public struct LucidWindowDragArea: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView { DragView() }
    public func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick")
                if action == "Minimize" {
                    window?.miniaturize(nil)
                } else if action == "Maximize" || action == "Fill" || action == "Zoom" {
                    window?.performZoom(nil)
                } else if action == "None" {
                    // System preference is None: do nothing
                } else if action == nil {
                    // System default is Zoom if unset
                    window?.performZoom(nil)
                }
                // Unrecognized action: fail safely, do nothing
                return
            }
            window?.performDrag(with: event)
        }

        override func mouseDragged(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
