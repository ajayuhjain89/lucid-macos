import AppKit
import WebKit
import UniformTypeIdentifiers

@MainActor
public final class ExportService {
    public static let shared = ExportService()

    private init() {}

    /// Exports the document as a paginated PDF, typeset with the preview's
    /// print styles on a light page. Works in every view mode: the document is
    /// rendered in its own offscreen page, not taken from the on-screen preview.
    public func exportPDF(markdown: String, documentURL: URL?, preferences: LucidPreferences, defaultFilename: String = "Document") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(defaultFilename).pdf"
        savePanel.title = "Export as PDF"

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else { return }
            Task { @MainActor in
                let renderer = OffscreenDocumentRenderer(documentDirectory: documentURL?.deletingLastPathComponent())
                do {
                    try await renderer.render(markdown: markdown, preferencesJSON: Self.preferencesJSON(preferences, forceLightTheme: true))
                    _ = try await renderer.evaluate("window.lucid.prepareForExport(); true")
                    try await renderer.printPDF(to: targetURL)
                    NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                } catch {
                    Self.showErrorAlert(message: "Failed to export PDF: \(error.localizedDescription)")
                }
                renderer.close()
            }
        }
    }

    /// Exports a self-contained HTML file: styles inlined, local images and (when
    /// the document has math) KaTeX fonts embedded, no scripts or app toolbars.
    public func exportHTML(markdown: String, documentURL: URL?, preferences: LucidPreferences, defaultFilename: String = "Document") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(defaultFilename).html"
        savePanel.title = "Export as Standalone HTML"

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else { return }
            Task { @MainActor in
                let documentDirectory = documentURL?.deletingLastPathComponent()
                let renderer = OffscreenDocumentRenderer(documentDirectory: documentDirectory)
                do {
                    try await renderer.render(markdown: markdown, preferencesJSON: Self.preferencesJSON(preferences, forceLightTheme: false))
                    guard let json = try await renderer.evaluate("window.lucid.prepareForExport()") as? String,
                          let parts = try? JSONDecoder().decode(ExportParts.self, from: Data(json.utf8)) else {
                        throw ExportError.renderFailed
                    }
                    let html = StandaloneHTMLBuilder.build(parts: parts, title: defaultFilename, documentDirectory: documentDirectory)
                    try Data(html.utf8).write(to: targetURL)
                    NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                } catch {
                    Self.showErrorAlert(message: "Failed to export HTML: \(error.localizedDescription)")
                }
                renderer.close()
            }
        }
    }

    /// The preview preference payload for an export: Focus/Typewriter off, and the
    /// theme optionally forced to light (PDF pages are white, so diagrams and code
    /// must use light colors).
    private static func preferencesJSON(_ preferences: LucidPreferences, forceLightTheme: Bool) -> String {
        let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let json = preferences.jsonPayload(systemColorScheme: isDark ? .dark : .light, focusMode: false)
        guard var dict = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] else { return json }
        // An export is the whole document: never dimmed or caret-centered.
        dict["typewriterMode"] = false
        if forceLightTheme { dict["theme"] = "light" }
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let light = String(data: data, encoding: .utf8) else { return json }
        return light
    }

    public func exportSVG(svgString: String, defaultFilename: String = "diagram") {
        let savePanel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            savePanel.allowedContentTypes = [svgType]
        }
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(defaultFilename).svg"
        savePanel.title = "Export SVG"

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else { return }
            do {
                try svgString.write(to: targetURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([targetURL])
            } catch {
                Self.showErrorAlert(message: "Failed to save SVG: \(error.localizedDescription)")
            }
        }
    }

    public func copyRichText(webView: WKWebView) {
        webView.evaluateJavaScript("""
            (function() {
                const content = document.getElementById('lucid-content');
                if (!content) return '';
                const range = document.createRange();
                range.selectNodeContents(content);
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
                document.execCommand('copy');
                selection.removeAllRanges();
                return 'copied';
            })()
        """) { _, _ in }
    }

    private static func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

enum ExportError: LocalizedError {
    case engineMissing, timedOut, renderFailed, printFailed

    var errorDescription: String? {
        switch self {
        case .engineMissing: return "The preview engine is missing from the app bundle."
        case .timedOut: return "The document took too long to render."
        case .renderFailed: return "The document could not be rendered."
        case .printFailed: return "The PDF could not be created."
        }
    }
}

struct ExportParts: Decodable {
    let htmlAttrs: [[String]]
    let bodyAttrs: [[String]]
    let content: String
}

/// Renders a document in its own offscreen web view (the same engine as the
/// preview), independent of the window's view mode and on-screen state.
@MainActor
final class OffscreenDocumentRenderer: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    private let window: NSWindow
    private let webView: WKWebView
    private var readyContinuation: CheckedContinuation<Void, Error>?
    private var isReady = false

    init(documentDirectory: URL?) {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(
            LocalAssetSchemeHandler { documentDirectory },
            forURLScheme: LocalAssetSchemeHandler.scheme
        )
        let userContent = WKUserContentController()
        config.userContentController = userContent
        // US Letter width at 96 dpi; print pagination re-flows to the paper size.
        let frame = NSRect(x: 0, y: 0, width: 816, height: 1056)
        webView = WKWebView(frame: frame, configuration: config)
        window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isExcludedFromWindowsMenu = true
        window.contentView = webView
        super.init()
        webView.navigationDelegate = self
        let handler = WeakScriptMessageHandler(self)
        for name in PreviewWebView.messageHandlerNames {
            userContent.add(handler, name: name)
        }
    }

    func close() {
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.navigationDelegate = nil
        window.contentView = nil
        window.close()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "lucidReady", !isReady else { return }
        isReady = true
        readyContinuation?.resume()
        readyContinuation = nil
    }

    func evaluate(_ script: String) async throws -> Any? {
        try await webView.evaluateJavaScript(script)
    }

    /// Loads the engine, applies preferences and renders `markdown`, then waits
    /// (up to ~30 s) until math, diagrams and images have finished.
    func render(markdown: String, preferencesJSON: String) async throws {
        guard let indexURL = PreviewWebView.engineIndexURL else { throw ExportError.engineMissing }
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            if isReady { continuation.resume() } else { readyContinuation = continuation }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                guard let self, let pending = self.readyContinuation else { return }
                self.readyContinuation = nil
                pending.resume(throwing: ExportError.timedOut)
            }
        }
        let markdownLiteral = String(data: try JSONEncoder().encode(markdown), encoding: .utf8) ?? "\"\""
        _ = try await evaluate("window.lucid.updatePreferences(\(preferencesJSON)); true")
        _ = try await evaluate("window.lucid.updateContent(\(markdownLiteral), 'export'); true")
        for _ in 0..<300 {
            if (try? await evaluate("window.lucid.isExportReady()")) as? Bool == true { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// Prints the rendered page to a paginated PDF at `url`.
    func printPDF(to url: URL) async throws {
        let printInfo = (NSPrintInfo.shared.copy() as? NSPrintInfo) ?? NSPrintInfo()
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.topMargin = 54
        printInfo.bottomMargin = 54
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54

        let operation = webView.printOperation(with: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        // WKWebView's print view has no size until given one; without it pages come out blank.
        operation.view?.frame = webView.bounds
        let succeeded = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let delegate = PrintCompletion { continuation.resume(returning: $0) }
            operation.runModal(
                for: window,
                delegate: delegate,
                didRun: #selector(PrintCompletion.printOperationDidRun(_:success:contextInfo:)),
                contextInfo: Unmanaged.passRetained(delegate).toOpaque()
            )
        }
        guard succeeded, FileManager.default.fileExists(atPath: url.path) else { throw ExportError.printFailed }
    }
}

/// Bridges NSPrintOperation's selector-based completion to a closure.
private final class PrintCompletion: NSObject {
    private let completion: (Bool) -> Void

    init(_ completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }

    @objc func printOperationDidRun(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        if let contextInfo { Unmanaged<PrintCompletion>.fromOpaque(contextInfo).release() }
        completion(success)
    }
}

/// Assembles the exported page: inlined engine styles, embedded local images and
/// KaTeX fonts, and the rendered content, with no scripts.
enum StandaloneHTMLBuilder {
    static func build(parts: ExportParts, title: String, documentDirectory: URL?) -> String {
        let engine = PreviewWebView.engineIndexURL?.deletingLastPathComponent()
        func read(_ path: String) -> String {
            guard let engine else { return "" }
            return (try? String(contentsOf: engine.appendingPathComponent(path), encoding: .utf8)) ?? ""
        }
        var css = read("markdown-preview.css") + "\n" + read("highlight/highlight.min.css")
        if parts.content.contains("class=\"katex") {
            css = embedKaTeXFonts(read("katex/katex.min.css"), fontsDirectory: engine?.appendingPathComponent("katex/fonts")) + "\n" + css
        }
        let content = embedLocalImages(parts.content, documentDirectory: documentDirectory)
        return """
        <!DOCTYPE html>
        <html \(attributes(parts.htmlAttrs))>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(escape(title))</title>
        <style>
        \(css)
        </style>
        </head>
        <body \(attributes(parts.bodyAttrs))>
        \(content)
        </body>
        </html>

        """
    }

    private static func attributes(_ pairs: [[String]]) -> String {
        pairs.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return "\(pair[0])=\"\(escape(pair[1]))\""
        }.joined(separator: " ")
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Replaces each `lucid-asset:` image source with a data: URI of the file.
    static func embedLocalImages(_ html: String, documentDirectory: URL?) -> String {
        guard let regex = try? NSRegularExpression(pattern: "src=\"(lucid-asset:[^\"]+)\"") else { return html }
        let ns = html as NSString
        var result = ""
        var last = 0
        for match in regex.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let urlString = ns.substring(with: match.range(at: 1))
            var replacement = ns.substring(with: match.range)
            if let url = URL(string: urlString),
               let file = LocalAssetSchemeHandler.resolve(url, documentDirectory: documentDirectory),
               let type = UTType(filenameExtension: file.pathExtension), type.conforms(to: .image),
               let mime = type.preferredMIMEType,
               let data = try? Data(contentsOf: file) {
                replacement = "src=\"data:\(mime);base64,\(data.base64EncodedString())\""
            }
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last)) + replacement
            last = NSMaxRange(match.range)
        }
        return result + ns.substring(from: last)
    }

    /// Points each KaTeX @font-face at an embedded WOFF2 data: URI.
    static func embedKaTeXFonts(_ css: String, fontsDirectory: URL?) -> String {
        guard let fontsDirectory,
              let regex = try? NSRegularExpression(pattern: "src:url\\(fonts/([A-Za-z0-9_-]+)\\.woff2\\) format\\(\"woff2\"\\)(,url\\([^)]*\\) format\\(\"[a-z]+\"\\))*") else { return css }
        let ns = css as NSString
        var result = ""
        var last = 0
        for match in regex.matches(in: css, range: NSRange(location: 0, length: ns.length)) {
            let name = ns.substring(with: match.range(at: 1))
            var replacement = ns.substring(with: match.range)
            if let data = try? Data(contentsOf: fontsDirectory.appendingPathComponent("\(name).woff2")) {
                replacement = "src:url(data:font/woff2;base64,\(data.base64EncodedString())) format(\"woff2\")"
            }
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last)) + replacement
            last = NSMaxRange(match.range)
        }
        return result + ns.substring(from: last)
    }
}

