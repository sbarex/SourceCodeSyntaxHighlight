//
//  PreviewView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 24/04/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import WebKit
import Syntax_Highlight_XPC_Service

class NSTextViewNoDrop: NSTextView {
    
    override var acceptableDragTypes: [NSPasteboard.PasteboardType] { return [.fileURL] }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("draggingEntered1")
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) ? .copy : NSDragOperation()
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("draggingUpdated1")
        return NSDragOperation.every
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let p = self.superview?.superview?.superview?.superview?.superview as? PreviewView, let a = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? String, let url = URL(string: a) {
            print("draggingEnded1")
            p.exampleUrl = url.absoluteURL
            p.examplesPopup.selectItem(at: p.examplesPopup.numberOfItems-2)
            p.refreshPreview()
            return true
        } else {
            return false
        }
    }
}

class WKWebViewDrop: WKWebView {
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return false
    }
}

class PreviewView: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var examplesPopup: NSPopUpButton!
    
    @IBOutlet weak var previewThemeControl: NSSegmentedControl!
    @IBOutlet weak var refreshIndicator: NSProgressIndicator!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var customMenuItem: NSMenuItem!
    
    var renderMode: SCSHBaseSettings.Format = SCSHGlobalBaseSettings.preferredFormat {
        didSet {
            webView.isHidden = renderMode == .rtf
            scrollView.isHidden = !webView.isHidden
            refresh(self)
        }
    }
    
    var isLooked = false
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    var getSettings = {()->SCSHSettings? in
        return nil
    }
    
    var examples: [ExampleInfo] = [] {
        didSet {
            examplesPopup.removeAllItems()
            
            examplesPopup.addItem(withTitle: "Theme colors")
            examplesPopup.menu?.addItem(NSMenuItem.separator())
            for file in examples {
                let m = NSMenuItem(title: file.title, action: nil, keyEquivalent: "")
                m.toolTip = file.uti
                examplesPopup.menu?.addItem(m)
            }
            examplesPopup.isEnabled = true
            examplesPopup.menu?.addItem(NSMenuItem.separator())
            
            let m = NSMenuItem(title: "Custom", action: nil, keyEquivalent: "")
            if let exampleUrl = self.exampleUrl {
                m.isHidden = false
                m.toolTip = exampleUrl.path
            } else {
                m.isHidden = true
            }
            examplesPopup.menu?.addItem(m)
            customMenuItem = m
            
            examplesPopup.addItem(withTitle: "Browse…")
        }
    }
    
    var exampleUrl: URL? {
        didSet {
            if let url = exampleUrl {
                customMenuItem.isHidden = false
                customMenuItem.toolTip = url.path
            } else {
                customMenuItem.isHidden = true
            }
        }
    }
    
    var themes: [SCSHTheme] = [] {
        didSet {
            refresh(self)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)

        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
        /*constrain(self, contentView) { view, subview in
            subview.edges == view.edges
        }*/
        
        examples = [] // Popola la lista degli esempi.
        
        let macosThemeLight = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        previewThemeControl.setSelected(true, forSegment: macosThemeLight ? 0 : 1)
        
        var layoutSize = textView.maxSize
        layoutSize.width = layoutSize.height;
        textView.maxSize = layoutSize
        
        textView.registerForDraggedTypes([.fileURL])
       
        /*
        // Prevent automatic word wrap.
        textView.isHorizontallyResizable = true
        textView.textContainer!.widthTracksTextView    =   false
        textView.textContainer!.containerSize          =   CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        */
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("drag enter")
        return NSDragOperation.every
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("drag updated")
        return NSDragOperation.every
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("drag draggingExited")
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        print("drag end")
    }
    
    /// Refresh global preview.
    func refreshPreview() {
        guard !isLooked, let settings = self.getSettings() else {
            return
        }
        
        let light = previewThemeControl.selectedSegment == 0
        
        let custom_settings = SCSHSettings(settings: settings)
        
        if light {
            custom_settings.theme = custom_settings.lightTheme
            custom_settings.backgroundColor = custom_settings.lightBackgroundColor
        } else {
            custom_settings.theme = custom_settings.darkTheme
            custom_settings.backgroundColor = custom_settings.darkBackgroundColor
        }
        
        self.refreshIndicator.startAnimation(self)
        
        let example: URL?
        if let e = exampleUrl, examplesPopup.indexOfSelectedItem == examplesPopup.numberOfItems - 2 {
            example = e
        } else {
            if examplesPopup.indexOfSelectedItem == 0 || examples.count == 0 {
                example = nil
            } else {
                example = self.examples[examplesPopup.indexOfSelectedItem-2].url
            }
        }
        
        if let url = example {
            /// Show a file.
            if custom_settings.format == .html {
                webView.loadHTMLString("<html><body><p style='font-family:  -apple-system; font-size: 10pt'>Waiting…</p></body></html>", baseURL: nil)
                //DispatchQueue.global(qos: .default).async {
                    self.service?.htmlColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary) { (html, extra, error) in
                        DispatchQueue.main.async {
                            self.webView.loadHTMLString(html, baseURL: nil)
                            self.refreshIndicator.stopAnimation(self)
                        }
                    }
                //}
            } else {
                textView.string = "Waiting…"
                //DispatchQueue.global(qos: .default).async {
                    self.service?.rtfColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary) { (response, effective_settings, error) in
                        let text: NSAttributedString
                        if let e = error {
                            text = NSAttributedString(string: String(data: response, encoding: .utf8) ?? e.localizedDescription)
                        } else {
                            text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Conversion error!")
                        }
                        
                        DispatchQueue.main.async {
                            self.textView.textStorage?.setAttributedString(text)
                            if let bg = effective_settings[SCSHSettings.Key.backgroundColor] as? String, let c = NSColor(fromHexString: bg) {
                                self.textView.backgroundColor = c
                            } else {
                                self.textView.backgroundColor = .clear
                            }
                            self.refreshIndicator.stopAnimation(self)
                        }
                    //}
                }
            }
        } else {
            // Show standard theme preview.
            if let t = getTheme(name: custom_settings.theme) {
                if custom_settings.format == .html {
                    webView.loadHTMLString(t.getHtmlExample(fontName: settings.fontFamily ?? "Menlo", fontSize: (settings.fontSize ?? 12) * 0.75), baseURL: nil)
                } else {
                    let example = t.getAttributedExample(fontName: custom_settings.fontFamily ?? "Menlo", fontSize: (custom_settings.fontSize ?? 12) * 0.75)
                    textView.textStorage?.setAttributedString(example)
                    
                    if let bg = custom_settings.backgroundColor, let c = NSColor(fromHexString: bg) {
                        textView.backgroundColor = c
                    } else {
                        textView.backgroundColor = .clear
                    }
                }
            } else {
                if custom_settings.format == .html {
                    webView.loadHTMLString("<html><body><p>Error: no theme</p></body></html>", baseURL: nil)
                } else {
                    textView.string = "Error: no theme."
                    if let bg = custom_settings.backgroundColor, let c = NSColor(fromHexString: bg) {
                        textView.backgroundColor = c
                    } else {
                        textView.backgroundColor = .clear
                    }
                }
            }
            refreshIndicator.stopAnimation(self)
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.refreshPreview()
    }
    
    @IBAction func handleExampleChanged(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            // Browse
            
            let dialog = NSOpenPanel();
            
            dialog.title                   = "Choose a source file";
            dialog.showsResizeIndicator    = true;
            dialog.showsHiddenFiles        = false;
            dialog.canChooseDirectories    = false;
            dialog.canCreateDirectories    = false;
            dialog.allowsMultipleSelection = false;
            //dialog.allowedFileTypes        = ["txt"];

            if (dialog.runModal() == NSApplication.ModalResponse.OK) {
                let result = dialog.url // Pathname of the file
                
                if (result != nil) {
                    exampleUrl = result!.absoluteURL
                    self.examplesPopup.selectItem(at: examplesPopup.numberOfItems-2)
                }
            } else {
                // User clicked on "Cancel"
                return
            }
        }
        self.refreshPreview()
    }
    
    func selectExampleForUTI(_ uti: String) {
        if let i = examples.firstIndex(where: { $0.uti == uti}) {
            examplesPopup.selectItem(at: i+2)
        } else {
            examplesPopup.selectItem(at: 0)
        }
        refresh(self)
    }
    
    /// Get a theme by name.
    /// - parameters:
    ///   - name: Name of the theme. If has ! prefix search for a customized theme, otherwise for a standalone theme.
    func getTheme(name: String?) -> SCSHTheme? {
        guard name != nil else {
            return nil
        }
        if name!.hasPrefix("!") {
            var n = name!
            n.remove(at: n.startIndex)
            return themes.first(where: { !$0.isStandalone && $0.name == n })
        } else {
            return themes.first(where: { $0.isStandalone && $0.name == name! })
        }
    }
}
