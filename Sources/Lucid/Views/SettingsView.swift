import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var preferences: LucidPreferences
    @ObservedObject var updateController: LucidUpdateController

    @MainActor
    public init(preferences: LucidPreferences = .shared, updateController: LucidUpdateController? = nil) {
        self.preferences = preferences
        self.updateController = updateController ?? .shared
    }

    public var body: some View {
        TabView {
            GeneralSettingsTab(preferences: preferences)
                .tabItem { Label("General", systemImage: "gearshape") }

            AppearanceSettingsTab(preferences: preferences)
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            EditorSettingsTab(preferences: preferences)
                .tabItem { Label("Editor", systemImage: "pencil") }

            PreviewSettingsTab(preferences: preferences)
                .tabItem { Label("Preview", systemImage: "book") }

            STEMSettingsTab(preferences: preferences)
                .tabItem { Label("STEM & Math", systemImage: "atom") }

            ShortcutsSettingsTab()
                .tabItem { Label("Shortcuts", systemImage: "command") }

            UpdatesSettingsTab(updateController: updateController)
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }

            AdvancedSettingsTab(preferences: preferences)
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .padding(LucidSpacing.xLarge)
        .frame(width: 680, height: 600)
    }
}

// MARK: - 1. General Settings Tab
struct GeneralSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                // Presets Section
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Workflow Presets",
                        subtitle: "Curated starting configurations tailored for focused writing styles."
                    )

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: LucidSpacing.small), GridItem(.flexible(), spacing: LucidSpacing.small)], spacing: LucidSpacing.small) {
                        ForEach(LucidPreset.allCases) { preset in
                            LucidSelectableCard(action: {
                                withAnimation(LucidMotion.state) { preferences.applyPreset(preset) }
                            }) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset.displayName)
                                        .font(LucidTypography.labelMedium)
                                        .foregroundColor(LucidColors.textPrimary)

                                    Text(preset.description)
                                        .font(LucidTypography.caption)
                                        .foregroundColor(LucidColors.textSecondary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }

                LucidDivider()

                // Default View Mode
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(title: "Default Canvas")

                    LucidSettingRow(
                        title: "Startup View Mode",
                        description: "The default presentation mode when opening a document."
                    ) {
                        Picker("", selection: $preferences.viewMode) {
                            ForEach(ViewMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Startup View Mode")
                        .fixedSize()
                    }

                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 2. Appearance Settings Tab
struct AppearanceSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    let curatedThemes: [(ThemeMode, String, Color, Color)] = [
        (.dark, "Studio Dark", Color(hex: "#171717"), Color(hex: "#ffffff")),
        (.light, "Editorial Light", Color(hex: "#ffffff"), Color(hex: "#171717")),
        (.sepia, "Warm Book Sepia", Color(hex: "#fcf8f2"), Color(hex: "#382d22")),
        (.system, "System Dynamic", Color(nsColor: NSColor.windowBackgroundColor), Color(nsColor: NSColor.labelColor))
    ]

    let accentPresets = [
        ("#2f81f7", "Lucid Blue"),
        ("#8250df", "Purple"),
        ("#1a7f37", "Green"),
        ("#bf8700", "Gold"),
        ("#cf222e", "Red"),
        ("#0891b2", "Teal"),
        ("#8b949e", "Graphite")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                // Theme Selection
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Themes",
                        subtitle: "Calibrated color appearances designed for extended writing."
                    )

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: LucidSpacing.small), GridItem(.flexible(), spacing: LucidSpacing.small)], spacing: LucidSpacing.small) {
                        ForEach(curatedThemes, id: \.0) { mode, name, bg, fg in
                            let isSelected = preferences.theme == mode
                            LucidSelectableCard(isSelected: isSelected, action: {
                                withAnimation(LucidMotion.state) { preferences.theme = mode }
                            }) {
                                HStack(spacing: LucidSpacing.medium) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: LucidRadius.micro)
                                            .fill(bg)
                                            .frame(width: 32, height: 22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: LucidRadius.micro)
                                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                                            )
                                        Circle()
                                            .fill(fg)
                                            .frame(width: 6, height: 6)
                                    }

                                    Text(name)
                                        .font(LucidTypography.labelMedium)
                                        .foregroundColor(LucidColors.textPrimary)
                                        .lineLimit(1)

                                    Spacer(minLength: LucidSpacing.small)

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 13))
                                        .opacity(isSelected ? 1 : 0)
                                        .scaleEffect(isSelected ? 1 : 0.6)
                                }
                            }
                        }
                    }
                }

                LucidDivider()

                // Accent Color
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(title: "Accent Color")

                    HStack(spacing: LucidSpacing.large) {
                        ForEach(accentPresets, id: \.0) { hex, name in
                            LucidAccentSwatch(
                                hex: hex,
                                name: name,
                                isSelected: preferences.accentColor == hex
                            ) {
                                withAnimation(LucidMotion.state) { preferences.accentColor = hex }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                LucidDivider()

                // Interface Density
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(title: "Interface Density")

                    LucidSettingRow(
                        title: "Spacing & Density",
                        description: "Adjust padding and row heights across sidebar, toolbar, and status bar."
                    ) {
                        Picker("", selection: $preferences.density) {
                            ForEach(InterfaceDensity.allCases) { d in
                                Text(d.displayName).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Spacing & Density")
                        .fixedSize()
                    }
                }

                LucidDivider()

                HStack {
                    Spacer()
                    LucidTextButton("Reset Appearance to Defaults", systemImage: "arrow.counterclockwise") {
                        withAnimation(LucidMotion.state) { preferences.resetAppearance() }
                    }
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 3. Editor Settings Tab
struct EditorSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                // Typography Section
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Typography",
                        subtitle: "Font family and size applied to both the editor and preview."
                    )

                    VStack(alignment: .leading, spacing: LucidSpacing.small) {
                        Text("Font Family")
                            .font(LucidTypography.label)
                            .foregroundColor(LucidColors.textSecondary)

                        Picker("Font Family", selection: $preferences.fontFamily) {
                            ForEach(FontFamily.allCases) { family in
                                Text(family.displayName).tag(family)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        if preferences.fontFamily == .custom {
                            TextField("Custom Font Name (e.g. Fira Code)", text: $preferences.customFontName)
                                .textFieldStyle(.roundedBorder)
                                .font(LucidTypography.label)
                        }
                    }

                    // Font Size Slider
                    VStack(alignment: .leading, spacing: LucidSpacing.xSmall) {
                        HStack {
                            Text("Font Size")
                                .font(LucidTypography.label)
                                .foregroundColor(LucidColors.textSecondary)
                            Spacer()
                            Text("\(Int(preferences.fontSize)) pt")
                                .font(LucidTypography.metadata)
                                .foregroundColor(LucidColors.textPrimary)
                        }
                        Slider(value: $preferences.fontSize, in: LucidPreferences.Limits.fontSizeRange, step: LucidPreferences.Limits.fontSizeStep)
                            .accessibilityLabel("Font Size")
                    }

                    // Line Height Slider
                    VStack(alignment: .leading, spacing: LucidSpacing.xSmall) {
                        HStack {
                            Text("Line Height")
                                .font(LucidTypography.label)
                                .foregroundColor(LucidColors.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f", preferences.lineHeight))
                                .font(LucidTypography.metadata)
                                .foregroundColor(LucidColors.textPrimary)
                        }
                        Slider(value: $preferences.lineHeight, in: LucidPreferences.Limits.lineHeightRange, step: LucidPreferences.Limits.lineHeightStep)
                            .accessibilityLabel("Line Height")
                    }
                }

                LucidDivider()

                // Editing Behavior
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(title: "Behavior & Visuals")

                    LucidSettingRow(title: "Line Numbers Gutter", description: "Display line numbers along the left edge.") {
                        Toggle("", isOn: $preferences.lineNumbers)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Line Numbers Gutter")
                    }

                    LucidSettingRow(title: "Highlight Active Line", description: "Apply a subtle luminance lift to the current cursor line.") {
                        Toggle("", isOn: $preferences.highlightCurrentLine)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Highlight Active Line")
                    }

                    LucidSettingRow(title: "Auto-Pair Delimiters", description: "Automatically insert closing brackets, quotes, and backticks.") {
                        Toggle("", isOn: $preferences.autoPairDelimiters)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Auto-Pair Delimiters")
                    }

                    LucidSettingRow(title: "Auto-Indent on Return", description: "Maintain leading indentation and list markers when pressing Return.") {
                        Toggle("", isOn: $preferences.autoIndent)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Auto-Indent on Return")
                    }

                    LucidSettingRow(title: "Soft Word Wrap", description: "Wrap long lines at the editor viewport edge.") {
                        Toggle("", isOn: $preferences.wordWrap)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Soft Word Wrap")
                    }
                }

                LucidDivider()

                HStack {
                    Spacer()
                    LucidTextButton("Reset Editor to Defaults", systemImage: "arrow.counterclockwise") {
                        withAnimation(LucidMotion.state) { preferences.resetEditor() }
                    }
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 4. Preview Settings Tab
struct PreviewSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                // Layout & Reading Width
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Reading Canvas",
                        subtitle: "Comfortable prose measure and breakout behavior."
                    )

                    LucidSettingRow(title: "Column Width") {
                        Picker("", selection: $preferences.contentWidth) {
                            ForEach(ContentWidth.allCases) { w in
                                Text(w.displayName).tag(w)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Column Width")
                        .frame(width: 260)
                    }

                    LucidSettingRow(
                        title: "Signature Breakout Layout",
                        description: "Prose remains centered at 720px while wide code blocks, tables, and diagrams expand to the full canvas."
                    ) {
                        Toggle("", isOn: $preferences.breakoutEnabled)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Signature Breakout Layout")
                    }

                    LucidSettingRow(title: "Table Density") {
                        Picker("", selection: $preferences.tableDensity) {
                            ForEach(TableDensity.allCases) { d in
                                Text(d.displayName).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Table Density")
                        .fixedSize()
                    }
                }

                LucidDivider()

                // Diagram & Math Scaling
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(title: "Visual Scales")

                    LucidSettingRow(title: "Math Scale") {
                        HStack(spacing: LucidSpacing.small) {
                            Slider(value: $preferences.mathScale, in: LucidPreferences.Limits.mathScaleRange, step: LucidPreferences.Limits.mathScaleStep)
                                .accessibilityLabel("Math Scale")
                                .frame(width: 160)
                            Text(String(format: "%.1f×", preferences.mathScale))
                                .font(LucidTypography.metadata)
                                .foregroundColor(LucidColors.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }

                    LucidSettingRow(title: "Mermaid Scale") {
                        HStack(spacing: LucidSpacing.small) {
                            Slider(value: $preferences.mermaidScale, in: LucidPreferences.Limits.mermaidScaleRange, step: LucidPreferences.Limits.mermaidScaleStep)
                                .accessibilityLabel("Mermaid Scale")
                                .frame(width: 160)
                            Text(String(format: "%.1f×", preferences.mermaidScale))
                                .font(LucidTypography.metadata)
                                .foregroundColor(LucidColors.textSecondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }

                LucidDivider()

                HStack {
                    Spacer()
                    LucidTextButton("Reset Preview to Defaults", systemImage: "arrow.counterclockwise") {
                        withAnimation(LucidMotion.state) { preferences.resetPreview() }
                    }
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 5. STEM & Science Tab
struct STEMSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                LucidSectionHeader(
                    title: "Technical Rendering Engines",
                    subtitle: "Built-in KaTeX, chemical notation, and Mermaid diagram engines."
                )

                LucidSettingRow(
                    title: "KaTeX Mathematics & Physics",
                    description: "Renders differential equations, Dirac bra-ket notation, and matrices."
                ) {
                    Toggle("", isOn: $preferences.enableKaTeX)
                        .toggleStyle(.switch)
                        .accessibilityLabel("KaTeX Mathematics & Physics")
                }

                LucidSettingRow(
                    title: "Chemistry Notation (mhchem)",
                    description: "Chemical stoichiometry, reaction equilibrium arrows, and electrochemistry."
                ) {
                    Toggle("", isOn: $preferences.enableMhchem)
                        .toggleStyle(.switch)
                        .accessibilityLabel("Chemistry Notation (mhchem)")
                        .disabled(!preferences.enableKaTeX)
                }

                LucidSettingRow(
                    title: "Mermaid Diagrams",
                    description: "Hardware architectures, control feedback loops, sequence and state diagrams."
                ) {
                    Toggle("", isOn: $preferences.enableMermaid)
                        .toggleStyle(.switch)
                        .accessibilityLabel("Mermaid Diagrams")
                }

                LucidSettingRow(
                    title: "Syntax Highlighting",
                    description: "Software and hardware language highlighting (Python, C++, Rust, MATLAB, Verilog)."
                ) {
                    Toggle("", isOn: $preferences.enableSyntaxHighlighting)
                        .toggleStyle(.switch)
                        .accessibilityLabel("Syntax Highlighting")
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 6. Shortcuts Settings Tab
struct ShortcutsSettingsTab: View {
    @State private var filter: String = ""
    let commands = LucidCommandRegistry.shared.commands.values.sorted { $0.title < $1.title }

    private var filteredCommands: [LucidCommandMetadata] {
        if filter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return commands
        }
        let q = filter.lowercased()
        return commands.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                LucidSectionHeader(
                    title: "Keyboard Shortcuts",
                    subtitle: "Standard macOS shortcuts configured across the application."
                )

                LucidSearchField(placeholder: "Filter shortcuts…", text: $filter, height: 28, fontSize: 12)

                LazyVStack(spacing: 2) {
                    ForEach(filteredCommands) { cmd in
                        HStack(spacing: LucidSpacing.medium) {
                            Image(systemName: cmd.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(LucidColors.textSecondary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(cmd.title)
                                    .font(LucidTypography.label)
                                    .foregroundColor(LucidColors.textPrimary)
                                Text(cmd.subtitle)
                                    .font(LucidTypography.caption)
                                    .foregroundColor(LucidColors.textSecondary)
                            }

                            Spacer()

                            if let shortcutStr = cmd.shortcutDisplayString {
                                LucidShortcutBadge(shortcutStr)
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, LucidSpacing.small)
                    }
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

// MARK: - 7. Advanced Settings Tab
struct AdvancedSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences
    @State private var showingResetConfirmation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: LucidSpacing.medium) {
            HStack {
                LucidSectionHeader(
                    title: "Custom CSS Injection",
                    subtitle: "Scoped exclusively to the rendered preview document."
                )
                Spacer()

                if !preferences.customCSS.isEmpty {
                    LucidTextButton("Clear CSS", systemImage: "xmark") {
                        preferences.customCSS = ""
                    }
                }
            }

            TextEditor(text: $preferences.customCSS)
                .font(LucidTypography.monoCode)
                .padding(LucidSpacing.small)
                .background(Color(nsColor: NSColor.textBackgroundColor))
                .cornerRadius(LucidRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: LucidRadius.small)
                        .stroke(LucidColors.subtleBorder, lineWidth: 0.5)
                )

            LucidDivider()

            HStack {
                LucidTextButton("Reset All Preferences…", systemImage: "arrow.counterclockwise", role: .destructive) {
                    showingResetConfirmation = true
                }
                .confirmationDialog(
                    "Reset All Preferences",
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset All Preferences", role: .destructive) {
                        withAnimation(LucidMotion.state) { preferences.resetAll() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to reset all preferences to their default values? This action cannot be undone.")
                }

                Spacer()
            }
        }
        .padding(LucidSpacing.small)
    }
}

// MARK: - 8. Updates Settings Tab
struct UpdatesSettingsTab: View {
    @ObservedObject var updateController: LucidUpdateController

    private var formattedLastCheckDate: String {
        guard let date = updateController.lastUpdateCheckDate else {
            return "Never"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LucidSpacing.sectionSpacing) {
                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Software Updates",
                        subtitle: "Keep Lucid up to date with the latest features, performance improvements, and security enhancements."
                    )

                    if updateController.isMountedFromDiskImage {
                        HStack(alignment: .top, spacing: LucidSpacing.medium) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Running from Disk Image")
                                    .font(LucidTypography.label)
                                    .foregroundColor(LucidColors.textPrimary)
                                Text("Lucid is currently running from a mounted disk image. To enable in-app updates, drag Lucid.app to your Applications folder.")
                                    .font(LucidTypography.caption)
                                    .foregroundColor(LucidColors.textSecondary)
                            }
                        }
                        .padding(LucidSpacing.medium)
                        .background(LucidColors.elevatedSurface)
                        .cornerRadius(LucidRadius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: LucidRadius.small)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Version information
                    LucidSettingRow(
                        title: "Current Version",
                        description: "Installed build: \(updateController.currentBuild)"
                    ) {
                        Text("Lucid \(updateController.currentVersion)")
                            .font(LucidTypography.labelMedium)
                            .foregroundColor(LucidColors.textPrimary)
                    }

                    LucidSettingRow(
                        title: "Last Checked",
                        description: "Time of the most recent update check"
                    ) {
                        Text(formattedLastCheckDate)
                            .font(LucidTypography.metadata)
                            .foregroundColor(LucidColors.textSecondary)
                    }

                    LucidSettingRow(
                        title: "Check for Updates",
                        description: "Manually check the production update feed now."
                    ) {
                        Button("Check for Updates…") {
                            updateController.checkForUpdates()
                        }
                        .disabled(!updateController.canCheckForUpdates)
                    }
                }

                LucidDivider()

                VStack(alignment: .leading, spacing: LucidSpacing.medium) {
                    LucidSectionHeader(
                        title: "Automatic Updates",
                        subtitle: "Configure background update scheduling and download preferences."
                    )

                    LucidSettingRow(
                        title: "Automatically check for updates",
                        description: "Periodically check the update feed in the background."
                    ) {
                        Toggle("", isOn: Binding(
                            get: { updateController.automaticallyChecksForUpdates },
                            set: { updateController.automaticallyChecksForUpdates = $0 }
                        ))
                        .toggleStyle(.switch)
                        .accessibilityLabel("Automatically check for updates")
                    }

                    LucidSettingRow(
                        title: "Automatically download updates",
                        description: "Download updates in the background and notify when ready to install."
                    ) {
                        Toggle("", isOn: Binding(
                            get: { updateController.automaticallyDownloadsUpdates },
                            set: { updateController.automaticallyDownloadsUpdates = $0 }
                        ))
                        .toggleStyle(.switch)
                        .accessibilityLabel("Automatically download updates")
                        .disabled(!updateController.automaticallyChecksForUpdates)
                    }
                }
            }
            .padding(LucidSpacing.small)
        }
    }
}

