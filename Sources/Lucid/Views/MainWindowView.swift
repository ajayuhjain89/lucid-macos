import SwiftUI
import WebKit

public struct MainWindowView: View {
    @Binding var document: LucidDocument
    var fileURL: URL?

    @StateObject private var preferences = LucidPreferences.shared
    @State private var headings: [HeadingItem] = []
    @State private var scrollToHeadingId: String?
    @State private var editorScrollFraction: Double = 0
    @State private var previewTargetFraction: Double?
    @State private var webViewInstance: WKWebView?
    @State private var fileWatcher: FileWatcher?

    // Stats
    private var wordCount: Int {
        let words = document.text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    private var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    public init(document: Binding<LucidDocument>, fileURL: URL? = nil) {
        self._document = document
        self.fileURL = fileURL
    }

    public var body: some View {
        HSplitView {
            // Outline Sidebar
            if preferences.showOutline {
                OutlineSidebarView(headings: headings) { id in
                    scrollToHeadingId = id
                }
                .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
            }

            // Main Content Area
            Group {
                switch preferences.viewMode {
                case .reader:
                    PreviewWebView(
                        preferences: preferences,
                        markdown: document.text,
                        headings: $headings,
                        scrollToHeadingId: scrollToHeadingId,
                        webViewInstance: $webViewInstance
                    )
                case .split:
                    HSplitView {
                        EditorView(
                            text: $document.text,
                            onScrollFractionChanged: { fraction in
                                previewTargetFraction = fraction
                            }
                        )
                        .frame(minWidth: 260)

                        PreviewWebView(
                            preferences: preferences,
                            markdown: document.text,
                            headings: $headings,
                            scrollToHeadingId: scrollToHeadingId,
                            targetScrollFraction: previewTargetFraction,
                            webViewInstance: $webViewInstance
                        )
                        .frame(minWidth: 260)
                    }
                case .editor:
                    EditorView(text: $document.text)
                }
            }
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

            // Inspector Sidebar
            if preferences.showInspector {
                InspectorView(preferences: preferences)
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            }
        }
        .toolbar {
            // Outline Toggle
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation { preferences.showOutline.toggle() }
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Outline (Table of Contents)")
            }

            // View Mode Selector
            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $preferences.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Document Stats
            ToolbarItem(placement: .status) {
                Text("\(wordCount) words · \(readingTimeMinutes) min read")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Export Menu
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportPDF(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    }) {
                        Label("Export as PDF…", systemImage: "arrow.down.doc")
                    }

                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.exportHTML(
                                webView: webView,
                                defaultFilename: fileURL?.deletingPathExtension().lastPathComponent ?? "Document"
                            )
                        }
                    }) {
                        Label("Export Standalone HTML…", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Divider()

                    Button(action: {
                        if let webView = webViewInstance {
                            ExportService.shared.copyRichText(webView: webView)
                        }
                    }) {
                        Label("Copy Formatted Rich Text", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export Document")
            }

            // Inspector Toggle
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation { preferences.showInspector.toggle() }
                }) {
                    Image(systemName: "slider.horizontal.3")
                }
                .help("Toggle Inspector")
            }
        }
        .onAppear {
            setupFileWatcher()
        }
    }

    private func setupFileWatcher() {
        guard let url = fileURL else { return }
        fileWatcher = FileWatcher(url: url) {
            if let updatedText = try? String(contentsOf: url, encoding: .utf8),
               updatedText != document.text {
                DispatchQueue.main.async {
                    self.document.text = updatedText
                }
            }
        }
    }
}
