import SwiftUI
import AppKit

/// A compact, native, minimal tab strip matching Lucid's design system.
///
/// Remains completely hidden when only 1 tab is open, preserving single-document simplicity.
/// Seamlessly appears when 2 or more tabs are open.
public struct TabBarView: View {
    @ObservedObject var documentManager: WindowDocumentManager
    @ObservedObject var preferences: LucidPreferences

    @State private var hoveredTabID: UUID? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(documentManager: WindowDocumentManager, preferences: LucidPreferences = .shared) {
        self.documentManager = documentManager
        self.preferences = preferences
    }

    public var body: some View {
        if documentManager.sessions.count > 1 {
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(documentManager.sessions) { session in
                            tabItem(for: session)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                }

                // New tab button
                Button(action: {
                    documentManager.newTab()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textSecondary))
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.92))
                .help("New Tab (⌘T)")
                .accessibilityLabel("New Tab")

                // Open file button
                Button(action: {
                    documentManager.promptOpenFile()
                }) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: preferences.theme.themeTokens.textSecondary))
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.92))
                .help("Open File… (⌘O)")
                .accessibilityLabel("Open File")
                .padding(.trailing, 8)
            }
            .frame(height: 28)
            .background(
                Color(hex: preferences.theme.themeTokens.windowBackground)
                    .overlay(
                        Divider().opacity(0.3),
                        alignment: .bottom
                    )
            )
            .contextMenu {
                Button("New Tab") {
                    documentManager.newTab()
                }
                Button("Open File…") {
                    documentManager.promptOpenFile()
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func tabItem(for session: DocumentSession) -> some View {
        let isActive = session.id == documentManager.activeSessionID
        let isHovered = hoveredTabID == session.id

        return HStack(spacing: 6) {
            // Document title
            Text(displayName(for: session))
                .font(.system(size: 11.5, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color(hex: preferences.theme.themeTokens.textPrimary) : Color(hex: preferences.theme.themeTokens.textSecondary))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(minWidth: 50, maxWidth: 160, alignment: .leading)

            // Dirty indicator or close button
            if session.isDirty && !isHovered {
                Circle()
                    .fill(Color(hex: preferences.accentColor))
                    .frame(width: 6, height: 6)
                    .frame(width: 14, height: 14)
                    .help("Unsaved changes")
                    .accessibilityLabel("Unsaved changes")
            } else {
                Button(action: {
                    documentManager.closeTab(id: session.id) { _ in }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(isActive || isHovered ? Color(hex: preferences.theme.themeTokens.textSecondary) : Color.clear)
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity((isActive || isHovered) ? 1.0 : 0.0)
                .help("Close Tab")
                .accessibilityLabel("Close \(session.displayName)")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive
                      ? Color(hex: preferences.theme.themeTokens.textPrimary).opacity(0.08)
                      : (isHovered ? Color(hex: preferences.theme.themeTokens.textPrimary).opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            documentManager.selectTab(id: session.id)
        }
        .onHover { isHovered in
            if isHovered {
                hoveredTabID = session.id
            } else if hoveredTabID == session.id {
                hoveredTabID = nil
            }
        }
        .contextMenu {
            Button("Close Tab") {
                documentManager.closeTab(id: session.id) { _ in }
            }
            Divider()
            Button("New Tab") {
                documentManager.newTab()
            }
            Button("Open File…") {
                documentManager.promptOpenFile()
            }
        }
        .help(session.fileURL?.path ?? session.displayName)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.displayName)\(session.isDirty ? ", edited" : "")")
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : [.isButton])
    }

    private func displayName(for session: DocumentSession) -> String {
        let name = session.displayName
        let duplicates = documentManager.sessions.filter { $0.displayName == name }
        if duplicates.count > 1, let url = session.fileURL {
            let parent = url.deletingLastPathComponent().lastPathComponent
            if !parent.isEmpty && parent != "/" {
                return "\(name) — \(parent)"
            }
        }
        return name
    }
}
