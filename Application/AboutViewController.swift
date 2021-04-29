//
//  AboutViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 07/01/21.
//

import Cocoa
import WebKit

class AboutViewController: NSViewController, WKNavigationDelegate {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var versionField: NSTextField!
    @IBOutlet weak var copyrightField: NSTextField!
    @IBOutlet weak var infoWebView: WKWebView!
    
    override func viewDidLoad() {
        imageView.image = NSApplication.shared.applicationIconImage
        if let info = Bundle.main.infoDictionary {
            let version = info["CFBundleShortVersionString"] as? String ?? ""
            let build = info["CFBundleVersion"] as? String ?? ""
                
            titleField.stringValue = info["CFBundleExecutable"] as? String ?? "Syntax Highlight"
            versionField.stringValue = "Version \(version) (\(build))"
            copyrightField.stringValue = (info["NSHumanReadableCopyright"] as? String ?? "").trimmingCharacters(in: CharacterSet(charactersIn: ". ")) + " with ❤️"
        } else {
            versionField.stringValue = ""
            copyrightField.stringValue = ""
        }
        
        let fg_color = NSColor.textColor.toHexString() ?? "#000000"
        let bg_color = NSColor.textBackgroundColor.toHexString() ?? "#ffffff"
        let grid_color = NSColor.tertiaryLabelColor.toHexString() ?? "#cccccc"
        
        let font_size = NSFont.smallSystemFontSize
        let head_font_size = NSFont.systemFontSize
        
        let dos2unix: String
        if let c = Bundle.main.path(forResource: "dos2unix", ofType: nil), let ci = try? ShellTask.runTask(command: c, arguments: ["-V"]), ci.isSuccess, let s = String(data: ci.data, encoding: .utf8) {
            dos2unix = s.replacingOccurrences(of: "\n", with: "<br />\n")
        } else {
            dos2unix = ""
        }
        let info = HighlightWrapper.shared.getHighlightInfo()
        let html = """
<html>
<head>
<title>About</title>
<style type="text/css">
:root {
    --backgroundColor: \(bg_color);
    --textColor: \(fg_color);
}

html {
    padding: 0;
    margin: 0;
    -webkit-text-size-adjust: none;
    text-size-adjust: none;
    font-family: -apple-system;
    font-size: \(font_size)px;
}

td, tr, table {
    font-family: -apple-system;
    font-size: \(font_size)px;
}
table {
    width: 100%;
    border-collapse: collapse;
}
td {
    vertical-align: top;
}
td:first-child {
    min-width: 10em;
}
h2 {
    font-size: \(head_font_size)px;
    margin-top: 1.5em;
}

h2:first-child {
    margin-top: 0;
}

h2 {
    font-size: \((head_font_size+font_size) / 2)px;
}

body {
    margin: 0;
    padding: 1em;
    color: var(--textColor);
    background-color: var(--backgroundColor);
    text-align: center;
}
a {
    color: var(--textColor);
}

table tr td {
    border-bottom: 1px solid \(grid_color);
}
table tr:last-child td {
    border-bottom: none;
}
hr {
    margin-top: 12pt;
    margin-bottom: 6pt;
}
</style>
</head>
<body>
    <h2>Developer</h2>
    <a href='https://github.com/sbarex/'>sbarex</a><br />
    <a href='https://github.com/sbarex/SourceCodeSyntaxHighlight'>https://github.com/sbarex/SourceCodeSyntaxHighlight</a><br />
<hr />
\(info)
<hr />
<h2>dos2unix</h2>
\(dos2unix)
</body>
</html>
"""
        
        infoWebView.loadHTMLString(html, baseURL: nil)
        
        //self.infoTextView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.allow)
            }
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.standardWindowButton(.zoomButton)?.isHidden = true
        view.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        view.window?.titlebarAppearsTransparent = true
        if #available(OSX 11.0, *) {
            view.window?.toolbarStyle = .unifiedCompact
            view.window?.titlebarSeparatorStyle = .none
        }
        view.window?.hidesOnDeactivate = true
    }
    
    @IBAction func cancel(_ sender: Any?) {
        self.dismiss(sender)
    }
}
