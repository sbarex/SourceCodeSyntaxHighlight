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
    
    var textScrollView: NSScrollView?
    var textView: NSTextView?
    var webView: WKWebView?
    
    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCRender")
        connection.remoteObjectInterface = NSXPCInterface(with: XPCLightRenderServiceProtocol.self)
        connection.resume()
        return connection
    }()
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.scsh-extension")
    }()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        // This code will not be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
        super.loadView()
        // Do any additional setup after loading the view.
        if #available(macOS 11, *) {
            view.wantsLayer = true
            view.layer?.borderWidth = 0
        }
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .SettingsUpdated, object: nil)
    }

    deinit {
        self.connection.invalidate()
        DistributedNotificationCenter.default().removeObserver(self, name: .SettingsUpdated, object: nil)
    }
    
    /// Reload settings after they have been changed in the main app.
    @objc internal func handleSettingsChanged(_ notification: Notification) {
        guard let service = connection.synchronousRemoteObjectProxyWithErrorHandler({ error in
            print("Received error:", error)
        }) as? XPCLightRenderServiceProtocol else {
            return
        }
        service.reloadSettings()
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
        // This code will not be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
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
        
        do {
            let result = try self.renderFile(at: url)
            
            DispatchQueue.main.async {
                let previewRect: CGRect
                if #available(macOS 11, *) {
                    previewRect = self.view.bounds
                } else {
                    previewRect = self.view.bounds.insetBy(dx: 2, dy: 2)
                }
                switch result {
                case .html(let code, let settings):
                    self.handler = handler
                    if self.webView == nil {
                        // Create a configuration for the preferences
                        let configuration = WKWebViewConfiguration()
                        
                        if #available(macOS 11.0, *) {
                            configuration.defaultWebpagePreferences.allowsContentJavaScript = settings?.allowInteractiveActions ?? false
                        } else {
                            configuration.preferences.javaScriptEnabled = settings?.allowInteractiveActions ?? false
                        }
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
                        if settings?.allowInteractiveActions ?? false {
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
                        self.view.addSubview(webView)
                        self.webView = webView
                    } else {
                        if #available(macOS 11.0, *) {
                            self.webView?.configuration.defaultWebpagePreferences.allowsContentJavaScript = settings?.allowInteractiveActions ?? false
                        } else {
                            self.webView?.configuration.preferences.javaScriptEnabled =  settings?.allowInteractiveActions ?? false
                        }
                    }
                    
                    self.textScrollView?.isHidden = true
                    self.webView?.isHidden = false

                    self.webView?.loadHTMLString(code, baseURL: nil)
                    // handler(nil) // call the handler in the delegate method after complete rendering
                case .rtf(let data, let settings):
                    if self.textScrollView == nil {
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
                        
                        self.textScrollView = textScrollView
                        self.textView = textView
                        
                        self.textView?.isVerticallyResizable = true
                        self.textView?.isHorizontallyResizable = true
                        self.textView?.autoresizingMask = []
                        
                        self.textView?.textContainerInset = CGSize(width: 6, height: 12)
                        
                        self.textView?.textContainer?.heightTracksTextView = false
                        self.textView?.wantsLayer = true
                        self.textView?.layer?.borderWidth = 0
                        
                        self.textView?.isEditable = false
                        self.textView?.isSelectable = false
                        
                        self.textView?.isGrammarCheckingEnabled = false
                        
                        self.textView?.backgroundColor = .clear
                        
                        self.textView?.allowsDocumentBackgroundColorChange = true
                        self.textView?.usesFontPanel = false
                        self.textView?.usesRuler = false
                        self.textView?.usesInspectorBar = false
                        self.textView?.allowsImageEditing = false
                        
                        self.textScrollView?.documentView = self.textView
                    }
                    self.webView?.isHidden = true
                    self.textScrollView?.isHidden = false
                    
                    if let settings = settings, settings.isWordWrapped, !settings.isWordWrappedSoft {
                        self.textView?.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                        self.textView?.textContainer?.widthTracksTextView = false
                        self.textView?.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    } else {
                        // self.textView?.maxSize = CGSize(width: textScrollView!.bounds.width, height: CGFloat.greatestFiniteMagnitude)
                        self.textView?.textContainer?.widthTracksTextView = true
                    }
                    
                    // The rtf parser don't apply (why?) the page background color.
                    if let c = settings?.backgroundColor, let color = NSColor(fromHexString: c) {
                        self.textView?.backgroundColor = color
                        self.textView?.drawsBackground = true
                    } else {
                        self.textView?.backgroundColor = .clear
                        self.textView?.drawsBackground = false
                    }
                    
                    var text: NSAttributedString
                    if let t = NSAttributedString(rtf: data, documentAttributes: nil) {
                        text = t
                    } else {
                        let t: NSMutableAttributedString
                        if let settings = settings, let a: NSAttributedString = "Syntax Highlight: unable to convert data to RTF.\n\n".toRTF(settings: settings) {
                            t = NSMutableAttributedString(attributedString: a)
                        } else {
                            t = NSMutableAttributedString(string: "Syntax Highlight: unable to convert data to RTF.\n\n", attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)])
                        }
                        if let s = String(data: data, encoding: .utf8) {
                            t.append(NSAttributedString(string: s, attributes: [.font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)]))
                        }
                        text = t
                    }
                    
                    self.textView?.textStorage?.setAttributedString(text)
                    
                    handler(nil)
                }
            }
        } catch {
            handler(error)
        }
    }
    
    @available(macOSApplicationExtension 12.0, *)
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        // This code will be called on macOS 12 Monterey with QLIsDataBasedPreview set.
        
        do {
            let result = try self.renderFile(at: request.fileURL)
            let r: QLPreviewReply
            switch result {
            case .html(let code, let settings):
                if settings?.isRenderingSupported ?? false {
                    if settings?.isImage ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.image, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the image file!".data(using: .utf8)!
                        }
                    } else if settings?.isPDF ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.pdf, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the PDF file!".data(using: .utf8)!
                        }
                    } else if settings?.isMovie ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.movie, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the movie file!".data(using: .utf8)!
                        }
                    } else if settings?.isAudio ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.audio, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the audio file!".data(using: .utf8)!
                        }
                    } else {
                        r = QLPreviewReply(dataOfContentType: UTType.html, contentSize: .zero) { _ in
                            return code.data(using: .utf8)!
                        }
                    }
                } else {
                    r = QLPreviewReply(fileURL: request.fileURL)
                }
            case .rtf(let data, let settings):
                if settings?.isRenderingSupported ?? false {
                    if settings?.isImage ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.image, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the image file!".data(using: .utf8)!
                        }
                    } else if settings?.isPDF ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.pdf, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the PDF file!".data(using: .utf8)!
                        }
                    } else if settings?.isMovie ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.movie, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the movie file!".data(using: .utf8)!
                        }
                    } else if settings?.isAudio ?? false {
                        r = QLPreviewReply(dataOfContentType: UTType.audio, contentSize: .zero) { _ in
                            return (try? Data(contentsOf: request.fileURL)) ?? "Unable to load the audio file!".data(using: .utf8)!
                        }
                    }  else {
                        r = QLPreviewReply(dataOfContentType: UTType.rtf, contentSize: .zero) { _ in
                            return data
                        }
                    }
                } else {
                    r = QLPreviewReply(fileURL: request.fileURL)
                }
            }
            handler(r, nil)
        } catch {
            handler(nil, error)
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
    
    enum RenderResult {
        case html(code: String, settings: SettingsRendering?)
        case rtf(data: Data, settings: SettingsRendering?)
    }
    
    func renderFile(at url: URL) throws -> RenderResult {
        os_log(
            "Generating preview for file %{public}s",
            log: self.log,
            type: .info,
            url.path
        )
        
        var result: RenderResult?
        
        var connettion_error: Error?
        guard let service = connection.synchronousRemoteObjectProxyWithErrorHandler({ error in
            connettion_error = error
            /*
            print("Received error:", error)
             */
        }) as? XPCLightRenderServiceProtocol else {
            return RenderResult.html(code: "Syntax Highlight: invalid XPC service.\n\(connettion_error?.localizedDescription ?? "")".toHTML(), settings: nil)
        }
        guard connettion_error == nil else {
            return RenderResult.html(code: "Syntax Highlight: \(connettion_error!.localizedDescription).".toHTML(), settings: nil)
        }
        
        service.colorize(url: url) { (response: Data, settings: NSDictionary, error: Error?) in
            let settings = SettingsRendering(settings: settings as! [String: AnyHashable])
            
            os_log(
                "Output mode: %{public}s",
                log: self.log,
                type: .info,
                settings.format.rawValue
            )
                
            if settings.format == .rtf {
                result = RenderResult.rtf(data: response, settings: settings)
            } else {
                var lossy = false
                let html = response.decodeToString(lossy: &lossy).trimmingCharacters(in: CharacterSet.newlines)
                
                if lossy {
                    os_log(OSLogType.error, log: self.log, "Some bytes cannot be decoded and have been replaced!")
                }
                
                result = RenderResult.html(code: html, settings: settings)
            }
        }
        
        return result ?? RenderResult.html(code: "Syntax Highlight error.".toHTML(), settings: nil)
    }
}

/*
// MARK - WKScriptMessageHandler
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
