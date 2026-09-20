import SwiftUI

public struct StatusBarView: View {
    @ObservedObject var preferences: LucidPreferences
    let wordCount: Int
    let charCount: Int
    let readingTimeMinutes: Int
    let cursorLine: Int
    let cursorCol: Int
    var onOpenSettings: () -> Void

    public init(
        preferences: LucidPreferences,
        wordCount: Int,
        charCount: Int,
        readingTimeMinutes: Int,
        cursorLine: Int = 1,
        cursorCol: Int = 1,
        onOpenSettings: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.wordCount = wordCount
        self.charCount = charCount
        self.readingTimeMinutes = readingTimeMinutes
        self.cursorLine = cursorLine
        self.cursorCol = cursorCol
        self.onOpenSettings = onOpenSettings
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public var body: some View {
        HStack(spacing: LucidSpacing.medium) {
            // Metrics group
            HStack(spacing: LucidSpacing.small) {
                if preferences.statusWordCount {
                    Text("\(formatNumber(wordCount)) words")
                        .font(.system(size: 11.5, weight: .regular, design: .default).monospacedDigit())
                }

                if preferences.statusCharCount {
                    if preferences.statusWordCount {
                        Text("·").foregroundColor(LucidColors.textTertiary)
                    }
                    Text("\(formatNumber(charCount)) characters")
                        .font(.system(size: 11.5, weight: .regular, design: .default).monospacedDigit())
                }

                if preferences.statusReadingTime {
                    if preferences.statusWordCount || preferences.statusCharCount {
                        Text("·").foregroundColor(LucidColors.textTertiary)
                    }
                    Text("\(readingTimeMinutes) min read")
                        .font(.system(size: 11.5, weight: .regular, design: .default).monospacedDigit())
                }

                if preferences.statusLineCol {
                    if preferences.statusWordCount || preferences.statusCharCount || preferences.statusReadingTime {
                        Text("·").foregroundColor(LucidColors.textTertiary)
                    }
                    Text("Ln \(cursorLine), Col \(cursorCol)")
                        .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                }
            }
            .foregroundColor(LucidColors.textSecondary)

            Spacer()

            // Trailing quiet affordance
            LucidIconButton(
                icon: "slider.horizontal.3",
                size: 22,
                iconSize: 11,
                helpText: "Preferences",
                shortcutText: "⌘,"
            ) {
                onOpenSettings()
            }
        }
        .padding(.horizontal, LucidSpacing.large)
        .frame(height: preferences.density.statusBarHeight)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        // A barely-there hairline instead of a hard band, so the status area reads
        // as a quiet continuation of the canvas rather than a separate stripe.
        .overlay(
            Rectangle()
                .fill(LucidColors.subtleSeparator.opacity(0.5))
                .frame(height: 0.5),
            alignment: .top
        )
        .contextMenu {
            Text("Status Bar Items")
            Divider()
            Toggle("Word Count", isOn: $preferences.statusWordCount)
            Toggle("Reading Time", isOn: $preferences.statusReadingTime)
            Toggle("Character Count", isOn: $preferences.statusCharCount)
            Toggle("Line & Column", isOn: $preferences.statusLineCol)
            Divider()
            Button("Hide Status Bar") {
                preferences.showStatusBar = false
            }
            Button("Customize in Settings…") {
                onOpenSettings()
            }
        }
    }
}
