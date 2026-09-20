import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    public init(preferences: LucidPreferences = .shared) {
        self.preferences = preferences
    }

    public var body: some View {
        TabView {
            GeneralSettingsView(preferences: preferences)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            TypographySettingsView(preferences: preferences)
                .tabItem {
                    Label("Typography", systemImage: "textformat")
                }

            InteractionSettingsView(preferences: preferences)
                .tabItem {
                    Label("Writing & Modes", systemImage: "pencil.and.outline")
                }

            CustomCSSSettingsView(preferences: preferences)
                .tabItem {
                    Label("Custom CSS", systemImage: "chevron.left.forwardslash.chevron.right")
                }

            STEMSettingsView()
                .tabItem {
                    Label("STEM & Science", systemImage: "atom")
                }
        }
        .frame(width: 560, height: 460)
        .padding(20)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    let accentPresets = [
        ("#2f81f7", "Lucid Blue"),
        ("#8250df", "Purple"),
        ("#1a7f37", "Green"),
        ("#bf8700", "Gold"),
        ("#cf222e", "Red"),
        ("#0891b2", "Teal"),
        ("#d946ef", "Pink")
    ]

    var body: some View {
        Form {
            Section {
                Picker("Theme:", selection: $preferences.theme) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Accent Color:")
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(accentPresets, id: \.0) { hex, name in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: preferences.accentColor == hex ? 2 : 0)
                                        .padding(-2)
                                )
                                .onTapGesture {
                                    preferences.accentColor = hex
                                }
                                .help(name)
                        }
                    }
                }

                Picker("Column Width:", selection: $preferences.contentWidth) {
                    ForEach(ContentWidth.allCases) { width in
                        Text(width.displayName).tag(width)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Signature Breakout Layout", isOn: $preferences.breakoutEnabled)
                    .help("Allows tables, code blocks, and diagrams to expand gracefully 32px beyond the reading column.")
            }
        }
        .padding(20)
    }
}

// MARK: - Typography Settings with All System Fonts
struct TypographySettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    private var availableSystemFonts: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    var body: some View {
        Form {
            Section {
                Picker("Font Family:", selection: $preferences.fontFamily) {
                    ForEach(FontFamily.allCases) { font in
                        Text(font.displayName).tag(font)
                    }
                }
                .pickerStyle(.segmented)

                if preferences.fontFamily == .custom {
                    Picker("Select System Font:", selection: $preferences.customFontName) {
                        ForEach(availableSystemFonts, id: \.self) { fontName in
                            Text(fontName).tag(fontName)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Font Size:")
                        Spacer()
                        Text("\(Int(preferences.fontSize)) px")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $preferences.fontSize, in: 13...28, step: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Line Height:")
                        Spacer()
                        Text(String(format: "%.2f", preferences.lineHeight))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $preferences.lineHeight, in: 1.3...2.4, step: 0.05)
                }
            }

            Section("Preview Sample") {
                Text("Lucid Studio Typography: The quick brown fox jumps over the lazy dog. 1234567890.")
                    .font(previewFont)
                    .lineSpacing(CGFloat((preferences.lineHeight - 1.0) * preferences.fontSize))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
            }
        }
        .padding(20)
    }

    private var previewFont: Font {
        switch preferences.fontFamily {
        case .sans: return .system(size: CGFloat(preferences.fontSize))
        case .serif: return .custom("New York", size: CGFloat(preferences.fontSize))
        case .mono: return .system(size: CGFloat(preferences.fontSize), design: .monospaced)
        case .custom: return .custom(preferences.customFontName, size: CGFloat(preferences.fontSize))
        }
    }
}

// MARK: - Interaction Settings (Focus & Typewriter)
struct InteractionSettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        Form {
            Section("Editing Modes") {
                Toggle("Click-to-Edit in Reading View", isOn: $preferences.clickToEdit)
                    .help("Allows clicking directly on text, headings, paragraphs, and tables while reading to edit them on the go.")

                Toggle("Focus Mode (⌘⇧D)", isOn: $preferences.focusMode)
                    .help("Dims non-active paragraphs to 25% opacity so you can concentrate exclusively on the current paragraph.")

                Toggle("Typewriter Mode (⌘⇧T)", isOn: $preferences.typewriterMode)
                    .help("Keeps the line you are currently typing on vertically centered on the screen.")
            }

            Section("File & Clipboard") {
                Toggle("Live External File Watching", isOn: .constant(true))
                    .disabled(true)
                Text("Automatically refreshes when modified by external editors (VS Code, Neovim, Obsidian).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Direct Clipboard Image Pasting (⌘V)", isOn: .constant(true))
                    .disabled(true)
                Text("Paste screenshots directly from clipboard as inline images.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - Custom CSS Settings
struct CustomCSSSettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Inject Custom CSS")
                .font(.headline)

            Text("Write custom CSS rules to fine-tune every aspect of the typography, layout, or colors. Applied live instantly.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $preferences.customCSS)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

            HStack {
                Button("Insert Sample: Gradient Headings") {
                    preferences.customCSS += "\nh1 { background: linear-gradient(90deg, #2f81f7, #a371f7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }\n"
                }
                .font(.caption)

                Button("Insert Sample: Rounded Images") {
                    preferences.customCSS += "\nimg { border-radius: 16px; border: 2px solid rgba(255,255,255,0.1); }\n"
                }
                .font(.caption)

                Spacer()

                if !preferences.customCSS.isEmpty {
                    Button("Clear") {
                        preferences.customCSS = ""
                    }
                    .font(.caption)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - STEM Settings
struct STEMSettingsView: View {
    var body: some View {
        Form {
            Section {
                Toggle("Chemistry Formulas (\\ce{...} via mhchem)", isOn: .constant(true))
                    .disabled(true)
                Text("Renders stoichiometry, reaction equilibrium arrows (<=>), oxidation numbers, and battery electrochemistry.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("KaTeX Advanced Mathematics & Physics", isOn: .constant(true))
                    .disabled(true)
                Text("Supports AMS environments (align*, bmatrix, cases), Dirac notation, and vector calculus.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Mermaid Architecture & Control Diagrams", isOn: .constant(true))
                    .disabled(true)
                Text("Interactive block diagrams, sequence timing charts, state machines, and flowcharts.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
}
