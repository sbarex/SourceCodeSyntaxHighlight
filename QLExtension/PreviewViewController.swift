//
//  PreviewViewController.swift
//  QLExtension
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

import Cocoa
import Quartz
import WebKit
import os.log

import XPCService

class PreviewViewController: NSViewController, QLPreviewingController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
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
        
        let connection = NSXPCConnection(serviceName: "sbarex.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
        connection.resume()
        
        guard let service = connection.remoteObjectProxyWithErrorHandler({ error in
            print("Received error:", error)
            handler(QLCError.xpcGenericError(error: error))
        }) as? XPCServiceProtocol else {
            handler(QLCError.xpcGenericError(error: nil))
            return
        }
        
        service.colorize(url: url, overrideSettings: nil) { (response, settings, error) in
            let format = settings[QLCSettings.Key.format.rawValue] as? String ?? QLCFormat.html.rawValue
            DispatchQueue.main.async {
                if format == QLCFormat.rtf.rawValue {
                    let textScrollView = NSScrollView(frame: self.view.bounds)
                    textScrollView.autoresizingMask = [.height, .width]
                    textScrollView.hasHorizontalScroller = true
                    textScrollView.hasVerticalScroller = true
                    textScrollView.borderType = .noBorder
                    self.view.addSubview(textScrollView)
                    
                    let textView = NSTextView(frame: CGRect(origin: .zero, size: textScrollView.contentSize))
                    
                    //textView.minSize = CGSize(width: 0, height: 0)
                    textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.isVerticallyResizable = true
                    textView.isHorizontallyResizable = true
                    textView.autoresizingMask = []
                    textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    textView.textContainer?.widthTracksTextView = false
                    textView.textContainer?.heightTracksTextView = false
                    
                    textView.isEditable = false
                    textView.isSelectable = true
                    
                    textView.isGrammarCheckingEnabled = false
                    
                    textView.backgroundColor = .clear
                    textView.drawsBackground = true
                    textView.allowsDocumentBackgroundColorChange = true
                    textView.usesFontPanel = false
                    textView.usesRuler = false
                    textView.usesInspectorBar = false
                    textView.allowsImageEditing = false
                    
                    textScrollView.documentView = textView
                    
                    // The rtf parser don't apply (why?) the page packground.
                    if let c = settings[QLCSettings.Key.rtfBackgroundColor.rawValue] as? String, let color = NSColor(fromHexString: c) {
                        textView.backgroundColor = color
                    } else {
                        textView.backgroundColor = .clear
                    }
                    
                    let text: NSAttributedString
                    if let e = error {
                        text = NSAttributedString(string: e.localizedDescription)
                    } else {
                        text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Unable to convert data to rtf.")
                    }
                    
                    textView.textStorage?.setAttributedString(text)
                } else {
                    let html: String
                    if let _ = error {
                        if let e = error as? QLCError {
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
                        html = (String(data: response, encoding: String.Encoding.utf8) ?? "Unable to convert data!").trimmingCharacters(in: CharacterSet.newlines)
                    }
                    
                    let preferences = WKPreferences()
                    preferences.javaScriptEnabled = false

                    // Create a configuration for the preferences
                    let configuration = WKWebViewConfiguration()
                    configuration.preferences = preferences
                    configuration.allowsAirPlayForMediaPlayback = false
                    
                    let webView = WKWebView(frame: self.view.bounds, configuration: configuration)
                    webView.autoresizingMask = [.height, .width]
                    
                    self.view.addSubview(webView)
                    
                    webView.loadHTMLString(html, baseURL: nil)
                }
                connection.invalidate()
                handler(nil)
            }
        }
    }
}
