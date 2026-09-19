import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var preferences: LucidPreferences

    public init(preferences: LucidPreferences = .shared) {
        self.preferences = preferences
    }

    public var body: some View {
        TabView {
            AppearanceSettingsTab(preferences: preferences)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette.fill")
                }

            TypographySettingsTab(preferences: preferences)
                .tabItem {
                    Label("Typography", systemImage: "textformat.size")
                }

            WritingSettingsTab(preferences: preferences)
                .tabItem {
                    Label("Writing & Modes", systemImage: "pencil.and.outline")
                }

            CustomCSSSettingsTab(preferences: preferences)
                .tabItem {
                    Label("Custom CSS", systemImage: "curlybraces")
                }

            STEMSettingsTab()
                .tabItem {
                    Label("STEM & Science", systemImage: "atom")
                }
        }
        .frame(width: 640, height: 530)
        .padding(16)
    }
}

// MARK: - 1. Appearance Settings Tab
struct AppearanceSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    let themes: [(ThemeMode, String, Color, Color)] = [
        (.dark, "Studio Dark", Color(hex: "#171717"), Color(hex: "#ffffff")),
        (.light, "Pure Light", Color(hex: "#ffffff"), Color(hex: "#171717")),
        (.sepia, "Warm Sepia", Color(hex: "#fbf0d9"), Color(hex: "#433422")),
        (.oled, "OLED Black", Color(hex: "#000000"), Color(hex: "#ffffff")),
        (.nord, "Nord Arctic", Color(hex: "#2e3440"), Color(hex: "#88c0d0")),
        (.dracula, "Dracula", Color(hex: "#282a36"), Color(hex: "#bd93f9"))
    ]

    let accentPresets = [
        ("#2f81f7", "Lucid Blue"),
        ("#8250df", "Purple"),
        ("#1a7f37", "Green"),
        ("#bf8700", "Gold"),
        ("#cf222e", "Red"),
        ("#0891b2", "Teal"),
        ("#d946ef", "Pink"),
        ("#8b949e", "Graphite")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Theme Selection Cards
                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 10) {
                        ForEach(themes, id: \.0) { mode, name, bg, fg in
                            Button(action: { preferences.theme = mode }) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(bg)
                                            .frame(width: 32, height: 24)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        Circle()
                                            .fill(fg)
                                            .frame(width: 8, height: 8)
                                    }

                                    Text(name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if preferences.theme == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(preferences.theme == mode ? Color.accentColor.opacity(0.14) : Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(preferences.theme == mode ? Color.accentColor : Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // Accent Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accent Color")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 12) {
                        ForEach(accentPresets, id: \.0) { hex, name in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: preferences.accentColor == hex ? 2.5 : 0)
                                        .shadow(radius: 2)
                                )
                                .onTapGesture {
                                    preferences.accentColor = hex
                                }
                                .help(name)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                // Reading Measure & Layout
                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout & Reading Width")
                        .font(.system(size: 13, weight: .semibold))

                    HStack {
                        Text("Reading Column Width")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $preferences.contentWidth) {
                            ForEach(ContentWidth.allCases) { width in
                                Text(width.displayName).tag(width)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }

                    Toggle(isOn: $preferences.breakoutEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signature Breakout Layout")
                                .font(.system(size: 12, weight: .medium))
                            Text("Prose remains centered at 720px for optimal readability, while tables, code, and diagrams expand into the full 1040px canvas.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - 2. Typography Settings Tab
struct TypographySettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    private var availableSystemFonts: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Font Family Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Family")
                        .font(.system(size: 13, weight: .semibold))

                    Picker("", selection: $preferences.fontFamily) {
                        Text("SF Pro (System Sans)").tag(FontFamily.sans)
                        Text("New York (Editorial Serif)").tag(FontFamily.serif)
                        Text("SF Mono (Code)").tag(FontFamily.mono)
                        Text("Custom System Font…").tag(FontFamily.custom)
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 320)

                    if preferences.fontFamily == .custom {
                        HStack {
                            Text("Installed Font:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Picker("", selection: $preferences.customFontName) {
                                ForEach(availableSystemFonts, id: \.self) { fontName in
                                    Text(fontName).tag(fontName)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 240)
                        }
                        .padding(.top, 4)
                    }
                }

                Divider()

                // Font Size Slider with Presets
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Base Font Size")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(Int(preferences.fontSize)) px")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .cornerRadius(4)
                    }

                    Slider(value: $preferences.fontSize, in: 13...28, step: 1)

                    HStack(spacing: 8) {
                        ForEach([14, 16, 18, 20, 22], id: \.self) { size in
                            let isSelected = Int(preferences.fontSize) == size
                            Button("\(size)px\(size == 18 ? " (Default)" : "")") {
                                preferences.fontSize = Double(size)
                            }
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .accentColor : .primary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color(NSColor.controlBackgroundColor))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // Line Height Slider with Presets
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Line Height (Leading)")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(String(format: "%.2f", preferences.lineHeight))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .cornerRadius(4)
                    }

                    Slider(value: $preferences.lineHeight, in: 1.3...2.4, step: 0.05)

                    HStack(spacing: 8) {
                        ForEach([(1.50, "1.50 (Compact)"), (1.65, "1.65"), (1.75, "1.75 (Default)"), (2.00, "2.00 (Relaxed)")], id: \.0) { val, label in
                            let isSelected = abs(preferences.lineHeight - val) < 0.02
                            Button(label) {
                                preferences.lineHeight = val
                            }
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .accentColor : .primary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color(NSColor.controlBackgroundColor))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()

                // Live Document Preview Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Preview")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Why Is It Called “MPU6050”?")
                            .font(.system(size: CGFloat(preferences.fontSize * 1.3), weight: .bold))
                            .foregroundColor(.white)

                        Text("The MPU6050 combines motion sensing functions in one device. Accelerations along X, Y, Z and angular rate ω are sampled at high frequency.")
                            .font(previewFont)
                            .lineSpacing(CGFloat((preferences.lineHeight - 1.0) * preferences.fontSize))
                            .foregroundColor(Color(hex: "#e6e6e6"))

                        HStack(spacing: 6) {
                            Text("MPU = Motion Processing Unit")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#2f81f7"))
                            Text("·")
                                .foregroundColor(.secondary)
                            Text("i2c_read(0x68)")
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 4)
                                .background(Color(hex: "#2a2a2a"))
                                .foregroundColor(Color(hex: "#ffb4b4"))
                                .cornerRadius(3)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#171717"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#343a43"), lineWidth: 1)
                    )
                }
            }
            .padding(16)
        }
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

// MARK: - 3. Writing & Modes Tab
struct WritingSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Editing & Writing Modes")
                    .font(.system(size: 13, weight: .semibold))

                // In-Place Live Editing
                ToggleRow(
                    title: "Click-to-Edit in Reader Mode",
                    subtitle: "Click directly on any paragraph, heading, list item, or table to edit in-place without switching modes. Serializes instantly to Markdown.",
                    badge: "Live",
                    isOn: $preferences.clickToEdit
                )

                Divider()

                // Focus Mode
                ToggleRow(
                    title: "Focus Mode (⌘⇧D)",
                    subtitle: "Dims non-active paragraphs to 25% opacity so you can concentrate exclusively on the current paragraph.",
                    badge: "⌘⇧D",
                    isOn: $preferences.focusMode
                )

                Divider()

                // Typewriter Mode
                ToggleRow(
                    title: "Typewriter Mode (⌘⇧T)",
                    subtitle: "Dynamically auto-scrolls the active typing line to the vertical center of the window, keeping your eye level consistent.",
                    badge: "⌘⇧T",
                    isOn: $preferences.typewriterMode
                )

                Divider()

                // File Watching & Clipboard
                Text("Automation & Clipboard")
                    .font(.system(size: 13, weight: .semibold))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live External File Watching")
                            .font(.system(size: 12, weight: .medium))
                        Text("Monitors file changes on disk and automatically reloads when saved by external tools (VS Code, Obsidian, Neovim).")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Direct Clipboard Image Pasting (⌘V)")
                            .font(.system(size: 12, weight: .medium))
                        Text("Paste screenshots directly from clipboard. Automatically saved into assets/ and referenced in Markdown.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - 4. Custom CSS Tab
struct CustomCSSSettingsTab: View {
    @ObservedObject var preferences: LucidPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom CSS Injection")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Write custom CSS rules to fine-tune typography, layouts, or colors. Applied live instantly.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()

                if !preferences.customCSS.isEmpty {
                    Button("Reset CSS") {
                        preferences.customCSS = ""
                    }
                    .font(.system(size: 11))
                }
            }

            TextEditor(text: $preferences.customCSS)
                .font(.system(size: 12, design: .monospaced))
                .padding(8)
                .background(Color(hex: "#171717"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#343a43"), lineWidth: 1)
                )

            HStack(spacing: 8) {
                Text("Insert Snippet:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button("+ Gradient Headings") {
                    preferences.customCSS += "\nh1 { background: linear-gradient(90deg, #2f81f7, #a371f7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }\n"
                }
                .font(.system(size: 10))

                Button("+ Rounded Images") {
                    preferences.customCSS += "\nimg { border-radius: 14px; border: 2px solid rgba(255,255,255,0.1); }\n"
                }
                .font(.system(size: 10))

                Button("+ Glass Callouts") {
                    preferences.customCSS += "\nblockquote.markdown-alert { backdrop-filter: blur(12px); border-radius: 12px; }\n"
                }
                .font(.system(size: 10))
            }
        }
        .padding(16)
    }
}

// MARK: - 5. STEM & Science Tab
struct STEMSettingsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("STEM Engines & Acceleration")
                    .font(.system(size: 13, weight: .semibold))

                STEMFeatureCard(
                    title: "KaTeX Mathematics & Physics",
                    subtitle: "Fast TeX rendering supporting AMS environments (align*, bmatrix), Dirac bra-ket notation, and vector calculus.",
                    sample: "$$\\oint_{\\partial \\Sigma} \\mathbf{B} \\cdot d\\boldsymbol{\\ell} = \\mu_0 I_{\\text{enc}} + \\mu_0 \\varepsilon_0 \\frac{d\\Phi_E}{dt}$$"
                )

                STEMFeatureCard(
                    title: "Chemistry Notation (\\ce{...} via mhchem)",
                    subtitle: "Chemical stoichiometry, reaction equilibrium arrows (<=>), precipitate arrows (v), and battery electrochemistry.",
                    sample: "$$\\ce{2H2 + O2 -> 2H2O} \\quad \\ce{Fe^{2+} + e- <=> Fe^{3+}}$$"
                )

                STEMFeatureCard(
                    title: "Mermaid Engineering Diagrams",
                    subtitle: "Hardware architecture charts, control feedback loops, state transitions, and sequence timing diagrams.",
                    sample: "flowchart LR\n  ESP32 --> TB6612FNG --> Motor --> Encoder --> ESP32"
                )
            }
            .padding(16)
        }
    }
}

// MARK: - Reusable UI Components
struct ToggleRow: View {
    let title: String
    let subtitle: String
    let badge: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}

struct STEMFeatureCard: View {
    let title: String
    let subtitle: String
    let sample: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
            }

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(sample)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(hex: "#8b949e"))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#171717"))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
