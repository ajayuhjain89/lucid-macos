import SwiftUI
import WebKit

public struct FindBarView: View {
    @Binding var isPresented: Bool
    var webView: WKWebView?
    @State private var query: String = ""
    @State private var matchCount: Int = 0
    @State private var currentIndex: Int = 0
    @FocusState private var isFieldFocused: Bool

    public init(isPresented: Binding<Bool>, webView: WKWebView?) {
        self._isPresented = isPresented
        self.webView = webView
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
                    performFind(newQuery)
                }
                .onSubmit {
                    findNext()
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
                    findPrev()
                }
                .disabled(matchCount == 0)

                LucidIconButton(
                    icon: "chevron.down",
                    size: 22,
                    iconSize: 10,
                    helpText: "Next Match",
                    shortcutText: "⌘G"
                ) {
                    findNext()
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
            isFieldFocused = true
        }
        .onDisappear {
            clearFind()
        }
    }

    private func performFind(_ text: String) {
        guard let webView = webView else { return }
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("window.lucid.find('\(escaped)')")
    }

    private func findNext() {
        webView?.evaluateJavaScript("window.lucid.findNext()")
    }

    private func findPrev() {
        webView?.evaluateJavaScript("window.lucid.findPrev()")
    }

    private func closeFind() {
        clearFind()
        isPresented = false
    }

    private func clearFind() {
        webView?.evaluateJavaScript("window.lucid.clearFind()")
        query = ""
        matchCount = 0
        currentIndex = 0
    }

    // Called via message handler from JS
    public func updateMatchStats(count: Int, index: Int) {
        self.matchCount = count
        self.currentIndex = index
    }
}
