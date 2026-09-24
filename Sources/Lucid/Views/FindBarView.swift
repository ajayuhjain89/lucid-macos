import SwiftUI

public struct FindBarView: View {
    @Binding var isPresented: Bool
    @Binding var query: String
    @Binding var matchCount: Int
    @Binding var currentIndex: Int
    var onPerformFind: (String) -> Void
    var onFindNext: () -> Void
    var onFindPrev: () -> Void
    var onDismiss: () -> Void
    @FocusState private var isFieldFocused: Bool

    public init(
        isPresented: Binding<Bool>,
        query: Binding<String>,
        matchCount: Binding<Int>,
        currentIndex: Binding<Int>,
        onPerformFind: @escaping (String) -> Void,
        onFindNext: @escaping () -> Void,
        onFindPrev: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self._query = query
        self._matchCount = matchCount
        self._currentIndex = currentIndex
        self.onPerformFind = onPerformFind
        self.onFindNext = onFindNext
        self.onFindPrev = onFindPrev
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: LucidSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LucidColors.textSecondary)
                .font(.system(size: 12, weight: .medium))

            TextField("Find in document…", text: $query)
                .textFieldStyle(.plain)
                .font(LucidTypography.label)
                .focused($isFieldFocused)
                .frame(width: 190)
                .onChange(of: query) { _, newQuery in
                    onPerformFind(newQuery)
                }
                .onSubmit {
                    onFindNext()
                }

            if !query.isEmpty {
                Text(matchCount > 0 ? "\(currentIndex) of \(matchCount)" : "No matches")
                    .font(LucidTypography.metadata)
                    .foregroundColor(matchCount > 0 ? LucidColors.textSecondary : LucidColors.warning)
                    .padding(.horizontal, 2)

                LucidIconButton(
                    icon: "chevron.up",
                    size: 22,
                    iconSize: 10,
                    helpText: "Previous Match",
                    shortcutText: "⇧⌘G"
                ) {
                    onFindPrev()
                }
                .disabled(matchCount == 0)

                LucidIconButton(
                    icon: "chevron.down",
                    size: 22,
                    iconSize: 10,
                    helpText: "Next Match",
                    shortcutText: "⌘G"
                ) {
                    onFindNext()
                }
                .disabled(matchCount == 0)
            }

            LucidIconButton(
                icon: "xmark",
                size: 22,
                iconSize: 10,
                helpText: "Close",
                shortcutText: "Esc"
            ) {
                closeFind()
            }
        }
        .padding(.horizontal, LucidSpacing.medium)
        .padding(.vertical, LucidSpacing.xSmall)
        .background(
            LucidVisualEffectView(material: .menu, blendingMode: .withinWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: LucidRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: LucidRadius.medium)
                .stroke(LucidColors.subtleBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .onAppear {
            // Focusing synchronously in onAppear loses to the editor, which is
            // still first responder; take focus on the next run-loop turn.
            DispatchQueue.main.async { isFieldFocused = true }
            if !query.isEmpty {
                onPerformFind(query)
            }
        }
        .onExitCommand {
            closeFind()
        }
        .onKeyPress(.escape) {
            closeFind()
            return .handled
        }
    }

    private func closeFind() {
        isPresented = false
        onDismiss()
    }
}
