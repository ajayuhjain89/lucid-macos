import SwiftUI

public struct InspectorView: View {
    @ObservedObject var preferences: LucidPreferences

    let accentPresets = [
        ("#0969da", "Blue"),
        ("#8250df", "Purple"),
        ("#1a7f37", "Green"),
        ("#bf8700", "Gold"),
        ("#cf222e", "Red"),
        ("#0891b2", "Teal"),
        ("#d946ef", "Pink")
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section: Theme
                VStack(alignment: .leading, spacing: 8) {
                    Label("Theme", systemImage: "circle.lefthalf.filled")
                        .font(.headline)

                    Picker("Theme", selection: $preferences.theme) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // Section: Typography
                VStack(alignment: .leading, spacing: 14) {
                    Label("Typography", systemImage: "textformat")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font Family")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Font Family", selection: $preferences.fontFamily) {
                            ForEach(FontFamily.allCases) { font in
                                Text(font.displayName).tag(font)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Font Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(preferences.fontSize)) px")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $preferences.fontSize, in: 13...24, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Line Height")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f", preferences.lineHeight))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $preferences.lineHeight, in: 1.3...2.2, step: 0.05)
                    }
                }

                Divider()

                // Section: Layout
                VStack(alignment: .leading, spacing: 14) {
                    Label("Layout", systemImage: "rectangle.arrowtriangle.2.outward")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading Column Width")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Reading Column Width", selection: $preferences.contentWidth) {
                            ForEach(ContentWidth.allCases) { width in
                                Text(width.displayName).tag(width)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle("Breakout Layout", isOn: $preferences.breakoutEnabled)
                        .help("Allows wide code blocks, tables, and diagrams to expand gracefully beyond the reading column.")
                }

                Divider()

                // Section: Accent Color
                VStack(alignment: .leading, spacing: 8) {
                    Label("Accent Color", systemImage: "paintpalette")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(accentPresets, id: \.0) { hex, name in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 22, height: 22)
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
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 240, idealWidth: 270)
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
