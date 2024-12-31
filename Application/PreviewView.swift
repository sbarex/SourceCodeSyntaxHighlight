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
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) ? .copy : NSDragOperation()
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.every
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let p = self.superview?.superview?.superview?.superview?.superview as? PreviewView, let a = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? String, let url = URL(string: a) {
            p.appendExample(url:  url.absoluteURL)
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
        if let p = self.superview as? PreviewView, let a = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? String, let url = URL(string: a) {
            print("draggingEnded2")
            p.appendExample(url:  url.absoluteURL)
            return true
        } else {
            return false
        }
    }
}

class PreviewView: NSView, SettingsSplitViewElement {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var examplesPopup: NSPopUpButton!
    
    @IBOutlet weak var refreshIndicator: NSProgressIndicator!
    @IBOutlet weak var appearanceButton: NSButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var textView: NSTextView!
    
    var isLocked = false
    fileprivate(set) var isRefreshig = false
    
    
    var isLight: Bool = {
        if #available(macOS 11.0, *) {
            return NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) ?? .aqua == .aqua
        } else {
            return (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        }
    }() {
        didSet {
            if oldValue != isLight {
                self.refreshPreview()
            }
        }
    }
    
    var settings: SettingsBase? {
        didSet {
            if let settings = self.settings {
                appearanceButton.isEnabled = settings.lightThemeName != settings.darkThemeName
                examplesPopup.isEnabled = true
            } else {
                appearanceButton.isEnabled = false
                examplesPopup.isEnabled = false
            }
            self.refreshPreview()
            highlightedProperty = nil
        }
    }
    
    var highlightedProperty: SCSHTheme.PropertyName? {
        didSet {
            guard settings?.format == .html, !isRefreshig else {
                return
            }
            if highlightedProperty == nil || highlightedProperty == .canvas || highlightedProperty == .plain {
                webView.evaluateJavaScript("unhighlight()")
            } else {
                webView.evaluateJavaScript("highlight('.\(highlightedProperty!.cssClasses.last!)', true);")
            }
        }
    }
    
    var render_settings: SettingsRendering {
        let render_settings: SettingsRendering
            
        if let settings = self.settings as? SettingsRendering {
            render_settings = settings
        } else {
            if let settings = self.settings as? SettingsFormat {
                render_settings = SettingsRendering(globalSettings: SCSHWrapper.shared.settings ?? Settings(settings: [:]), format: settings)
            } else if let settings = self.settings as? Settings {
                render_settings = SettingsRendering(globalSettings: settings, format: nil)
            } else {
                render_settings = SettingsRendering(settings: [:])
            }
        
            render_settings.vcsDiff = ["-2,0 +2 -5 +5,0 -8,2 +8,2"]
            render_settings.isLight = isLight
            if isLight {
                render_settings.themeName = render_settings.lightThemeName
                render_settings.backgroundColor = render_settings.lightBackgroundColor
                render_settings.foregroundColor = render_settings.lightForegroundColor
            } else {
                render_settings.themeName = render_settings.darkThemeName
                render_settings.backgroundColor = render_settings.darkBackgroundColor
                render_settings.foregroundColor = render_settings.darkForegroundColor
            }
            if let theme = HighlightWrapper.shared.getTheme(name: render_settings.themeName), theme.isDirty || !theme.exists {
                // Embed theme properties if it is not saved.
                render_settings.themeLua = theme.getLua()
            }
        }
        
        return render_settings
    }
    
    var examples: [ExampleItem] = [] {
        didSet {
            examplesPopup.removeAllItems()
            
            examplesPopup.addItem(withTitle: "Color scheme")
            examplesPopup.menu?.addItem(NSMenuItem.separator())
            
            var custom = false
            for file in examples {
                if !custom && !file.standalone {
                    custom = true
                    examplesPopup.menu?.addItem(NSMenuItem.separator())
                }
                let m = NSMenuItem(title: file.title, action: nil, keyEquivalent: "")
                m.representedObject = file
                m.toolTip = file.standalone ? file.uti : "\(file.url.path) (\(file.uti))"
                examplesPopup.menu?.addItem(m)
            }
            
            examplesPopup.menu?.addItem(NSMenuItem.separator())
            examplesPopup.addItem(withTitle: "Browse…")
            
            examplesPopup.isEnabled = true
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
        
        // Populate the example files list.
        examples = (NSApplication.shared.delegate as? AppDelegate)?.getAvailableExamples() ?? []
        
        var layoutSize = textView.maxSize
        layoutSize.width = layoutSize.height;
        textView.maxSize = layoutSize
        
        textView.registerForDraggedTypes([.fileURL])
        textView.textContainerInset = CGSize(width: 6, height: 12)
        
        webView.configuration.userContentController.add(self, name: "nativeProcess")
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    
        // Prevent automatic word wrap.
        textView.isHorizontallyResizable = true
        textView.textContainer!.widthTracksTextView    =   false
        textView.textContainer!.containerSize          =   CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    func selectExample(forUTI uti: UTI?) {
        defer {
            handleExampleChanged(examplesPopup)
        }
        if let uti = uti {
            for item in examplesPopup.menu?.items ?? [] {
                guard let file = item.representedObject as? ExampleItem else {
                    continue
                }
                if uti.UTI == file.uti {
                    examplesPopup.select(item)
                    return
                }
            }
        }
        examplesPopup.selectItem(at: 0)
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
        guard !isLocked else {
            return
        }
        
        guard let _ = self.settings else {
            webView.isHidden = true
            scrollView.isHidden = true
            return
        }
        
        let render_settings = self.render_settings
        
        webView.isHidden = render_settings.format == .rtf
        scrollView.isHidden = !webView.isHidden
        self.refreshIndicator.startAnimation(self)
        self.isRefreshig = true
        
        let example = (examplesPopup.selectedItem?.representedObject as? ExampleItem)?.url
        
        if let url = example {
            /// Show a file.
            if render_settings.format == .html {
                webView.loadHTMLString("<!DOCTYPE html><html style='background-color: \(render_settings.backgroundColor)'><body style='height: 100%'    ><p style='font-family:  -apple-system; font-size: 10pt'>Waiting…</p></body></html>", baseURL: nil)
                //DispatchQueue.global(qos: .default).async {
                SCSHWrapper.shared.render(url: url, settings: render_settings) { (data, effective_settings, error) in
                    let settings = SettingsRendering(settings: effective_settings as! [String : AnyHashable])
                    self.isRefreshig = false
                    
                    let html: String
                    if let e = error {
                        html = String(data: data, encoding: .utf8) ?? e.localizedDescription
                    } else if let s = String(data: data, encoding: .utf8) {
                        html = s
                    } else {
                        html = "Conversion error!".toHTML(settings: settings)
                    }
                    DispatchQueue.main.async {
                        self.webView.loadHTMLString(html, baseURL: nil)
                        self.refreshIndicator.stopAnimation(self)
                    }
                }
                //}
            } else {
                textView.string = "Waiting…"
                //DispatchQueue.global(qos: .default).async {
                    SCSHWrapper.shared.render(url: url, settings: render_settings) { (response, effective_settings, error) in
                        let settings = SettingsRendering(settings: effective_settings as! [String : AnyHashable])
                        let text: NSAttributedString
                        if let e = error {
                            text = NSAttributedString(rtf: response, documentAttributes: nil) ?? (String(data: response, encoding: .utf8) ?? e.localizedDescription).toRTF(settings: settings) ?? NSAttributedString(string: e.localizedDescription)
                        } else if let s = NSAttributedString(rtf: response, documentAttributes: nil) {
                            text = s
                        } else {
                            text = "Conversion error!".toRTF(settings: settings) ?? NSAttributedString(string: "Conversion error!")
                        }
                        self.isRefreshig = false
                        DispatchQueue.main.async {
                            self.textView.textStorage?.setAttributedString(text)
                            self.scrollView.contentView.scroll(.zero)
                            
                            if let c = NSColor(fromHexString: settings.backgroundColor) {
                                self.textView.backgroundColor = c
                            } else {
                                self.textView.backgroundColor = .clear
                            }
                            self.refreshIndicator.stopAnimation(self)
                        }
                    }
                //}
            }
        } else {
            // Show standard theme preview.
            if let t = HighlightWrapper.shared.getTheme(name: render_settings.themeName) {
                if render_settings.format == .html {
                    webView.loadHTMLString(t.getHtmlExample(fontName: render_settings.fontName, fontSize: render_settings.fontSize * 0.75, showLSPTokens: (NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false), baseURL: nil)
                } else {
                    let example = t.getAttributedExample(fontName: render_settings.fontName, fontSize: render_settings.fontSize * 0.75, showLSPTokens: (NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)
                    textView.textStorage?.setAttributedString(example)
                    self.scrollView.contentView.scroll(.zero)
                    if let c = NSColor(fromHexString: render_settings.backgroundColor) {
                        textView.backgroundColor = c
                    } else {
                        textView.backgroundColor = .clear
                    }
                }
            } else {
                if render_settings.format == .html {
                    webView.loadHTMLString("<!DOCTYPE html><html style='background-color: \(render_settings.backgroundColor)'><body style='height: 100%'><p style='font-family:  -apple-system; font-size: 10pt'><p>Error: no theme</p></body></html>", baseURL: nil)
                } else {
                    textView.string = "Error: no theme."
                    if let c = NSColor(fromHexString: render_settings.backgroundColor) {
                        textView.backgroundColor = c
                    } else {
                        textView.backgroundColor = .clear
                    }
                }
            }
            refreshIndicator.stopAnimation(self)
            self.isRefreshig = false
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

            if dialog.runModal() == NSApplication.ModalResponse.OK {
                if let url = dialog.url?.absoluteURL {
                    self.appendExample(url: url)
                }
            } else {
                // User clicked on "Cancel"
                return
            }
        } else {
            self.refreshPreview()
        }
    }
    
    func appendExample(url: URL) {
        let file = (url: url, title: url.lastPathComponent, uti: UTI(URL: url)?.UTI ?? "", standalone: false)
        self.examples.append(file)
        self.examplesPopup.selectItem(at: examplesPopup.numberOfItems - 3)
        self.refreshPreview()
    }
    
    @IBAction func handleSwitchAppearance(_ sender: Any) {
        self.isLight = !self.isLight
    }
}

extension PreviewView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // print(message.name) // prints nativeProcess string
        if let message = message.body as? [String: AnyHashable], let name = message["name"] as? String {
            if name == "select-theme-token", let css = message["token-class"] as? String, let property = SCSHTheme.PropertyName(className: css) {
                self.themeEditView?.selectProperty(property)
            } else if name == "domready" && self.highlightedProperty != nil && self.highlightedProperty != .canvas && self.highlightedProperty != .plain {
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("highlight('.\(self.highlightedProperty!.cssClasses.last!)', true);")
                }
            }
        }
    }
}

class PreviewViewController: NSViewController {
    @IBOutlet weak var previewView: PreviewView!
}
