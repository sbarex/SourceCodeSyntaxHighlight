//
//  ViewController.swift
//  SourceCodeSyntaxHighlight
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import WebKit
import SourceCodeSyntaxHighlightXPCService

class ViewController: NSViewController {
    var webView: WKWebView?
    var textScrollView: NSScrollView?
    var textView: NSTextView?
    
    @IBOutlet var progressIndicatorView: NSProgressIndicator!
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    deinit {
        self.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    func load(url: URL) {
        self.webView?.loadHTMLString("", baseURL: nil)
        self.webView?.isHidden = true
        self.textView?.string = ""
        self.textScrollView?.isHidden = true

        self.representedObject = url
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var representedObject: Any? {
        didSet {
            refresh(nil)
        }
    }

    @IBAction func refresh(_ sender: Any?) {
        guard let documentUrl = self.representedObject as? URL else {
            return
        }
        
        self.progressIndicatorView.startAnimation(self)
        
        webView?.isHidden = true
        textScrollView?.isHidden = true
        
        service?.colorize(url: documentUrl, overrideSettings: nil) { (response, settings, error) in
            let format = settings[SCSHSettings.Key.format.rawValue] as? String ?? SCSHFormat.html.rawValue
            if format == "rtf" {
                DispatchQueue.main.async {
                    if self.textScrollView == nil {
                        self.textScrollView = NSScrollView(frame: self.view.bounds)
                        self.textScrollView!.autoresizingMask = [.height, .width]
                        self.textScrollView!.hasHorizontalScroller = true
                        self.textScrollView!.hasVerticalScroller = true
                        self.textScrollView!.borderType = .noBorder
                        self.view.addSubview(self.textScrollView!)
                    }
                    if self.textView == nil {
                        self.textView = NSTextView(frame: CGRect(origin: .zero, size: self.textScrollView!.contentSize))
                        
                        //self.textView!.minSize = CGSize(width: 0, height: 0)
                        self.textView!.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                        self.textView!.isVerticallyResizable = true
                        self.textView!.isHorizontallyResizable = true
                        self.textView!.autoresizingMask = []
                        self.textView!.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                        self.textView!.textContainer?.widthTracksTextView = false
                        self.textView!.textContainer?.heightTracksTextView = false
                        
                        self.textView!.isEditable = false
                        self.textView!.isSelectable = true
                        
                        self.textView!.isGrammarCheckingEnabled = false
                        
                        self.textView!.backgroundColor = .clear
                        self.textView!.drawsBackground = true
                        self.textView!.allowsDocumentBackgroundColorChange = true
                        self.textView!.usesFontPanel = false
                        self.textView!.usesRuler = false
                        self.textView!.usesInspectorBar = false
                        self.textView!.allowsImageEditing = false
                        
                        self.textScrollView!.documentView = self.textView!
                    }
                    
                    let text: NSAttributedString
                    if let e = error {
                        text = NSAttributedString(string: e.localizedDescription)
                    } else {
                        text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Errore di conversione")
                    }
                    
                    self.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
                    self.webView?.removeFromSuperview()
                    self.webView = nil
                    
                    self.textView?.textStorage?.setAttributedString(text)
                    // The rtf parser don't apply (why?) the page packground.
                    if let c = settings[SCSHSettings.Key.rtfBackgroundColor.rawValue] as? String, let color = NSColor(fromHexString: c) {
                        self.textView?.backgroundColor = color
                    } else {
                        self.textView?.backgroundColor = .clear
                    }
                    
                    self.progressIndicatorView.stopAnimation(self)
                    self.textScrollView?.isHidden = false
                    
                    self.view.window?.makeFirstResponder(self.textView!)
                }
            } else {
                let html: String
                if let _ = error {
                    if let e = error as? SCSHError {
                        switch e {
                        case .shellError(let cmd, let exitCode, let stdOut, let stdErr, let message):
                            var s = ""
                            if let m = message, m.count > 0 {
                                s += "<b>\(m)</b><br />"
                            } else {
                                s += "<b>Shell error!</b><br />"
                            }
                            s += "<code>\(cmd)</code><br />exitCode: \(exitCode)<br />"
                            if stdOut.count > 0 {
                               s += "<pre>\(stdOut)</pre>"
                            }
                            if stdErr.count > 0 {
                               s += "<pre style='color: red'>\(stdErr)<pre>"
                            }
                            html = s
                        default:
                            html = e.localizedDescription.replacingOccurrences(of: "\n", with: "<br />\n")
                        }
                    } else {
                        html = "unknown error (\(error!))"
                    }
                } else {
                    html = response.decodeToString().trimmingCharacters(in: CharacterSet.newlines)
                }
                
                DispatchQueue.main.async {
                    if self.webView == nil {
                        let preferences = WKPreferences()
                        preferences.javaScriptEnabled = false

                        // Create a configuration for the preferences
                        let configuration = WKWebViewConfiguration()
                        configuration.preferences = preferences
                        configuration.allowsAirPlayForMediaPlayback = false
                        
                        self.webView = WKWebView(frame: self.view.bounds, configuration: configuration)
                        self.webView!.autoresizingMask = [.height, .width]
                        
                        self.view.addSubview(self.webView!)
                        self.webView?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
                    }
                    
                    self.textScrollView?.removeFromSuperview()
                    self.textScrollView = nil
                    self.textView = nil
                    
                    self.progressIndicatorView.stopAnimation(self)
                    self.webView?.loadHTMLString(html, baseURL: nil)
                    
                    self.view.window?.makeFirstResponder(self.webView!)
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress", let w = self.webView, w.estimatedProgress == 1 {
            // Show the webview only when loading is complete.
            self.webView?.isHidden = false
        }
    }
}

