import SwiftUI
import AppKit

/// Represents an open document tab in the Lucid multi-document tab bar.
public struct LucidTabItem: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var fileURL: URL?
    public var isModified: Bool

    public init(id: UUID = UUID(), title: String, fileURL: URL? = nil, isModified: Bool = false) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.isModified = isModified
    }
}

/// Lightweight editorial tab bar integrated seamlessly into the floating top chrome.
/// Hidden when only 1 document is open.
public struct TabBarView: View {
    @Binding var tabs: [LucidTabItem]
    @Binding var activeTabId: UUID?
    var onNewTab: (() -> Void)?
    var onCloseTab: ((UUID) -> Void)?
    var onSelectTab: ((UUID) -> Void)?

    @State private var hoveredTabId: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        tabs: Binding<[LucidTabItem]>,
        activeTabId: Binding<UUID?>,
        onNewTab: (() -> Void)? = nil,
        onCloseTab: ((UUID) -> Void)? = nil,
        onSelectTab: ((UUID) -> Void)? = nil
    ) {
        self._tabs = tabs
        self._activeTabId = activeTabId
        self.onNewTab = onNewTab
        self.onCloseTab = onCloseTab
        self.onSelectTab = onSelectTab
    }

    public var body: some View {
        // Strictly hidden when 1 or fewer documents are open
        if tabs.count > 1 {
            HStack(spacing: 2) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(tabs) { tab in
                            let isActive = tab.id == activeTabId
                            let isHovered = tab.id == hoveredTabId

                            tabCell(tab: tab, isActive: isActive, isHovered: isHovered)
                                .onHover { hovering in
                                    hoveredTabId = hovering ? tab.id : nil
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                if let onNewTab = onNewTab {
                    Button(action: onNewTab) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(LucidColors.textSecondary)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(LucidPressableButtonStyle(pressedScale: 0.92))
                    .help("New Tab (⌘T)")
                    .padding(.trailing, 4)
                }
            }
            .frame(height: 28)
            .background(Color.primary.opacity(0.02))
            .overlay(
                Rectangle()
                    .fill(LucidColors.subtleSeparator.opacity(0.3))
                    .frame(height: 0.5),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func tabCell(tab: LucidTabItem, isActive: Bool, isHovered: Bool) -> some View {
        HStack(spacing: 6) {
            if tab.isModified {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
            }

            Text(tab.title)
                .font(.system(size: 11.5, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? LucidColors.textPrimary : LucidColors.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if isHovered || isActive {
                Button(action: {
                    onCloseTab?(tab.id)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(LucidColors.textSecondary.opacity(0.8))
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("Close Tab (⌘W)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    isActive
                        ? Color(nsColor: .textColor).opacity(0.09)
                        : (isHovered ? Color.primary.opacity(0.04) : Color.clear)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            activeTabId = tab.id
            onSelectTab?(tab.id)
        }
    }
}
