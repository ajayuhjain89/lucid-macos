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
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Find in document…", text: $query)
                .textFieldStyle(.plain)
                .focused($isFieldFocused)
                .frame(width: 180)
                .onChange(of: query) { _, newQuery in
                    performFind(newQuery)
                }
                .onSubmit {
                    findNext()
                }

            if !query.isEmpty {
                Text(matchCount > 0 ? "\(currentIndex) of \(matchCount)" : "No matches")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(matchCount > 0 ? .secondary : .red)
                    .padding(.horizontal, 4)

                Button(action: findPrev) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .disabled(matchCount == 0)
                .help("Previous Match (⇧⌘G)")
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button(action: findNext) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.plain)
                .disabled(matchCount == 0)
                .help("Next Match (⌘G)")
                .keyboardShortcut("g", modifiers: .command)
            }

            Button(action: closeFind) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
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
