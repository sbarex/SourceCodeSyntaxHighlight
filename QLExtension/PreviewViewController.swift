//
//  PreviewViewController.swift
//  SourceCodeSyntaxHighlightExtension
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
import Quartz
import WebKit
import OSLog

import SourceCodeSyntaxHighlightXPCService

class MyDraggingView: NSTextView {
    override var isOpaque: Bool {
        get {
            return false
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
    
    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
    }
}

class StaticTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    @IBOutlet weak var draggingView: MyDraggingView!
    @IBOutlet weak var trailingDragginViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomDragginViewConstraint: NSLayoutConstraint!
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.scsh-extension")
    }()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        
        let w = NSScroller.scrollerWidth(for: NSControl.ControlSize.regular, scrollerStyle: NSScroller.Style.overlay)
        self.trailingDragginViewConstraint.constant = w
        self.bottomDragginViewConstraint.constant = w
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
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: SCSHXPCServiceProtocol.self)
        connection.resume()
        
        guard let service = connection.synchronousRemoteObjectProxyWithErrorHandler({ error in
            print("Received error:", error)
            handler(SCSHError.xpcGenericError(error: error))
        }) as? SCSHXPCServiceProtocol else {
            handler(SCSHError.xpcGenericError(error: nil))
            return
        }
        
        service.colorize(url: url, overrideSettings: nil) { (response, settings, error) in
            let format = settings[SCSHSettings.Key.format.rawValue] as? String ?? SCSHFormat.html.rawValue
            DispatchQueue.main.async {
                if format == SCSHFormat.rtf.rawValue {
                    let textScrollView = NSScrollView(frame: self.view.bounds)
                    textScrollView.autoresizingMask = [.height, .width]
                    textScrollView.hasHorizontalScroller = true
                    textScrollView.hasVerticalScroller = true
                    textScrollView.borderType = .noBorder
                    self.view.addSubview(textScrollView, positioned: NSWindow.OrderingMode.below, relativeTo: self.draggingView)
                    
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
                    if let c = settings[SCSHSettings.Key.rtfBackgroundColor.rawValue] as? String, let color = NSColor(fromHexString: c) {
                        textView.backgroundColor = color
                    } else {
                        textView.backgroundColor = .clear
                    }
                    
                    let text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Unable to convert data to rtf.")
                    textView.textStorage?.setAttributedString(text)
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
                    
                    let webView = WKWebView(frame: self.view.bounds, configuration: configuration)
                    webView.autoresizingMask = [.height, .width]
                    
                    self.view.addSubview(webView, positioned: NSWindow.OrderingMode.below, relativeTo: self.draggingView)
                    
                    webView.loadHTMLString(html, baseURL: nil)
                }
                
                handler(nil)
            }
        }
    }
}
