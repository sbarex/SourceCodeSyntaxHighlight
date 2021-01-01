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


class StaticTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount > 1, let u = (self.window?.contentViewController as? PreviewViewController)?.fileUrl {
            // Open the source file by a double click on the quicklook preview window.
            NSWorkspace.shared.open(u)
        }
        /*
        if let parent = self.superview?.superview as? NSScrollView {
            if let _ = parent.verticalScroller?.hitTest(NSPoint(x: event.absoluteX, y: event.absoluteY)) {
                super.mouseDown(with: event)
                return
            } else if let _ = parent.horizontalScroller?.hitTest(NSPoint(x: event.absoluteX, y: event.absoluteY)) {
                super.mouseDown(with: event)
                return
            }
        }
        */
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
        if #available(macOS 11, *) {
            view.wantsLayer = true
            view.layer?.borderWidth = 0
        }
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
        
        os_log(
            "Generating preview for file %{public}s",
            log: self.log,
            type: .info,
            url.path
        )
        
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCRender")
        connection.remoteObjectInterface = NSXPCInterface(with: XPCLightRenderServiceProtocol.self)
        connection.resume()
        
        guard let service = connection.synchronousRemoteObjectProxyWithErrorHandler({ error in
            print("Received error:", error)
            
            let labelView = NSTextField(frame: self.view.bounds)
            labelView.autoresizingMask = [.height, .width]
            self.view.addSubview(labelView)
            labelView.stringValue = "Error: \(error.localizedDescription)"
            
            handler(SCSHError.xpcGenericError(error: error))
        }) as? XPCLightRenderServiceProtocol else {
            let labelView = NSTextField(frame: self.view.bounds)
            labelView.autoresizingMask = [.height, .width]
            self.view.addSubview(labelView)
            labelView.stringValue = "Error: invalid XPC service"
            
            handler(SCSHError.xpcGenericError(error: nil))
            return
        }
        
        service.colorize(url: url) { (response: Data, settings: NSDictionary, error: Error?) in
            let format = settings[SCSHSettings.Key.format] as? String ?? SCSHGlobalBaseSettings.preferredFormat.rawValue
            os_log(
                "Output mode: %{public}s",
                log: self.log,
                type: .info,
                format
            )
            DispatchQueue.main.async {
                /*
                if let color = settings[SCSHSettings.Key.rtfBackgroundColor] as? String, let c = NSColor(fromHexString: color) {
                    // Apply the background color to the container view.
                    self.view.layer?.backgroundColor = c.cgColor
                } else {
                    self.view.layer?.backgroundColor = NSColor.clear.cgColor
                }
                */
                let previewRect: CGRect
                if #available(macOS 11, *) {
                    previewRect = self.view.bounds
                } else {
                    previewRect = self.view.bounds.insetBy(dx: 2, dy: 2)
                }
                if format == SCSHBaseSettings.Format.rtf.rawValue {
                    let textScrollView = NSScrollView(frame: previewRect)
                    textScrollView.autoresizingMask = [.height, .width]
                    textScrollView.hasHorizontalScroller = true
                    textScrollView.hasVerticalScroller = true
                    if #available(macOS 11, *) {
                        textScrollView.borderType = .noBorder
                        textScrollView.backgroundColor = NSColor.clear
                    } else {
                        textScrollView.borderType = .lineBorder
                    }
                    self.view.addSubview(textScrollView)
                    
                    let textView: NSTextView
                    if #available(macOS 11, *) {
                        textView = NSTextView(frame: CGRect(origin: .zero, size: textScrollView.contentSize))
                    } else {
                        // Catalina do not automatically handle double click and drag on the ql preview window.
                        textView = StaticTextView(frame: CGRect(origin: .zero, size: textScrollView.contentSize))
                    }
                    
                    //textView.minSize = CGSize(width: 0, height: 0)
                    textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.isVerticallyResizable = true
                    textView.isHorizontallyResizable = true
                    textView.autoresizingMask = []
                    textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.textContainer?.widthTracksTextView = false
                    textView.textContainer?.heightTracksTextView = false
                    textView.wantsLayer = true
                    textView.layer?.borderWidth = 0
                    
                    textView.isEditable = false
                    textView.isSelectable = false
                    
                    textView.isGrammarCheckingEnabled = false
                    
                    textView.backgroundColor = .clear
                    
                    textView.allowsDocumentBackgroundColorChange = true
                    textView.usesFontPanel = false
                    textView.usesRuler = false
                    textView.usesInspectorBar = false
                    textView.allowsImageEditing = false
                    
                    textScrollView.documentView = textView
                    
                    // The rtf parser don't apply (why?) the page background color.
                    if let c = settings[SCSHSettings.Key.backgroundColor] as? String, let color = NSColor(fromHexString: c) {
                        textView.backgroundColor = color
                        textView.drawsBackground = true
                    } else {
                        textView.backgroundColor = .clear
                        textView.drawsBackground = false
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
                    self.handler = handler
                    
                    let preferences = WKPreferences()
                    preferences.javaScriptEnabled = false
                    if let v = settings[SCSHSettings.Key.interactive] as? Bool, v {
                        preferences.javaScriptEnabled = true
                    }

                    // Create a configuration for the preferences
                    let configuration = WKWebViewConfiguration()
                    //configuration.preferences = preferences
                    configuration.allowsAirPlayForMediaPlayback = false
                    // configuration.userContentController.add(self, name: "jsHandler")
                    
                    /* MARK: FIXME
                    On Big Sur as far as I know, QuickLook extensions don't honor com.apple.security.network.client, so WebKit process immediately crash.
                    To temporary fix add this entitlements exception
                    com.apple.security.temporary-exception.mach-lookup.global-name:
                    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
                    <array>
                        <string>com.apple.nsurlsessiond</string>
                    </array>
                    */

                    let webView: WKWebView
                    if let v = settings[SCSHSettings.Key.interactive] as? Bool, v {
                        webView = WKWebView(frame: previewRect, configuration: configuration)
                    } else {
                        webView = StaticWebView(frame: previewRect, configuration: configuration)
                        (webView as! StaticWebView).fileUrl = self.fileUrl
                    }
                    webView.autoresizingMask = [.height, .width]
                    
                    webView.wantsLayer = true
                    if #available(macOS 11, *) {
                        webView.layer?.borderWidth = 0
                    } else {
                        // Draw a border around the web view
                        webView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
                        webView.layer?.borderWidth = 1
                    }
                
                    webView.navigationDelegate = self
                    webView.uiDelegate = self
                

                    webView.loadHTMLString(html, baseURL: nil)
                    self.view.addSubview(webView)
                    // handler(nil) // call the handler in the delegate method after complete rendering
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

extension PreviewViewController: WKUIDelegate {
}
