import AppKit
import WebKit
import UniformTypeIdentifiers

@MainActor
public final class ExportService {
    public static let shared = ExportService()

    private init() {}

    public func exportPDF(webView: WKWebView, defaultFilename: String = "Document") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(defaultFilename).pdf"
        savePanel.title = "Export as PDF"

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else { return }

            let config = WKPDFConfiguration()
            webView.createPDF(configuration: config) { result in
                switch result {
                case .success(let data):
                    do {
                        try data.write(to: targetURL)
                        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                    } catch {
                        Self.showErrorAlert(message: "Failed to save PDF: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    Self.showErrorAlert(message: "Failed to generate PDF: \(error.localizedDescription)")
                }
            }
        }
    }

    public func exportHTML(webView: WKWebView, defaultFilename: String = "Document") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(defaultFilename).html"
        savePanel.title = "Export as Standalone HTML"

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else { return }

            webView.evaluateJavaScript("window.lucid.getStandaloneHTML()") { result, error in
                if let htmlString = result as? String, let data = htmlString.data(using: .utf8) {
                    do {
                        try data.write(to: targetURL)
                        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                    } catch {
                        Self.showErrorAlert(message: "Failed to save HTML: \(error.localizedDescription)")
                    }
                } else if let error = error {
                    Self.showErrorAlert(message: "Failed to generate HTML: \(error.localizedDescription)")
                }
            }
        }
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
