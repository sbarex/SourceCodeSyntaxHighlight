//
//  PreferencesController.swift
//  SourceCodeSyntaxHighlight
//
//  Created by sbarex on 16/10/2019.
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

class PreferencesController: NSViewController, NSFontChanging {
    private var themes: [NSDictionary] = []
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var pathControl: NSPathCell!
    @IBOutlet weak var browseButton: NSButton!
    
    @IBOutlet weak var lightThemePopup: NSPopUpButton!
    @IBOutlet weak var darkThemePopup: NSPopUpButton!
    
    @IBOutlet weak var htmlFormatButton: NSButton!
    @IBOutlet weak var rtfFormatButton: NSButton!
    @IBOutlet weak var colorLightControl: NSColorWell!
    @IBOutlet weak var colorDarkControl: NSColorWell!
    
    @IBOutlet weak var lineNumbersButton: NSButton!
    
    @IBOutlet weak var tabToSpaceButton: NSButton!
    @IBOutlet weak var spacesSlider: NSSlider!
    
    @IBOutlet weak var extraArgumentsTextField: NSTextField!
    @IBOutlet weak var exampleFormatButton: NSPopUpButton!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textScrollView: NSScrollView!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var themeControl: NSSegmentedControl!
    
    @IBOutlet weak var fontText: NSTextField!
    
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    @objc dynamic var lightTheme: String = "XCode IDE"
    @objc dynamic var darkTheme: String = "XCode IDE"
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    var settings: [String: Any]?
    var examples: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let macosThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        self.themeControl.selectedSegment = macosThemeLight ? 0 : 1
        
        self.exampleFormatButton.removeAllItems()
        
        if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                self.examples = files
                
                for file in files {
                    self.exampleFormatButton.addItem(withTitle: file.lastPathComponent)
                }
            }
        }
        
        if let service = self.service {
            service.getSettings() {
                self.settings = $0 as? [String: Any]
                
                self.updateInternalState(n: 1)
            }
            
            service.getThemes() { (results, error) in
                self.themes = results
                
                self.updateInternalState(n: 1)
                // print(results)
            }
        }
    }
    
    override func viewDidAppear() {
       // any additional code
       view.window!.styleMask.remove(.resizable)
    }

    
    private var internal_state = 0
    private func updateInternalState(n: Int) {
        internal_state += n
        
        if internal_state == 2 {
            DispatchQueue.main.async {
                self.pathControl.isEnabled = true
                self.pathControl.url = URL(fileURLWithPath: self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String ?? "")
                self.browseButton.isEnabled = true
                
                let format = self.settings?[SCSHSettings.Key.format.rawValue] as? String ?? "html"
                self.htmlFormatButton.isEnabled = true
                self.htmlFormatButton.state = format == "html" ? .on : .off
                
                self.rtfFormatButton.isEnabled = true
                self.rtfFormatButton.state = format == "rtf" ? .on : .off
                self.colorLightControl.isEnabled = self.rtfFormatButton.state == .on
                self.colorDarkControl.isEnabled = self.rtfFormatButton.state == .on
                
                self.lineNumbersButton.isEnabled = true
                self.lineNumbersButton.state = (self.settings?[SCSHSettings.Key.lineNumbers.rawValue] as? Int) != 0 ? .on : .off
                
                self.tabToSpaceButton.isEnabled = true
                let spaces = self.settings?[SCSHSettings.Key.tabSpaces.rawValue] as? Int ?? 0
                self.tabToSpaceButton.state = spaces > 0 ? .on : .off
                self.spacesSlider.isEnabled = spaces > 0
                self.spacesSlider.integerValue = spaces > 0 ? spaces : 4
                
                self.extraArgumentsTextField.isEnabled = true
                self.extraArgumentsTextField.stringValue = self.settings?[SCSHSettings.Key.extraArguments.rawValue] as? String ?? ""
                
                self.updateFont()
                
                self.saveButton.isEnabled = true
                
                self.lightThemePopup.isEnabled = self.themes.count > 0
                self.lightThemePopup.removeAllItems()
                self.darkThemePopup.isEnabled = self.themes.count > 0
                self.darkThemePopup.removeAllItems()
                
                var i = 0
                var lightIndex = -1
                var darkIndex = -1
                for theme in self.themes {
                    let name = theme.value(forKey: "name") as! String
                    let desc = theme.value(forKey: "desc") as! String
                    
                    self.lightThemePopup.addItem(withTitle: desc)
                    self.darkThemePopup.addItem(withTitle: desc)
                    if name == self.settings?[SCSHSettings.Key.lightTheme.rawValue] as? String {
                        lightIndex = i
                        if let color = theme.value(forKey: "bg-color") as? String, let c = NSColor(fromHexString: color) {
                            self.colorLightControl.color = c
                        } else {
                            self.colorLightControl.color = .clear
                        }
                    }
                    if name == self.settings?[SCSHSettings.Key.darkTheme.rawValue] as? String {
                        darkIndex = i
                        if let color = theme.value(forKey: "bg-color") as? String, let c = NSColor(fromHexString: color) {
                            self.colorDarkControl.color = c
                        } else {
                            self.colorDarkControl.color = .clear
                        }
                    }
                    i += 1
                }
                if lightIndex >= 0 {
                    self.lightThemePopup.selectItem(at: lightIndex)
                }
                if darkIndex >= 0 {
                    self.darkThemePopup.selectItem(at: darkIndex)
                }
                
                self.exampleFormatButton.isEnabled = self.examples.count > 0
                self.themeControl.isEnabled = self.examples.count > 0
                self.refreshButton.isEnabled = self.examples.count > 0
                
                self.webView.isHidden = self.htmlFormatButton.state == .off
                self.textScrollView.isHidden = self.rtfFormatButton.state == .off
                
                self.refresh(nil)
            }
        }
    }
    
    private func updateFont() {
        let ff = SCSHSettings.Key.fontFamily.rawValue
        let fp = SCSHSettings.Key.fontSize.rawValue
        self.fontText.stringValue = String(format:"%@ %.1f pt", self.settings?[ff] as? String ?? "", self.settings?[fp] as? Float ?? 10)
        
         self.fontText.stringValue = String(format:"%@ %.1f pt", self.settings?[ff] as? String ?? "??", self.settings?[fp] as? Float ?? 10)
    }
    
    @IBAction func handleConvertSpace(_ sender: NSButton) {
        self.spacesSlider.isEnabled = sender.state == .on
    }

    @IBAction func handleFormatChange(_ sender: NSButton) {
        self.webView.isHidden = self.htmlFormatButton.state == .off
        self.textScrollView.isHidden = self.rtfFormatButton.state == .off
        self.colorLightControl.isEnabled = self.rtfFormatButton.state == .on
        self.colorDarkControl.isEnabled = self.rtfFormatButton.state == .on
        refresh(nil)
    }
    
    @IBAction func handleThemeChange(_ sender: NSPopUpButton) {
        let colorControl = sender == self.lightThemePopup ? self.colorLightControl : self.colorDarkControl
        
        if let c = self.themes[sender.indexOfSelectedItem]["bg-color"] as? String, let color = NSColor(fromHexString: c) {
            colorControl?.color = color
        } else {
            colorControl?.color = .clear
        }
        
        if (sender == self.lightThemePopup && self.themeControl.selectedSegment == 0) || sender == self.darkThemePopup && self.themeControl.selectedSegment == 1 {
            self.refresh(sender)
        }
    }
    
    @IBAction func browseAcrion(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = false
        openPanel.showsHiddenFiles = true
        if let s = self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String {
            let url = URL(fileURLWithPath: s, isDirectory: false)
            openPanel.directoryURL = url.deletingLastPathComponent()
        }
        openPanel.beginSheetModal(for: self.view.window!) { (result) -> Void in
            if result == .OK, let url = openPanel.url {
                self.pathControl.url = url
            }
        }
    }
    
    @IBAction func chooseFont(_ sender: Any) {
        let fontPanel = NSFontPanel.shared
        if let font = NSFont(name: self.settings?[SCSHSettings.Key.fontFamily.rawValue] as? String ?? "Menlo", size: self.settings?[SCSHSettings.Key.fontSize.rawValue] as? CGFloat ?? 10) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        if let family = font.familyName {
            self.settings?[SCSHSettings.Key.fontFamily.rawValue] = family
        } else {
            self.settings?[SCSHSettings.Key.fontFamily.rawValue] = font.fontName
        }
        self.settings?[SCSHSettings.Key.fontSize.rawValue] = Float(font.pointSize)
        
        self.updateFont()
    }
    
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
    
    private func getCurrentSettings() -> [String: Any] {
        var settings: [String: Any] = [
            SCSHSettings.Key.lineNumbers.rawValue: self.lineNumbersButton.state == .on,
            
            SCSHSettings.Key.tabSpaces.rawValue: self.tabToSpaceButton.state == .on ? self.spacesSlider.integerValue : 0,
            
            SCSHSettings.Key.extraArguments.rawValue: self.extraArgumentsTextField.stringValue,
            SCSHSettings.Key.format.rawValue: self.htmlFormatButton.state == .on ? "html" : "rtf",
        ]
        if self.themes.count > 0, let t = self.themes[self.lightThemePopup.indexOfSelectedItem]["name"] as? String {
            settings[SCSHSettings.Key.lightTheme.rawValue] = t
        }
        if self.themes.count > 0, let t = self.themes[self.darkThemePopup.indexOfSelectedItem]["name"] as? String {
            settings[SCSHSettings.Key.darkTheme.rawValue] = t
        }
        
        if let v = self.pathControl.url?.path {
            settings[SCSHSettings.Key.highlightPath.rawValue] = v
        }
        if let v = self.settings?[SCSHSettings.Key.fontFamily.rawValue] as? String {
            settings[SCSHSettings.Key.fontFamily.rawValue] = v
        }
        if let v = self.settings?[SCSHSettings.Key.fontSize.rawValue] as? Float {
            settings[SCSHSettings.Key.fontSize.rawValue] = v
        }
        
        if self.rtfFormatButton.state == .on {
            settings[SCSHSettings.Key.rtfLightBackgroundColor.rawValue] = self.colorLightControl.color.toHexString()
            settings[SCSHSettings.Key.rtfDarkBackgroundColor.rawValue] = self.colorDarkControl.color.toHexString()
        }
        
        return settings
    }
    
    @IBAction func refresh(_ sender: Any? = nil) {
        guard self.exampleFormatButton.itemArray.count > 0 else {
            return
        }
        
        progressIndicator.startAnimation(self)
        
        var settings = self.getCurrentSettings()
        
        if let t = settings[self.themeControl.selectedSegment == 0 ? SCSHSettings.Key.lightTheme.rawValue : SCSHSettings.Key.darkTheme.rawValue] as? String {
            settings[SCSHSettings.Key.theme.rawValue] = t
        }
        if let t = settings[self.themeControl.selectedSegment == 0 ? SCSHSettings.Key.rtfLightBackgroundColor.rawValue : SCSHSettings.Key.rtfDarkBackgroundColor.rawValue] as? String {
            settings[SCSHSettings.Key.rtfBackgroundColor.rawValue] = t
        }
        
        let url = self.examples[self.exampleFormatButton.indexOfSelectedItem]
        
        if self.htmlFormatButton.state == .on {
            webView.isHidden = true
            service?.htmlColorize(url: url, overrideSettings: settings as NSDictionary) { (html, extra, error) in
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(error != nil ? error!.localizedDescription : html, baseURL: nil)
                    self.progressIndicator.stopAnimation(self)
                    self.webView.isHidden = false
                }
            }
        } else {
            textScrollView.isHidden = true
            service?.rtfColorize(url: url, overrideSettings: settings as NSDictionary) { (response, effective_settings, error) in
                let text: NSAttributedString
                if let e = error {
                    text = NSAttributedString(string: e.localizedDescription)
                } else {
                    text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Conversion error!")
                }
                
                DispatchQueue.main.async {
                    self.textView.textStorage?.setAttributedString(text)
                    if let bg = effective_settings[SCSHSettings.Key.rtfBackgroundColor.rawValue] as? String, let c = NSColor(fromHexString: bg) {
                        self.textView.backgroundColor = c
                    } else {
                        self.textView.backgroundColor = .clear
                    }
                    self.progressIndicator.stopAnimation(self)
                    self.textScrollView.isHidden = false
                }
            }
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let settings = self.getCurrentSettings()
        
        service?.setSettings(settings as NSDictionary) { _ in 
            DispatchQueue.main.async {
                NSApplication.shared.windows.forEach { (window) in
                    if let c = window.contentViewController as? ViewController {
                        c.refresh(nil)
                    }
                }
                
                self.dismiss(sender)
            }
        }
    }
}
