import SwiftUI

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
                    Label("Editor & Reading", systemImage: "pencil.and.outline")
                }

            STEMSettingsView()
                .tabItem {
                    Label("STEM & Science", systemImage: "atom")
                }
        }
        .frame(width: 520, height: 420)
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

                Toggle("Enable Breakout Layout", isOn: $preferences.breakoutEnabled)
                    .help("Allows wide code blocks, tables, and diagrams to expand gracefully beyond the reading column.")
            }
        }
        .padding(20)
    }
}

// MARK: - Typography Settings
struct TypographySettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        Form {
            Section {
                Picker("Font Family:", selection: $preferences.fontFamily) {
                    ForEach(FontFamily.allCases) { font in
                        Text(font.displayName).tag(font)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Font Size:")
                        Spacer()
                        Text("\(Int(preferences.fontSize)) px")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $preferences.fontSize, in: 13...26, step: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Line Height:")
                        Spacer()
                        Text(String(format: "%.2f", preferences.lineHeight))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $preferences.lineHeight, in: 1.3...2.2, step: 0.05)
                }
            }

            Section("Preview Sample") {
                Text("Lucid is designed for pure focus. The quick brown fox jumps over the lazy dog. 1234567890.")
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
        }
    }
}

// MARK: - Interaction Settings
struct InteractionSettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        Form {
            Section {
                Toggle("Click-to-Edit in Reading View", isOn: $preferences.clickToEdit)
                    .help("Allows clicking directly on text, headings, paragraphs, and tables while reading to edit them on the go.")

                Text("When enabled, you can click on any paragraph, heading, bullet point, or table cell while reading to make instant edits without opening the split editor.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Toggle("Live External File Watching", isOn: .constant(true))
                    .disabled(true)
                Text("Automatically refreshes your view when the document is saved by external editors (VS Code, Neovim, Obsidian).")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
