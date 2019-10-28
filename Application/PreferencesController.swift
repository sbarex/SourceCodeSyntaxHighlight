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
    // MARK: - Outlets
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var highlightPathPopup: NSPopUpButton!
    
    @IBOutlet weak var modePopupButton: NSPopUpButton!
    
    @IBOutlet weak var wrapPopupButton: NSPopUpButton!
    @IBOutlet weak var lineLengthTextField: NSTextField!
    @IBOutlet weak var lineLengthLabel: NSTextField!
    
    @IBOutlet weak var lineNumbersPopupButton: NSPopUpButton!
    
    @IBOutlet weak var tabsPopupButton: NSPopUpButton!
    @IBOutlet weak var spacesSlider: NSSlider!
    
    @IBOutlet weak var lightThemePopup: NSPopUpButton!
    @IBOutlet weak var darkThemePopup: NSPopUpButton!
    
    @IBOutlet weak var extraArgumentsTextField: NSTextField!
    @IBOutlet weak var exampleFormatButton: NSPopUpButton!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var textScrollView: NSScrollView!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var themeControl: NSSegmentedControl!
    
    @IBOutlet weak var fontText: NSTextField!
    
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    // MARK: - attributes
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    var settings: [String: Any]?
    /// List of highlight presents on the system.
    private var highlightPaths: [(path: String, ver: String, embedded: Bool)] = []
    /// List of themes.
    private var themes: [NSDictionary] = []
    /// List of example files.
    private var examples: [URL] = []
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let macosThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        self.themeControl.selectedSegment = macosThemeLight ? 0 : 1
        
        // Populate the example files list.
        self.exampleFormatButton.removeAllItems()
        if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                self.examples = files.sorted(by: { (a, b) -> Bool in
                    a.lastPathComponent < b.lastPathComponent
                })
                
                for file in self.examples {
                    self.exampleFormatButton.addItem(withTitle: file.lastPathComponent)
                }
            }
        }
        
        if let service = self.service {
            service.getSettings() {
                self.settings = $0 as? [String: Any]
                
                self.processNextInitTask()
            }
        }
    }
    
    override func viewDidAppear() {
       // any additional code
       view.window!.styleMask.remove(.resizable)
    }

    private var internal_state = 0
    private func processNextInitTask() {
        internal_state += 1
        
        switch internal_state {
        case 1:
            DispatchQueue.main.async {
                // Fetch highlight path.
                self.highlightPaths = []
                self.service?.locateHighlight { (paths) in
                    let currentHighlightPath = self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String
                    var found = false
                    for info in paths {
                        guard info.count == 3, let path = info[0] as? String, let ver = info[1] as? String, let embedded = info[2] as? Bool else {
                            continue
                        }
                        self.highlightPaths.append((path: embedded ? "-" : path, ver: ver, embedded: embedded))
                        
                        if let p = currentHighlightPath, (p == "-" && embedded) || p == path {
                            if embedded {
                                self.settings?[SCSHSettings.Key.highlightPath.rawValue] = "-"
                            }
                            found = true
                        }
                    }
                    if !found, let p = currentHighlightPath {
                        // Append current customized path.
                        self.highlightPaths.append((path: p, ver: "", embedded: false))
                    }
                    
                    self.processNextInitTask()
                }
            }
            
        case 2:
            // Fetch themes.
            DispatchQueue.main.async {
                self.service?.getThemes(highlight: self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String ?? "-") { (results, error) in
                    self.themes = results
                    
                    self.processNextInitTask()
                    // print(results)
                }
            }
            
        case 3:
            // Intialize all gui controls.
            DispatchQueue.main.async {
                // Highlight Path
                self.highlightPathPopup.removeAllItems()
                
                let currentHighlightPath = self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String
                for (i, path) in self.highlightPaths.enumerated() {
                    let m = NSMenuItem(title: "\(path.embedded ? "Internal" : path.path)\(path.ver != "" ? " (ver. \(path.ver))" : "")", action: nil, keyEquivalent: "")
                    m.tag = i
                    self.highlightPathPopup.menu?.addItem(m)
                    if currentHighlightPath == path.path {
                        self.highlightPathPopup.select(m)
                    }
                    if path.embedded && self.highlightPaths.count > 1 {
                        let sep = NSMenuItem.separator()
                        sep.tag = -2
                        self.highlightPathPopup.menu?.addItem(sep)
                    }
                }
                let sep = NSMenuItem.separator()
                sep.tag = -2
                self.highlightPathPopup.menu?.addItem(sep)
                
                let m = NSMenuItem(title: "other…", action: nil, keyEquivalent: "")
                m.tag = -1
                self.highlightPathPopup.menu?.addItem(m)
                self.highlightPathPopup.isEnabled = true
                
                // HTML/RTF format
                let format = self.settings?[SCSHSettings.Key.format.rawValue] as? String ?? SCSHFormat.html.rawValue
                self.modePopupButton.isEnabled = true
                self.modePopupButton.selectItem(at: format == SCSHFormat.html.rawValue ? 0 : 1)
                
                // Word wrap.
                if let i = self.settings?[SCSHSettings.Key.wordWrap.rawValue] as? Int, let ln = SCSHWordWrap(rawValue: i) {
                    switch ln {
                    case .off:
                        self.wrapPopupButton.selectItem(at: 0)
                    case .simple:
                        self.wrapPopupButton.selectItem(at: 1)
                    case .standard:
                        self.wrapPopupButton.selectItem(at: 2)
                    }
                } else {
                    self.wrapPopupButton.selectItem(at: 0)
                }
                self.wrapPopupButton.isEnabled = true
                
                // Line length.
                self.lineLengthLabel.isHidden = self.wrapPopupButton.indexOfSelectedItem == 0
                self.lineLengthTextField.isHidden = self.lineLengthLabel.isHidden
                self.lineLengthTextField.isEnabled = true
                self.lineLengthTextField.integerValue = self.settings?[SCSHSettings.Key.lineLength.rawValue] as? Int ?? 80
                
                // Line numbers.
                if let v = self.settings?[SCSHSettings.Key.lineNumbers.rawValue] as? Bool {
                    if !v {
                        self.lineNumbersPopupButton.selectItem(at: 0)
                    } else {
                        self.lineNumbersPopupButton.selectItem(at: self.settings?[SCSHSettings.Key.lineNumbersOmittedWrap.rawValue] as? Bool ?? true ? 2 : 1)
                    }
                } else {
                    self.lineNumbersPopupButton.selectItem(at: 0)
                }
                self.lineNumbersPopupButton.isEnabled = true
                self.lineNumbersPopupButton.menu?.item(at: 2)?.isEnabled = self.wrapPopupButton.indexOfSelectedItem != 0
                
                // Tab/spaces.
                let spaces = self.settings?[SCSHSettings.Key.tabSpaces.rawValue] as? Int ?? 0
                self.tabsPopupButton.isEnabled = true
                self.tabsPopupButton.selectItem(at: spaces > 0 ? 1 : 0)
                self.spacesSlider.isEnabled = spaces > 0
                self.spacesSlider.isHidden = spaces <= 0
                self.spacesSlider.integerValue = spaces > 0 ? spaces : 4
                
                // Extra.
                self.extraArgumentsTextField.isEnabled = true
                self.extraArgumentsTextField.stringValue = self.settings?[SCSHSettings.Key.extraArguments.rawValue] as? String ?? ""
                
                // Refresh font label.
                self.refreshFontPanel()
                
                // Poppulate theme list.
                self.updateThemes()
                
                // Example preview.
                self.exampleFormatButton.isEnabled = self.examples.count > 0
                self.themeControl.isEnabled = self.examples.count > 0
                self.refreshButton.isEnabled = self.examples.count > 0
                
                self.webView.isHidden = self.modePopupButton.indexOfSelectedItem != 0
                self.textScrollView.isHidden = !self.webView.isHidden
                
                self.saveButton.isEnabled = true
                
                self.refresh(nil)
            }
        default:
            return
        }
    }
    
    /// Update the theme popups.
    private func updateThemes() {
        self.lightThemePopup.removeAllItems()
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
            }
            if name == self.settings?[SCSHSettings.Key.darkTheme.rawValue] as? String {
                darkIndex = i
            }
            i += 1
        }
        if lightIndex >= 0 {
            self.lightThemePopup.selectItem(at: lightIndex)
        }
        if darkIndex >= 0 {
            self.darkThemePopup.selectItem(at: darkIndex)
        }
        
        self.lightThemePopup.isEnabled = self.themes.count > 0
        self.darkThemePopup.isEnabled = self.themes.count > 0
        if self.themes.count == 0 {
            self.lightThemePopup.addItem(withTitle: "No theme available")
            self.darkThemePopup.addItem(withTitle: "No theme available")
        }
    }
    
    /// Update font preview.
    private func refreshFontPanel() {
        let ff: String = self.settings?[SCSHSettings.Key.fontFamily.rawValue] as? String ?? ""
        let fp: Float = self.settings?[SCSHSettings.Key.fontSize.rawValue] as? Float ?? 10
        self.fontText.stringValue = String(format:"%@ %.1f pt", ff, fp)
        
        self.fontText.font = NSFont(name: ff, size: CGFloat(fp))
    }
    
    /// Get current font.
    private func getCurrentSettings() -> [String: Any] {
        var settings: [String: Any] = [
            SCSHSettings.Key.highlightPath.rawValue: self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String ?? "-",
            
            SCSHSettings.Key.lineNumbers.rawValue: self.lineNumbersPopupButton.indexOfSelectedItem > 0,
            SCSHSettings.Key.lineNumbersOmittedWrap.rawValue: self.lineNumbersPopupButton.indexOfSelectedItem == 2,
            
            SCSHSettings.Key.wordWrap.rawValue: self.wrapPopupButton.indexOfSelectedItem,
            SCSHSettings.Key.lineLength.rawValue: self.lineLengthTextField.integerValue,
            
            SCSHSettings.Key.tabSpaces.rawValue: self.tabsPopupButton.indexOfSelectedItem == 1 ? self.spacesSlider.integerValue : 0,
            
            SCSHSettings.Key.extraArguments.rawValue: self.extraArgumentsTextField.stringValue,
            SCSHSettings.Key.format.rawValue: self.modePopupButton.indexOfSelectedItem == 0 ? "html" : "rtf",
        ]
        
        let lightTheme: [String: Any]
        if self.themes.count > 0, let t = self.themes[self.lightThemePopup.indexOfSelectedItem] as? [String: Any] {
            lightTheme = t
        } else {
            lightTheme = [:]
        }
        let darkTheme: [String: Any]
        if self.themes.count > 0, let t = self.themes[self.darkThemePopup.indexOfSelectedItem] as? [String: Any] {
            darkTheme = t
        } else {
            darkTheme = [:]
        }
        
        if let t = lightTheme["name"] as? String {
            settings[SCSHSettings.Key.lightTheme.rawValue] = t
        }
        if let t = darkTheme["name"] as? String {
            settings[SCSHSettings.Key.darkTheme.rawValue] = t
        }
        
        if let v = self.settings?[SCSHSettings.Key.fontFamily.rawValue] as? String {
            settings[SCSHSettings.Key.fontFamily.rawValue] = v
        }
        if let v = self.settings?[SCSHSettings.Key.fontSize.rawValue] as? Float {
            settings[SCSHSettings.Key.fontSize.rawValue] = v
        }
        
        settings[SCSHSettings.Key.rtfLightBackgroundColor.rawValue] = lightTheme["bg-color"] as? String ?? ""
            
        settings[SCSHSettings.Key.rtfDarkBackgroundColor.rawValue] = darkTheme["bg-color"] as? String ?? ""
        
        return settings
    }
    
    // MARK: - Actions
    @IBAction func handleConvertTabsToSpaces(_ sender: NSPopUpButton) {
        self.spacesSlider.isEnabled = sender.indexOfSelectedItem == 1
        self.spacesSlider.isHidden = !self.spacesSlider.isEnabled
    }

    /// Handle format output change.
    @IBAction func handleFormatChange(_ sender: NSPopUpButton) {
        self.webView.isHidden = sender.indexOfSelectedItem != 0
        self.textScrollView.isHidden = sender.indexOfSelectedItem == 0
        refresh(nil)
    }

    /// Handle word wrap change.
    @IBAction func handleWordWrapChange(_ sender: NSPopUpButton) {
        self.lineLengthTextField.isHidden = sender.indexOfSelectedItem == 0
        self.lineLengthLabel.isHidden = sender.indexOfSelectedItem == 0
        
        if sender.indexOfSelectedItem == 0 {
            if self.lineNumbersPopupButton.indexOfSelectedItem == 2 {
                self.lineNumbersPopupButton.selectItem(at: 1)
            }
            self.lineNumbersPopupButton.menu?.item(at: 2)?.isEnabled = false
        } else {
            self.lineNumbersPopupButton.menu?.item(at: 2)?.isEnabled = true
        }
        
        refresh(nil)
    }
    
    /// Handle theme change.
    @IBAction func handleThemeChange(_ sender: NSPopUpButton) {
        if (sender == self.lightThemePopup && self.themeControl.selectedSegment == 0) || sender == self.darkThemePopup && self.themeControl.selectedSegment == 1 {
            self.refresh(sender)
        }
    }
    
    /// Handle highlight theme change.
    @IBAction func handleHighLightPath(_ sender: NSPopUpButton) {
        var changed = false
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            // Browse for a custom path.
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
                    self.highlightPaths.append((path: url.path, ver: "", embedded: false))
                    
                    let m = NSMenuItem(title: url.path, action: nil, keyEquivalent: "")
                    m.tag = self.highlightPaths.count-1
                    self.highlightPathPopup.menu?.insertItem(m, at: sender.numberOfItems-1)
                    sender.select(m)
                    
                    self.settings?[SCSHSettings.Key.highlightPath.rawValue] = url.path
                    changed = true
                } else {
                    // Restore previous selected path.
                    if let i = self.highlightPaths.firstIndex(where: { $0.path == self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String }), let m = sender.menu?.item(withTag: i) {
                        sender.select(m)
                    } else {
                        sender.selectItem(at: 0)
                    }
                }
            }
        } else {
            if let i = sender.selectedItem?.tag, i >= 0, i < self.highlightPaths.count {
                self.settings?[SCSHSettings.Key.highlightPath.rawValue] = self.highlightPaths[i].path
                changed = true
            }
        }
        
        guard changed else {
            return
        }
        
        refresh()
        
        self.lightThemePopup.removeAllItems()
        self.lightThemePopup.isEnabled = false
        self.lightThemePopup.addItem(withTitle: "loading…")
        
        self.darkThemePopup.removeAllItems()
        self.darkThemePopup.isEnabled = false
        self.darkThemePopup.addItem(withTitle: "loading…")
        
        self.service?.getThemes(highlight: self.settings?[SCSHSettings.Key.highlightPath.rawValue] as? String ?? "-") { (results, error) in
            self.themes = results
            
            DispatchQueue.main.async {
                self.updateThemes()
            }
            // print(results)
        }
    }
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: Any) {
        let fontPanel = NSFontPanel.shared
        if let font = NSFont(name: self.settings?[SCSHSettings.Key.fontFamily.rawValue] as? String ?? "Menlo", size: self.settings?[SCSHSettings.Key.fontSize.rawValue] as? CGFloat ?? 10) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    /// Handle the selection of a font.
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
        
        self.refreshFontPanel()
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
    
    /// Refresh the preview panel.
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
        
        if self.modePopupButton.indexOfSelectedItem == 0 {
            webView.isHidden = true
            service?.htmlColorize(url: url, overrideSettings: settings as NSDictionary) { (html, extra, error) in
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(html, baseURL: nil)
                    self.progressIndicator.stopAnimation(self)
                    self.webView.isHidden = false
                }
            }
        } else {
            textScrollView.isHidden = true
            service?.rtfColorize(url: url, overrideSettings: settings as NSDictionary) { (response, effective_settings, error) in
                let text: NSAttributedString
                if let e = error {
                    text = NSAttributedString(string: String(data: response, encoding: .utf8) ?? e.localizedDescription)
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
    
    /// Save the settings.
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
