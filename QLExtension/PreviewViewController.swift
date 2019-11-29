//
//  PreviewViewController.swift
//  SyntaxHighlightExtension
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
import Quartz
import WebKit
import OSLog

import Syntax_Highlight_XPC_Render

class MyDraggingView: NSTextView {
    var trackArea: NSTrackingArea? = nil
    var doubleClickTimer: Timer?
    /// Url of current file.
    var url: URL?
    
    override var isOpaque: Bool {
        get {
            return false
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.clickCount > 1, let u = self.url {
            // Open the source file by a double click on the quicklook preview window.
            NSWorkspace.shared.open(u)
        } else {
            self.window?.performDrag(with: event)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
    }
    
    override func updateTrackingAreas() {
        if let trackArea = self.trackArea {
            self.removeTrackingArea(trackArea)
        }
        self.trackArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.cursorUpdate], owner: self, userInfo: nil)
        self.addTrackingArea(self.trackArea!)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}

class StaticTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount > 1, let u = (self.window?.contentViewController as? PreviewViewController)?.fileUrl {
            // Open the source file by a double click on the quicklook preview window.
            NSWorkspace.shared.open(u)
        } else {
            self.window?.performDrag(with: event)
        }
        self.window?.performDrag(with: event)
    }
}

class StaticWebView: WKWebView {
    var fileUrl: URL?
    static let scrollerSize = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
    
    override func mouseDown(with event: NSEvent) {
        if event.clickCount > 1, let u = fileUrl {
            // Open the source file by a double click on the quicklook preview window.
            NSWorkspace.shared.open(u)
        } else {
            let pos = self.convert(event.locationInWindow, from: nil)
            var rect = bounds
            rect.size.width -= StaticWebView.scrollerSize
            rect.size.height -= StaticWebView.scrollerSize
            if rect.contains(pos) {
                self.window?.performDrag(with: event)
            } else {
                // Ignore the event to allow interaction with scrollbars.
                super.mouseDown(with: event)
            }
        }
    }
}

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {
    /// Url of current file.
    var fileUrl: URL?
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.scsh-extension")
    }()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        /*
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.red.cgColor
        */
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    var handler: ((Error?) -> Void)? = nil
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        self.fileUrl = url
        
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCRender")
        connection.remoteObjectInterface = NSXPCInterface(with: XPCLightRenderServiceProtocol.self)
        connection.resume()
        
        guard let service = connection.synchronousRemoteObjectProxyWithErrorHandler({ error in
            print("Received error:", error)
            handler(SCSHError.xpcGenericError(error: error))
        }) as? XPCLightRenderServiceProtocol else {
            handler(SCSHError.xpcGenericError(error: nil))
            return
        }
        
        service.colorize(url: url) { (response: Data, settings: NSDictionary, error: Error?) in
            let format = settings[SCSHSettings.Key.format] as? String ?? SCSHBaseSettings.Format.html.rawValue
            DispatchQueue.main.async {
                /*
                if let color = settings[SCSHSettings.Key.rtfBackgroundColor] as? String, let c = NSColor(fromHexString: color) {
                    // Apply the background color to the container view.
                    self.view.layer?.backgroundColor = c.cgColor
                } else {
                    self.view.layer?.backgroundColor = NSColor.clear.cgColor
                }
                */
                let previewRect = self.view.bounds.insetBy(dx: 2, dy: 2)
                if format == SCSHBaseSettings.Format.rtf.rawValue {
                    let textScrollView = NSScrollView(frame: previewRect)
                    textScrollView.autoresizingMask = [.height, .width]
                    textScrollView.hasHorizontalScroller = true
                    textScrollView.hasVerticalScroller = true
                    textScrollView.borderType = .lineBorder
                    self.view.addSubview(textScrollView)
                    
                    let textView = StaticTextView(frame: CGRect(origin: .zero, size: textScrollView.contentSize))
                    
                    //textView.minSize = CGSize(width: 0, height: 0)
                    textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.isVerticallyResizable = true
                    textView.isHorizontallyResizable = true
                    textView.autoresizingMask = []
                    textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.textContainer?.widthTracksTextView = false
                    textView.textContainer?.heightTracksTextView = false
                    
                    textView.isEditable = false
                    textView.isSelectable = false
                    
                    textView.isGrammarCheckingEnabled = false
                    
                    textView.backgroundColor = .clear
                    textView.drawsBackground = true
                    textView.allowsDocumentBackgroundColorChange = true
                    textView.usesFontPanel = false
                    textView.usesRuler = false
                    textView.usesInspectorBar = false
                    textView.allowsImageEditing = false
                    
                    textScrollView.documentView = textView
                    
                    // The rtf parser don't apply (why?) the page background color.
                    if let c = settings[SCSHSettings.Key.backgroundColor] as? String, let color = NSColor(fromHexString: c) {
                        textView.backgroundColor = color
                    } else {
                        textView.backgroundColor = .clear
                    }
                    
                    let text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Unable to convert data to rtf.")
                    textView.textStorage?.setAttributedString(text)
                    
                    handler(nil)
                } else {
                    var lossy = false
                    let html = response.decodeToString(lossy: &lossy).trimmingCharacters(in: CharacterSet.newlines)
                    
                    if lossy {
                        os_log(OSLogType.error, log: self.log, "Some bytes cannot be decoded and have been replaced!")
                    }
                    
                    let preferences = WKPreferences()
                    preferences.javaScriptEnabled = false

                    // Create a configuration for the preferences
                    let configuration = WKWebViewConfiguration()
                    configuration.preferences = preferences
                    configuration.allowsAirPlayForMediaPlayback = false
                    // configuration.userContentController.add(self, name: "jsHandler")
                    
                    let webView: WKWebView
                    if let v = settings[SCSHSettings.Key.interactive] as? Bool, v {
                        webView = WKWebView(frame: previewRect, configuration: configuration)
                    } else {
                        webView = StaticWebView(frame: previewRect, configuration: configuration)
                        (webView as! StaticWebView).fileUrl = self.fileUrl
                    }
                    
                    // Draw a border around the web view
                    webView.wantsLayer = true
                    webView.layer?.borderColor = NSColor.gridColor.cgColor
                    webView.layer?.borderWidth = 1
                    
                    webView.navigationDelegate = self
                    
                    webView.autoresizingMask = [.height, .width]
                    
                    self.view.addSubview(webView)
                    
                    /*
                    webView.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[subview]-2-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": webView]))
                    self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": webView]))
                    */
                    
                    webView.loadHTMLString(html, baseURL: nil)
                    self.handler = handler
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let handler = self.handler {
            // Show the quicklook preview only after the complete rendering (preventing a flickering glitch).
            /*
            let w = NSScroller.scrollerWidth(for: NSControl.ControlSize.regular, scrollerStyle: NSScroller.Style.overlay)
            webView.evaluateJavaScript("""
            document.body.onmousedown = function(event) {
                const height = document.body.scrollHeight;
                const width = document.body.scrollWidth;
                const hasHorizontalScrollbar = width >  window.innerWidth;
                const hasVerticalScrollbar = height > window.innerHeight;
                const scroller = \(w);
                if (hasVerticalScrollbar && event.clientX >= window.innerWidth - scroller) {
                    // Mouse over scrollbar.
                    return;
                } else if (hasHorizontalScrollbar && event.clientY >= window.innerHeight - scroller) {
                    // Mouse over scrollbar.
                    return;
                } else {
                    event.stopPropagation();
                    window.webkit.messageHandlers.jsHandler.postMessage({event: "mousedown"});
                }
            }
            body.ondblclick = function(event) {
                window.webkit.messageHandlers.jsHandler.postMessage({event: "dblclick"});
                event.stopPropagation();
            }
            true; // result returned to swift
            """){ (result, error) in
                if let e = error {
                    print(e)
                }
            }
            */
            handler(nil)
            self.handler = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let handler = self.handler {
            handler(error)
            self.handler = nil
        }
    }
}

/*
// MARK: - WKScriptMessageHandler
extension PreviewViewController: WKScriptMessageHandler {
    /// Handle messages from the webkit.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "jsHandler", let result = message.body as? [String: Any] else {
            return
        }
        
        if result["event"] as? String == "mousedown" {
        let event = NSEvent.mouseEvent(with: NSEvent.EventType.leftMouseDown, location: NSEvent.mouseLocation, modifierFlags: [], timestamp: TimeInterval(), windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        self.view.window?.performDrag(with: event)
        } else if result["event"] as? String == "dblclick" {
            NSWorkspace.shared.open(fileUrl!)
        } else {
            print(result)
        }
    }
}
*/
