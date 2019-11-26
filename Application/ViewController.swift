//
//  ViewController.swift
//  SyntaxHighlight
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SyntaxHighlight.
//  SyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import WebKit
import Syntax_Highlight_XPC_Service

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
        self.webView?.isHidden = true
        self.webView?.loadHTMLString("", baseURL: nil)
        
        self.textScrollView?.isHidden = true
        self.textView?.string = ""
        
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
    
    func initializeView(forMode mode: SCSHFormat) {
        if mode == .rtf {
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
             
            if let wv = self.webView {
                wv.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
                wv.removeFromSuperview()
                self.webView = nil
            }
        } else {
            if self.webView == nil {
                let preferences = WKPreferences()
                preferences.javaScriptEnabled = true
                preferences.setValue(true, forKey: "developerExtrasEnabled")

                // Create a configuration for the preferences
                let configuration = WKWebViewConfiguration()
                configuration.preferences = preferences
                configuration.allowsAirPlayForMediaPlayback = false
                
                self.webView = WKWebView(frame: self.view.bounds, configuration: configuration)
                self.webView!.autoresizingMask = [.height, .width]
                self.webView?.isHidden = true
                
                self.view.addSubview(self.webView!)
                self.webView?.navigationDelegate = self
            }
                
            if let tsv = textScrollView {
                self.textView?.removeFromSuperview()
                self.textView = nil
                
                tsv.removeFromSuperview()
                self.textScrollView = nil
            }
        }
    }

    @IBAction func refresh(_ sender: Any?) {
        guard let documentUrl = self.representedObject as? URL else {
            return
        }
        
        self.progressIndicatorView.startAnimation(self)
        
        webView?.isHidden = true
        textScrollView?.isHidden = true
        
        service?.colorize(url: documentUrl, overrideSettings: [SCSHSettings.Key.renderForExtension: false]) { (response, settings, error) in
            let format = SCSHFormat(rawValue: settings[SCSHSettings.Key.format] as? String ?? "html") ?? .html
            DispatchQueue.main.async {
                self.initializeView(forMode: format)
                
                if format == .rtf {
                    let text: NSAttributedString
                    if let e = error {
                        text = NSAttributedString(string: String(data: response, encoding: .utf8) ?? e.localizedDescription)
                    } else {
                        text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Conversion error!")
                    }
                    
                    self.textView?.textStorage?.setAttributedString(text)
                    // The rtf parser don't apply (why?) the page packground.
                    if let c = settings[SCSHSettings.Key.rtfBackgroundColor] as? String, let color = NSColor(fromHexString: c) {
                        self.textView?.backgroundColor = color
                    } else {
                        self.textView?.backgroundColor = .clear
                    }
                    
                    self.progressIndicatorView.stopAnimation(self)
                    self.textScrollView?.isHidden = false
                        
                    self.view.window?.makeFirstResponder(self.textView!)
                } else {
                    let html: String = response.decodeToString().trimmingCharacters(in: CharacterSet.newlines)
                    
                    self.webView?.loadHTMLString(html, baseURL: nil)
                }
            }
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Show the quicklook preview only after the complete rendering (preventing a flickering glitch).
        webView.isHidden = false
        self.view.window?.makeFirstResponder(webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.isHidden = false
    }
}

