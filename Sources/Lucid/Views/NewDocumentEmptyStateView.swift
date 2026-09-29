import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A welcoming empty-state card displayed on pristine untitled tabs or empty windows,
/// providing clear, immediate affordances to open existing markdown documents or start writing.
public struct NewDocumentEmptyStateView: View {
    @ObservedObject var preferences: LucidPreferences
    var onOpen: () -> Void
    var onStartWriting: () -> Void
    var onOpenRecent: (URL) -> Void

    @ObservedObject private var recentDocs = RecentDocumentsManager.shared
    @State private var isDropTargeted = false

    public init(
        preferences: LucidPreferences = .shared,
        onOpen: @escaping () -> Void,
        onStartWriting: @escaping () -> Void,
        onOpenRecent: @escaping (URL) -> Void
    ) {
        self.preferences = preferences
        self.onOpen = onOpen
        self.onStartWriting = onStartWriting
        self.onOpenRecent = onOpenRecent
    }

    public var body: some View {
        VStack(spacing: LucidSpacing.large) {
            Spacer()

            VStack(spacing: LucidSpacing.medium) {
                // Subtle icon badge
                ZStack {
                    Circle()
                        .fill(Color(hex: preferences.accentColor).opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: "doc.text")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: preferences.accentColor))
                }

                VStack(spacing: LucidSpacing.xxxSmall) {
                    Text("New Markdown Document")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textPrimary))

                    Text("Start writing or open an existing Markdown file")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textSecondary))
                }
            }

            // Primary actions
            HStack(spacing: LucidSpacing.medium) {
                Button(action: onOpen) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Open File…")
                            .font(.system(size: 12.5, weight: .medium))
                        Text("⌘O")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .opacity(0.7)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: LucidRadius.small)
                            .fill(Color(hex: preferences.accentColor))
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.96))
                .help("Open existing Markdown file (⌘O)")

                Button(action: onStartWriting) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Start Writing")
                            .font(.system(size: 12.5, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: LucidRadius.small)
                            .fill(Color(hex: preferences.theme.themeTokens.textPrimary).opacity(0.08))
                    )
                    .foregroundColor(Color(hex: preferences.theme.themeTokens.textPrimary))
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.96))
                .help("Switch to Editor mode and start typing")
            }

            // Recents list if available
            if !recentDocs.recentURLs.isEmpty {
                VStack(alignment: .leading, spacing: LucidSpacing.xSmall) {
                    Text("Recent Documents")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textTertiary))
                        .padding(.horizontal, 4)

                    VStack(spacing: 2) {
                        ForEach(recentDocs.recentURLs.prefix(4), id: \.self) { url in
                            Button(action: { onOpenRecent(url) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textSecondary))
                                    Text(recentDocs.displayName(for: url))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textPrimary))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: LucidRadius.xSmall)
                                        .fill(Color(hex: preferences.theme.themeTokens.textPrimary).opacity(0.04))
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.98))
                            .help(url.path)
                        }
                    }
                }
                .frame(maxWidth: 320)
                .padding(.top, LucidSpacing.small)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onStartWriting()
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url else { return }
                DispatchQueue.main.async {
                    onOpenRecent(url)
                }
            }
            return true
        }
        .overlay(
            RoundedRectangle(cornerRadius: LucidRadius.medium)
                .stroke(Color(hex: preferences.accentColor), lineWidth: 2)
                .opacity(isDropTargeted ? 0.6 : 0)
                .padding(LucidSpacing.medium)
        )
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { press in
            guard !press.characters.isEmpty else { return .ignored }
            if press.modifiers.contains(.command) || press.modifiers.contains(.control) {
                return .ignored
            }
            onStartWriting()
            return .ignored
        }
    }
}
