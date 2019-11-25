//
//  PreferencesViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 08/11/2019.
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

typealias SuppressedExtension = (ext: String, uti: String)

class UTIDesc: Equatable {
    /// Uniform Type Identifiers.
    let uti: UTI
    
    /// Return if the system know the file extensions or mime types for the UTI.
    lazy var isValid: Bool = {
        if uti.UTI.hasPrefix("public.") {
            return true
        }
        return uti.mimeTypes.count > 0 || uti.extensions.count > 0
    }()
    
    lazy var description: String = {
        let description = self.uti.description
        return description.isEmpty ? self.uti.UTI : description
    }()
    
    lazy var extensions: [String] = {
        return self.uti.extensions
    }()
    
    /// Full description with supported extensions.
    lazy var fullDescription: String = {
        var label: String = self.description
        let exts = self.extensions
        if exts.count > 0 {
            label += " (." + exts.joined(separator: ", .") + ")"
        }
        return label
    }()
    
    lazy var icon: NSImage? = {
        return self.uti.icon
    }()
    
   
    lazy var suppressedExtensions: [SuppressedExtension] = {
        var e: [SuppressedExtension] = []
        for ext in extensions {
            if let u = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() {
                if u as String != uti.UTI {
                    e.append((ext: ext, uti: u as String))
                }
            }
        }
        return e
    }()
    
    init(UTI type: String) {
        self.uti = UTI(type)
    }
    
    func getSuppressedExtensions(handledUti: [String]) -> [(suppress: SuppressedExtension, handled: Bool)] {
        var e: [(suppress: SuppressedExtension, handled: Bool)] = []
        for suppress in suppressedExtensions {
            e.append((suppress: suppress, handled: handledUti.contains(suppress.uti)))
        }
        return e
    }
    
    // MARK: - Equatable
    static func == (lhs: UTIDesc, rhs: UTIDesc) -> Bool {
        return lhs.uti.UTI == rhs.uti.UTI
    }
}

class PreferencesViewController: NSViewController {
    // MARK: -
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var filterButton: NSButton!
    
    @IBOutlet weak var highlightPathPopup: NSPopUpButton!
    @IBOutlet weak var formatModeControl: NSSegmentedControl!
    
    @IBOutlet weak var themeLightIcon: NSButton!
    @IBOutlet weak var themeLightLabel: NSTextField!
    @IBOutlet weak var themeDarkIcon: NSButton!
    @IBOutlet weak var themeDarkLabel: NSTextField!

    @IBOutlet weak var customCSSButton: NSButton!
    @IBOutlet weak var customCSSImage: NSImageView!
    
    @IBOutlet weak var fontPreviewTextField: NSTextField!
    @IBOutlet weak var fontChooseButton: NSButton!
    
    @IBOutlet weak var wordWrapPopup: NSPopUpButton!
    @IBOutlet weak var lineLengthTextField: NSTextField!
    @IBOutlet weak var lineLenghLabel: NSTextField!
    @IBOutlet weak var lineNumbersPopup: NSPopUpButton!
    @IBOutlet weak var tabSpacesSlider: NSSlider!
    @IBOutlet weak var argumentsTextField: NSTextField!
    @IBOutlet weak var debugButton: NSButton!
    
    @IBOutlet weak var examplesPopup: NSPopUpButton!
    
    @IBOutlet weak var previewThemeControl: NSSegmentedControl!
    @IBOutlet weak var refreshIndicator: NSProgressIndicator!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var textView: NSTextView!
    
    @IBOutlet weak var saveButton: NSButton!
    
    @IBOutlet weak var utiTitleTextField: NSTextField!
    @IBOutlet weak var extensionsTitleTextField: NSTextField!
    @IBOutlet weak var utiErrorButton: NSButton!
    @IBOutlet weak var utiSpecificArgumentsTextField: NSTextField!
    
    @IBOutlet weak var utiThemeCheckbox: NSButton!
    @IBOutlet weak var utiThemeLightIcon: NSButton!
    @IBOutlet weak var utiThemeLightLabel: NSTextField!
    @IBOutlet weak var utiThemeDarkIcon: NSButton!
    @IBOutlet weak var utiThemeDarkLabel: NSTextField!
    
    @IBOutlet weak var utiCustomCSSCheckbox: NSButton!
    @IBOutlet weak var utiCustomCSSButton: NSButton!
    @IBOutlet weak var utiCustomCSSImage: NSImageView!
    
    @IBOutlet weak var utiFontChecbox: NSButton!
    @IBOutlet weak var utiFontPreviewTextField: NSTextField!
    @IBOutlet weak var utiFontChooseButton: NSButton!
    
    @IBOutlet weak var utiWordWrapChecbox: NSButton!
    @IBOutlet weak var utiWordWrapPopup: NSPopUpButton!
    @IBOutlet weak var utiLineLengthTextField: NSTextField!
    @IBOutlet weak var utiLineLenghLabel: NSTextField!
    
    @IBOutlet weak var utiLineNumberChecbox: NSButton!
    @IBOutlet weak var utiLineNumbersPopup: NSPopUpButton!
    
    @IBOutlet weak var utiTabSpacesChecbox: NSButton!
    @IBOutlet weak var utiTabSpacesSlider: NSSlider!
    
    @IBOutlet weak var utiArgumentsChecbox: NSButton!
    @IBOutlet weak var utiArgumentsTextField: NSTextField!
    
    @IBOutlet weak var utiPreprocessorCheckbox: NSButton!
    @IBOutlet weak var utiPreprocessorTextField: NSTextField!
    
    @IBOutlet weak var utiPreviewThemeControl: NSSegmentedControl!
    @IBOutlet weak var utiRefreshIndicator: NSProgressIndicator!
    @IBOutlet weak var utiRefreshButton: NSButton!
    @IBOutlet weak var utiWebView: WKWebView!
    @IBOutlet weak var utiScrollView: NSScrollView!
    @IBOutlet weak var utiTextView: NSTextView!
    
    @IBOutlet weak var utiDetailView: NSView!
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    /// List of themes.
    var themes: [SCSHTheme] = [] {
        didSet {
            updateThemes()
        }
    }
    
    /// Gliobal settings.
    var settings: SCSHSettings?
    
    typealias HighlightPath = (path: String, ver: String, embedded: Bool)
    var highlightPaths: [HighlightPath] = []
    
    /// All supported UTIs.
    var allFileTypes: [UTIDesc] = []
    
    /// Filtered supported UTIs.
    var fileTypes: [UTIDesc] = [] {
        didSet {
            guard oldValue != fileTypes else {
                return
            }
            tableView?.reloadData()
            tableView?.isEnabled = fileTypes.count > 0
        }
    }
    
    /// Filter for the UTI description.
    var filter: String = "" {
        didSet {
            guard oldValue != filter else {
                return
            }
            
            filterUTIs()
        }
    }
    
    /// Show only UTI with customized settings.
    var filterOnlyChanged: Bool = false {
        didSet {
            guard oldValue != filterOnlyChanged else {
                return
            }
            
            filterUTIs()
        }
    }
    
    /// Update a theme icon.
    func refreshTheme(_ theme: SCSHTheme?, button: NSButton, label: NSTextField) {
        if let t = theme {
            button.image = t.getImage(size: button.bounds.size, font: NSFont(name: "Menlo", size: 4) ?? NSFont.systemFont(ofSize: 4))
            let text = NSMutableAttributedString()
            if !t.desc.isEmpty {
                text.append(NSAttributedString(string: "\(t.desc)\n", attributes: [.font: NSFont.labelFont(ofSize: NSFont.systemFontSize)]))
            }
            text.append(NSAttributedString(string: "\(t.name)", attributes: [.font: NSFont.labelFont(ofSize: NSFont.smallSystemFontSize)]))
            
            label.attributedStringValue = text
        } else {
            button.image = nil
            label.stringValue = "-"
        }
    }
    
    var customCSS: String? = nil
    var lightTheme: SCSHTheme? {
        didSet {
            refreshTheme(lightTheme, button: themeLightIcon, label: themeLightLabel)
            refreshPreview(self)
        }
    }
    var darkTheme: SCSHTheme? {
        didSet {
            refreshTheme(darkTheme, button: themeDarkIcon, label: themeDarkLabel)
            refreshPreview(self)
        }
    }
    
    var utiCustomCSS: String? = nil
    var utiLightTheme: SCSHTheme? {
        didSet {
            refreshTheme(utiLightTheme, button: utiThemeLightIcon, label: utiThemeLightLabel)
            refreshUtiPreview(self)
        }
    }
    var utiDarkTheme: SCSHTheme? {
        didSet {
            refreshTheme(utiDarkTheme, button: utiThemeDarkIcon, label: utiThemeDarkLabel)
            refreshUtiPreview(self)
        }
    }
    
    /// UTI settings in the detail view.
    var currentUTISettings: SCSHSettings? {
        didSet {
            if let utiSettings = oldValue {
                saveCurrentUtiSettings(utiSettings.uti)
            }
            
            if let currentUTISettings = self.currentUTISettings {
                guard let format = fileTypes.first(where: { $0.uti.UTI == currentUTISettings.uti }) else {
                    utiDetailView.isHidden = true
                    return
                }
                
                utiErrorButton.isHidden = format.getSuppressedExtensions(handledUti: allFileTypes.map({ $0.uti.UTI })).count == 0
                
                utiTitleTextField.stringValue = format.description
                utiTitleTextField.toolTip = format.uti.UTI
                extensionsTitleTextField.stringValue = format.extensions.count > 0 ? "." + format.extensions.joined(separator: ", .") : ""
                utiSpecificArgumentsTextField.stringValue = currentUTISettings.utiExtra ?? ""
                
                utiThemeCheckbox.state = currentUTISettings.lightTheme != nil ? .on : .off
                utiThemeLightIcon.isEnabled = utiThemeCheckbox.state == .on && themes.count > 0
                utiThemeDarkIcon.isEnabled = utiThemeCheckbox.state == .on && themes.count > 0
                
                if let theme = getTheme(name: currentUTISettings.lightTheme) {
                    utiLightTheme = theme
                } else {
                    utiLightTheme = lightTheme
                }
                if let theme = getTheme(name: currentUTISettings.darkTheme) {
                    utiDarkTheme = theme
                } else {
                    utiDarkTheme = darkTheme
                }
                utiCustomCSS = currentUTISettings.css
                
                utiCustomCSSCheckbox.isEnabled = formatModeControl.selectedSegment == 0
                utiCustomCSSCheckbox.state = utiCustomCSS != nil && !utiCustomCSS!.isEmpty ? .on : .off
                utiCustomCSSButton.isEnabled = utiCustomCSSCheckbox.state == .on && utiCustomCSSCheckbox.isEnabled
                utiCustomCSSImage.image = NSImage(named: utiCustomCSSCheckbox.state == .on ? NSImage.statusAvailableName : NSImage.statusNoneName)
                    
                utiFontChecbox.state = currentUTISettings.fontFamily != nil ? .on : .off
                utiFontPreviewTextField.isEnabled = utiFontChecbox.state == .on
                utiFontChooseButton.isEnabled = utiFontChecbox.state == .on
                refreshFontPanel(withFontFamily: currentUTISettings.fontFamily ?? settings?.fontFamily ?? "Menlo", size: currentUTISettings.fontSize ?? settings?.fontSize ?? 12, isGlobal: false)
                
                utiWordWrapChecbox.state = currentUTISettings.wordWrap != nil ? .on : .off
                utiWordWrapPopup.isEnabled = utiWordWrapChecbox.state == .on
                switch currentUTISettings.wordWrap ?? settings?.wordWrap ?? .off {
                case .off:
                    utiWordWrapPopup.selectItem(at: 0)
                    
                    utiLineLengthTextField.isHidden = true
                    utiLineLenghLabel.isHidden = true
                    
                    utiLineNumbersPopup.menu?.item(at: 2)?.isEnabled = false
                case .simple:
                    utiWordWrapPopup.selectItem(at: 1)
                    
                    utiLineLengthTextField.isHidden = false
                    utiLineLenghLabel.isHidden = false
                    
                    utiLineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
                case .standard:
                    utiWordWrapPopup.selectItem(at: 2)
                    
                    utiLineLengthTextField.isHidden = false
                    utiLineLenghLabel.isHidden = false
                    
                    utiLineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
                }
                utiLineLengthTextField.integerValue = currentUTISettings.lineLength ?? settings?.lineLength ?? 80
                
                utiLineNumberChecbox.state = currentUTISettings.lineNumbers != nil ? .on : .off
                utiLineNumbersPopup.isEnabled = utiLineNumberChecbox.state == .on
                switch currentUTISettings.lineNumbers ?? settings?.lineNumbers ?? .hidden {
                case .hidden:
                    utiLineNumbersPopup.selectItem(at: 0)
                case .visible(let omittingWrapLines):
                    utiLineNumbersPopup.selectItem(at: omittingWrapLines ? 2 : 1)
                }
                
                utiTabSpacesChecbox.state = currentUTISettings.tabSpaces != nil ? .on : .off
                utiTabSpacesSlider.isEnabled = utiTabSpacesChecbox.state == .on
                utiTabSpacesSlider.integerValue = currentUTISettings.tabSpaces ?? settings?.tabSpaces ?? 4
                
                utiArgumentsChecbox.state = currentUTISettings.extra != nil ? .on : .off
                utiArgumentsTextField.isEnabled = utiArgumentsChecbox.state == .on
                utiArgumentsTextField.stringValue = currentUTISettings.extra ?? settings?.extra ?? ""
                
                utiPreprocessorCheckbox.state = currentUTISettings.preprocessor != nil ? .on : .off
                utiPreprocessorTextField.isEnabled = utiPreprocessorCheckbox.state == .on
                utiPreprocessorTextField.stringValue = currentUTISettings.preprocessor ?? ""
                
                refreshUtiPreview(self)
                
                utiDetailView.isHidden = false
                
                if let i = fileTypes.firstIndex(where: { $0.uti.UTI == currentUTISettings.uti }) {
                    if tableView.selectedRow != i {
                        tableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                        tableView.scrollRowToVisible(i)
                    }
                } else {
                    tableView.deselectAll(nil)
                }
            } else {
                utiDetailView.isHidden = true
                if tableView.selectedRow != -1 {
                    tableView.deselectAll(nil)
                }
            }
        }
    }
    
    typealias ExampleInfo = (url: URL, title: String, uti: String)
    /// List of example files.
    private var examples: [ExampleInfo] = []
    
    deinit {
        // Remove the theme observer.
        NotificationCenter.default.removeObserver(self, name: .themeDidSaved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .themeDidDeleted, object: nil)
    }
    
    // MARK: -
    override func viewDidLoad() {
        for btn in [themeLightIcon, themeDarkIcon, utiThemeLightIcon, utiThemeDarkIcon] {
            // Add round corners and border to the theme icons.
            btn?.wantsLayer = true
            btn?.layer?.cornerRadius = 8
            btn?.layer?.borderWidth = 1
            btn?.layer?.borderColor = NSColor.gridColor.cgColor
        }
        
        // Populate UTIs list.
        allFileTypes = (NSApplication.shared.delegate as? AppDelegate)?.fetchHandledUTIs() ?? []
        fileTypes = allFileTypes
        
        let defaults = UserDefaults.standard
        /// Current OS style.
        let macosThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        previewThemeControl.setSelected(true, forSegment: macosThemeLight ? 0 : 1)
        utiPreviewThemeControl.setSelected(true, forSegment: macosThemeLight ? 0 : 1)
        
        // Populate the example files list.
        examples = (NSApplication.shared.delegate as? AppDelegate)?.getAvailableExamples() ?? []
        examplesPopup.removeAllItems()
        examplesPopup.addItem(withTitle: "Theme colors")
        examplesPopup.menu?.addItem(NSMenuItem.separator())
        for file in examples {
            let m = NSMenuItem(title: file.title, action: nil, keyEquivalent: "")
            m.toolTip = file.uti
            examplesPopup.menu?.addItem(m)
        }
        examplesPopup.isEnabled = true
        
        for view in [webView, scrollView, utiWebView, utiScrollView] {
            view?.wantsLayer = true;
            view?.layer?.cornerRadius = 4
            view?.layer?.masksToBounds = true
            view?.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        
        utiDetailView.isHidden = true
        
        fetchSettings()
        
        // Register the objservers for theme save and delete notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeDidSaved(_:)), name: .themeDidSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeDidDeleted(_:)), name: .themeDidDeleted, object: nil)
    }
    
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
        
        filter = self.searchField.stringValue
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "WarningUTISegue", let vc = segue.destinationController as? WarningUTIViewController {
            vc.data = fileTypes.first(where: { $0.uti.UTI == currentUTISettings?.uti })?.getSuppressedExtensions(handledUti: allFileTypes.map( { $0.uti.UTI } )) ?? []
        } else if segue.identifier == "CustomCSSSegue", let vc = segue.destinationController as? CSSControlView {
            if sender as? NSButton == customCSSButton {
                vc.cssCode = customCSS ?? ""
                vc.isUTIWarningHidden = true
                vc.handler = { css in
                    self.customCSS = css.isEmpty ? nil : css
                    self.customCSSImage.image = NSImage(named: !css.isEmpty ? NSImage.statusAvailableName : NSImage.statusNoneName)
                    self.refreshPreview(self)
                }
            } else {
                vc.cssCode = utiCustomCSS ?? ""
                vc.isUTIWarningHidden = false
                vc.handler = { css in
                    self.utiCustomCSS = css.isEmpty ? nil : css
                    self.utiCustomCSSImage.image = NSImage(named: !css.isEmpty ? NSImage.statusAvailableName : NSImage.statusNoneName)
                    self.refreshUtiPreview(self)
                }
            }
        } else if segue.identifier == "ThemeSegue", let vc = segue.destinationController as? ThemeSelectorViewController {
            vc.allThemes = self.themes.map({ SCSHThemePreview(theme: $0) })
            if let btn = sender as? NSButton {
                vc.style = btn == themeLightIcon || btn == utiThemeLightIcon ? .light : .dark
                
                if btn == themeLightIcon {
                    vc.handler = { theme in
                        self.lightTheme = theme
                    }
                } else if btn == themeDarkIcon {
                    vc.handler = { theme in
                        self.darkTheme = theme
                    }
                } else if btn == utiThemeLightIcon {
                    vc.handler = { theme in
                        self.utiLightTheme = theme
                    }
                } else if btn == utiThemeDarkIcon {
                    vc.handler = { theme in
                        self.utiDarkTheme = theme
                    }
                }
            }
        }
    }
    
    // MARK: - Settings
    
    /// Filter the visible UTIs based on search cryteria.
    func filterUTIs() {
        guard !filter.isEmpty || filterOnlyChanged else {
            fileTypes = self.allFileTypes
            return
        }
        
        let filter = self.filter.lowercased()
        fileTypes = self.allFileTypes.filter({ (uti) -> Bool in
            if filterOnlyChanged && !(settings?.hasCustomizedUTI(uti.uti.UTI) ?? false) {
                return false
            }
            if !filter.isEmpty && !uti.fullDescription.lowercased().contains(filter) && !uti.uti.UTI.lowercased().contains(filter) {
                return false;
            }
            return true
        })
    }
    
    /// Fetch current settings.
    func fetchSettings() {
        guard let service = self.service else {
            return
        }
        service.getSettings() {
            if let s = $0 as? [String: Any] {
                self.settings = SCSHSettings(dictionary: s)
                self.customCSS = self.settings?.css
            }
            
            self.processNextInitTask()
        }
    }
    
    private var internal_state = 0
    /// Execute next initialization task.
    private func processNextInitTask() {
        internal_state += 1
        
        switch internal_state {
        case 1:
            // Fetch highlight path.
            self.highlightPaths = []
            self.service?.locateHighlight { (paths) in
                let currentHighlightPath = self.settings?.highlightProgramPath
                var found = false
                for info in paths {
                    guard info.count == 3, let path = info[0] as? String, let ver = info[1] as? String, let embedded = info[2] as? Bool else {
                        continue
                    }
                    self.highlightPaths.append((path: embedded ? "-" : path, ver: ver, embedded: embedded))
                    
                    if let p = currentHighlightPath, (p == "-" && embedded) || p == path {
                        if embedded {
                            self.settings?.highlightProgramPath = "-"
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
            
        case 2:
            // Fetch themes.
            self.service?.getThemes(highlight: self.settings?.highlightProgramPath ?? "-") { (results, error) in
                var themes: [SCSHTheme] = []
                for dict in results {
                    if let d = dict as? [String: Any], let theme = SCSHTheme(dict: d) {
                        themes.append(theme)
                    }
                }
                
                DispatchQueue.main.async {
                    self.themes = themes
                    self.processNextInitTask()
                }
                // print(results)
            }
            
        case 3:
            // Intialize all gui controls.
            DispatchQueue.main.async {
                self.populateSettings()
            }
        default:
            return
        }
    }
    
    /// Initialize gui elements with current settings.
    func populateSettings() {
        self.highlightPathPopup.removeAllItems()
        
        let currentHighlightPath = self.settings?.highlightProgramPath
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
        self.highlightPathPopup.isEnabled = settings != nil
        
        // HTML/RTF format
        self.formatModeControl.setSelected(true, forSegment: self.settings?.format == .rtf ? 1 : 0)
        self.formatModeControl.isEnabled = settings != nil
        
        customCSSImage.image = NSImage(named: settings?.format == .html && settings?.css != nil && !settings!.css!.isEmpty ? NSImage.statusAvailableName : NSImage.statusNoneName)
        customCSSButton.isEnabled = settings?.format == .html
        
        updateThemes()
        
        if let ln = settings?.wordWrap {
            switch ln {
            case .off:
                wordWrapPopup.selectItem(at: 0)
                lineLenghLabel.isHidden = true
                lineLengthTextField.isHidden = true
            case .simple:
                wordWrapPopup.selectItem(at: 1)
                lineLenghLabel.isHidden = false
                lineLengthTextField.isHidden = false
            case .standard:
                wordWrapPopup.selectItem(at: 2)
                lineLenghLabel.isHidden = false
                lineLengthTextField.isHidden = false
            }
        }
        wordWrapPopup.isEnabled = settings != nil
        
        // Line length.
        lineLengthTextField.integerValue = settings?.lineLength ?? 80
        lineLengthTextField.isEnabled = settings != nil
        
        // Line numbers.
        if let ln = settings?.lineNumbers {
            switch (ln) {
            case .hidden:
                lineNumbersPopup.selectItem(at: 0)
            case .visible(let omittingWrapLines):
                lineNumbersPopup.selectItem(at: omittingWrapLines && wordWrapPopup.indexOfSelectedItem != 0 ? 2 : 1)
            }
        }
        lineNumbersPopup.menu?.item(at: 2)?.isEnabled = wordWrapPopup.indexOfSelectedItem != 0
        lineNumbersPopup.isEnabled = settings != nil
        
        // Tab/spaces.
        let spaces = settings?.tabSpaces ?? 0
        tabSpacesSlider.integerValue = spaces
        tabSpacesSlider.isEnabled = settings != nil
        
        // Extra.
        argumentsTextField.stringValue = settings?.extra ?? ""
        argumentsTextField.isEnabled = settings != nil
        
        fontChooseButton.isEnabled = settings != nil
        refreshFontPanel(withFontFamily: settings?.fontFamily ?? "Menlo", size: settings?.fontSize ?? 12, isGlobal: true)
        
        debugButton.state = settings?.debug ?? false ? .on : .off
        debugButton.isEnabled = settings != nil
        
        previewThemeControl.isEnabled = settings != nil
        refreshButton.isEnabled = settings != nil
        saveButton.isEnabled = settings != nil
        
        if settings != nil {
            refreshPreview(self)
        }
    }
    
    /// Update the theme popups.
    func updateThemes() {
        themeLightIcon.isEnabled = themes.count > 0
        themeDarkIcon.isEnabled = themes.count > 0
        
        lightTheme = getTheme(name: self.settings?.lightTheme)
        darkTheme = getTheme(name: self.settings?.darkTheme)
    }
    
    /// Get theme at the index.
    func getTheme(at index: Int) -> SCSHTheme? {
        if themes.count == 0 || index < 0 || index >= themes.count {
            return nil
        }
        return themes[index]
    }
    
    /// Get a theme by name.
    /// - parameters:
    ///   - name: Name of the theme. If has ! prefix search for a customized theme, otherwise fot a standalone theme.
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
    
    /// Return the url of an example file for specified UTI.
    func getExample(forUTI uti: String)-> URL? {
        if let e = examples.first(where: { $0.uti == currentUTISettings?.uti }) {
            // Exists an example specific for the requested UTI.
            return e.url
        }
        
        // Search an example valid for the file extension associated to the UTI.
        var uti_extensions: [String] = []
        let type = uti as CFString
        if let info = UTTypeCopyDeclaration(type)?.takeRetainedValue() as? [String: AnyObject], let specifications = info["UTTypeTagSpecification"] as? [String: AnyObject], let extensions = specifications["public.filename-extension"] {
            if let e = extensions as? String {
                uti_extensions = [e]
            } else if let ee = extensions as? [String] {
                uti_extensions = ee
            }
        }
        if let e = examples.first(where: { uti_extensions.contains($0.url.pathExtension) }) {
            return e.url
        }
        
        return nil
    }
    
    /// Get current edited global settings, without any custom settings for UTIs.
    func getSettings() -> SCSHSettings {
        let settings = SCSHSettings()
        settings.highlightProgramPath = self.settings?.highlightProgramPath ?? "-"
        settings.format = formatModeControl.selectedSegment == 0 ? .html : .rtf
        
        if let theme = lightTheme {
            settings.lightTheme = (theme.isStandalone ? "" : "!") + theme.name
            settings.rtfLightBackgroundColor = theme.backgroundColor
        }
        if let theme = darkTheme {
            settings.darkTheme = (theme.isStandalone ? "" : "!") + theme.name
            settings.rtfDarkBackgroundColor = theme.backgroundColor
        }
        settings.css = customCSS
        
        settings.fontFamily = self.fontPreviewTextField.font?.fontName
        if let size = self.fontPreviewTextField.font?.pointSize {
            settings.fontSize = Float(size)
        }
        
        switch wordWrapPopup.indexOfSelectedItem {
        case 0:
            settings.wordWrap = .off
        case 1:
            settings.wordWrap = .simple
            settings.lineLength = lineLengthTextField.integerValue
        case 2:
            settings.wordWrap = .standard
            settings.lineLength = lineLengthTextField.integerValue
        default:
            break
        }
        
        switch lineNumbersPopup.indexOfSelectedItem {
        case 0:
            settings.lineNumbers = .hidden
        case 1:
            settings.lineNumbers = .visible(omittingWrapLines: false)
        case 2:
            settings.lineNumbers = .visible(omittingWrapLines: true)
        default:
            break
        }
        
        settings.tabSpaces = tabSpacesSlider.integerValue
        settings.extra = argumentsTextField.stringValue
        
        settings.debug = debugButton.state == .on
        
        return settings
    }
    
    func selectUTI(_ uti: String) -> Bool {
        if let _ = allFileTypes.first(where: { $0.uti.UTI == uti }) {
            currentUTISettings = settings?.getSettings(forUTI: uti)
            return true
        }
        return false
    }
    
    /// Get a settings based on current customized global with apply the customization of active UTI.
    func getUtiSettings() -> SCSHSettings {
        let settings = getSettings()
        
        if utiThemeCheckbox.state == .on {
            if let theme = utiLightTheme {
                settings.lightTheme = (theme.isStandalone ? "" : "!") + theme.name
                settings.rtfLightBackgroundColor = theme.backgroundColor
            }
            if let theme = utiDarkTheme {
                settings.darkTheme = (theme.isStandalone ? "" : "!") + theme.name
                settings.rtfDarkBackgroundColor = theme.backgroundColor
            }
        }
        
        if utiCustomCSSCheckbox.state == .on, let utiCustomCSS = self.utiCustomCSS, !utiCustomCSS.isEmpty {
            settings.css = (settings.css != nil ? settings.css! : "") + utiCustomCSS
        }
        
        if utiFontChecbox.state == .on {
            settings.fontFamily = self.utiFontPreviewTextField.font?.fontName
            if let size = self.utiFontPreviewTextField.font?.pointSize {
                settings.fontSize = Float(size)
            }
        }
        
        if utiWordWrapChecbox.state == .on {
            switch wordWrapPopup.indexOfSelectedItem {
            case 0:
                settings.wordWrap = .off
            case 1:
                settings.wordWrap = .simple
                settings.lineLength = lineLengthTextField.integerValue
            case 2:
                settings.wordWrap = .standard
                settings.lineLength = lineLengthTextField.integerValue
            default:
                break
            }
        }
        
        if utiLineNumberChecbox.state == .on {
            switch lineNumbersPopup.indexOfSelectedItem {
            case 0:
                settings.lineNumbers = .hidden
            case 1:
                settings.lineNumbers = .visible(omittingWrapLines: false)
            case 2:
                settings.lineNumbers = .visible(omittingWrapLines: true)
            default:
                break
            }
        }
        
        if utiTabSpacesChecbox.state == .on {
            settings.tabSpaces = tabSpacesSlider.integerValue
        }
        if utiArgumentsChecbox.state == .on {
            settings.extra = argumentsTextField.stringValue
        }
        if utiPreprocessorCheckbox.state == .on {
            let v = utiPreprocessorTextField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
            settings.preprocessor = v.isEmpty ? nil : v
        } else {
            settings.preprocessor = nil
        }
        
        settings.extra = (settings.extra != nil ? settings.extra! + " " : "") + utiSpecificArgumentsTextField.stringValue
        
        return settings
    }
    
    /// Save current UTI settings in the customized settings.
    func saveCurrentUtiSettings() {
        if let uti = currentUTISettings?.uti {
            saveCurrentUtiSettings(uti)
        }
    }
    
    /// Save the state of the UTI panels to a settings for the specified UTI.
    func saveCurrentUtiSettings(_ uti: String) {
        let utiSettings = SCSHSettings(UTI: uti)
        
        if utiSpecificArgumentsTextField.stringValue.isEmpty {
            utiSettings.utiExtra = nil
        } else {
            utiSettings.utiExtra = utiSpecificArgumentsTextField.stringValue
        }
        
        if utiThemeCheckbox.state == .on {
            if let theme = utiLightTheme {
                utiSettings.lightTheme = (theme.isStandalone ? "" : "!") + theme.name
                utiSettings.rtfLightBackgroundColor = theme.backgroundColor
            }
            if let theme = utiDarkTheme {
                utiSettings.darkTheme = (theme.isStandalone ? "" : "!") + theme.name
                utiSettings.rtfDarkBackgroundColor = theme.backgroundColor
            }
        } else {
            utiSettings.lightTheme = nil
            utiSettings.rtfLightBackgroundColor = nil
            utiSettings.darkTheme = nil
            utiSettings.rtfDarkBackgroundColor = nil
        }
        
        if utiCustomCSSCheckbox.state == .on {
            utiSettings.css = utiCustomCSS
        } else {
            utiSettings.css = nil
        }
        
        if utiFontChecbox.state == .on {
            utiSettings.fontFamily = utiFontPreviewTextField.font?.fontName ?? "Menlo"
            utiSettings.fontSize = Float(utiFontPreviewTextField.font?.pointSize ?? 12)
        } else {
            utiSettings.fontFamily = nil
            utiSettings.fontSize = nil
        }
        
        if utiWordWrapChecbox.state == .on {
            switch utiWordWrapPopup.indexOfSelectedItem {
            case 0:
                utiSettings.wordWrap = .off
                utiSettings.lineLength = nil
            case 1:
                utiSettings.wordWrap = .simple
                utiSettings.lineLength = utiLineLenghLabel.integerValue
            case 2:
                utiSettings.wordWrap = .standard
                utiSettings.lineLength = utiLineLenghLabel.integerValue
            default:
                utiSettings.wordWrap = nil
                utiSettings.lineLength = nil
            }
        } else {
            utiSettings.wordWrap = nil
            utiSettings.lineLength = nil
        }
        
        if utiLineNumberChecbox.state == .on {
            switch utiLineNumbersPopup.indexOfSelectedItem {
            case 0:
                utiSettings.lineNumbers = .hidden
            case 1:
                utiSettings.lineNumbers = .visible(omittingWrapLines: false)
            case 2:
                if let ww = utiSettings.wordWrap {
                    utiSettings.lineNumbers = .visible(omittingWrapLines: ww != .off)
                } else {
                    utiSettings.lineNumbers = .visible(omittingWrapLines: false)
                }
            default:
                utiSettings.lineNumbers = nil
            }
        } else {
            utiSettings.lineNumbers = nil
        }
        
        if utiTabSpacesChecbox.state == .on {
            utiSettings.tabSpaces = utiTabSpacesSlider.integerValue
        } else {
            utiSettings.tabSpaces = nil
        }
        
        if utiArgumentsChecbox.state == .on {
            utiSettings.extra = utiArgumentsTextField.stringValue
        } else {
            utiSettings.extra = nil
        }
        
        if utiPreprocessorCheckbox.state == .on {
            let v = utiPreprocessorTextField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
            utiSettings.preprocessor = v.isEmpty ? nil : v
        } else {
            utiSettings.preprocessor = nil
        }
        
        if utiSettings.isCustomized {
            settings?.setUTISettings(utiSettings)
        } else {
            _ = settings?.removeUTISettings(uti: utiSettings.uti)
        }
        
        if let i = fileTypes.firstIndex(where: { $0.uti.UTI == utiSettings.uti }) {
            tableView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: 2))
        }
    }
    
    // MARK: -
    
    /// Handle word wrap change.
    @IBAction func handleWordWrapChange(_ sender: NSPopUpButton) {
        let lineTextField = sender == wordWrapPopup ? lineLengthTextField : utiLineLengthTextField
        let lineTextLabel = sender == wordWrapPopup ? lineLenghLabel : utiLineLenghLabel
        let lineNumbersPopup = sender == wordWrapPopup ? self.lineNumbersPopup : utiLineNumbersPopup
        
        lineTextField?.isHidden = sender.indexOfSelectedItem == 0
        lineTextLabel?.isHidden = sender.indexOfSelectedItem == 0
        
        if sender.indexOfSelectedItem == 0 {
            if lineNumbersPopup?.indexOfSelectedItem == 2 {
                lineNumbersPopup?.selectItem(at: 1)
            }
            lineNumbersPopup?.menu?.item(at: 2)?.isEnabled = false
        } else {
            lineNumbersPopup?.menu?.item(at: 2)?.isEnabled = true
        }
        if sender == wordWrapPopup {
            refreshPreview(sender)
        } else {
            refreshUtiPreview(sender)
        }
    }
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: NSButton) {
        let fontPanel = NSFontPanel.shared
        fontPanel.worksWhenModal = true
        fontPanel.becomesKeyOnlyIfNeeded = true
        
        let fontFamily: String
        let fontSize: Float
        
        if tabView.selectedTabViewItem?.identifier as? String != "SpecificSettingsView" {
            fontFamily = fontPreviewTextField.font?.fontName ?? "Menlo"
            fontSize = Float(fontPreviewTextField.font?.pointSize ?? 12)
        } else {
            fontFamily = utiFontPreviewTextField.font?.fontName ?? "Menlo"
            fontSize = Float(utiFontPreviewTextField.font?.pointSize ?? 12)
        }
        if let font = NSFont(name: fontFamily, size: CGFloat(fontSize)) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        
        self.view.window?.makeFirstResponder(tabView)
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFont font: NSFont, isGlobal: Bool) {
        let ff: String
        if let family = font.familyName {
            ff = family
        } else {
            ff = font.fontName
        }
        
        let fp = font.pointSize
        
        let fontPreview = isGlobal ? fontPreviewTextField : utiFontPreviewTextField
        fontPreview?.stringValue = String(format:"%@ %.1f pt", ff, fp)
        fontPreview?.font = font
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFontFamily font: String, size: Float, isGlobal: Bool) {
        if let f = NSFont(name: font, size: CGFloat(size)) {
            self.refreshFontPanel(withFont: f, isGlobal: isGlobal)
        }
    }
    
    /// Handle format output change.
    @IBAction func handleFormatChange(_ sender: NSSegmentedControl) {
        webView.isHidden = sender.indexOfSelectedItem != 0
        scrollView.isHidden = sender.indexOfSelectedItem == 0
        refreshPreview(sender)
    
        utiWebView.isHidden = sender.indexOfSelectedItem != 0
        utiScrollView.isHidden = sender.indexOfSelectedItem == 0
        
        customCSSButton.isEnabled = sender.indexOfSelectedItem == 0
        
        utiCustomCSSCheckbox.isEnabled = self.currentUTISettings != nil && sender.indexOfSelectedItem == 0
        utiCustomCSSButton.isEnabled = utiCustomCSSCheckbox.isEnabled && utiCustomCSSCheckbox.state == .on
        
        refreshUtiPreview(sender)
    }
    
    /// Handle highlight theme change.
    @IBAction func handleHighLightPathChange(_ sender: NSPopUpButton) {
        var changed = false
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            // Browse for a custom path.
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.resolvesAliases = false
            openPanel.showsHiddenFiles = true
            if let s = self.settings?.highlightProgramPath {
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
                    
                    self.settings?.highlightProgramPath = url.path
                    changed = true
                } else {
                    // Restore previous selected path.
                    if let i = self.highlightPaths.firstIndex(where: { $0.path == self.settings?.highlightProgramPath }), let m = sender.menu?.item(withTag: i) {
                        sender.select(m)
                    } else {
                        sender.selectItem(at: 0)
                    }
                }
            }
        } else {
            if let i = sender.selectedItem?.tag, i >= 0, i < self.highlightPaths.count {
                self.settings?.highlightProgramPath = self.highlightPaths[i].path
                changed = true
            }
        }
        
        guard changed else {
            return
        }
        
        themeLightIcon.isEnabled = false
        themeDarkIcon.isEnabled = false
        
        utiThemeLightIcon.isEnabled = false
        utiThemeDarkIcon.isEnabled = false
        
        self.service?.getThemes(highlight: self.settings?.highlightProgramPath ?? "-") { (results, error) in
            var themes: [SCSHTheme] = []
            for dict in results {
                if let d = dict as? [String: Any], let theme = SCSHTheme(dict: d) {
                    themes.append(theme)
                }
            }
            DispatchQueue.main.async {
                self.themes = themes
                self.refreshPreview(self)
                if self.currentUTISettings != nil {
                    self.refreshUtiPreview(self)
                }
            }
        }
    }
    
    /// Shows the about highlight window,
    @IBAction func handleInfoButton(_ sender: Any) {
        service?.highlightInfo(highlight: self.settings?.highlightProgramPath ?? "-", reply: { (result) in
            if let vc = self.storyboard?.instantiateController(withIdentifier: "HighlightInfo") as? InfoHighlightController {
                vc.text = result
                self.presentAsSheet(vc)
            }
            
        })
    }
    
    // MARK: -
    
    // Called from refresh menu item.
    @IBAction func refresh(_ sender: Any) {
        if tabView.selectedTabViewItem?.identifier as? String == "SpecificSettingsView" {
            refreshUtiPreview(sender)
        } else {
            refreshPreview(sender)
        }
    }
    
    /// Refresh global preview.
    @IBAction func refreshPreview(_ sender: Any) {
        let settings = getSettings()
        
        let example: URL?
        if examplesPopup.indexOfSelectedItem == 0 || examples.count == 0 {
            example = nil
        } else {
            example = self.examples[examplesPopup.indexOfSelectedItem-2].url
        }
            
        self.refreshPreview(light: previewThemeControl.selectedSegment == 0, settings: settings, webView: webView, scrollText: scrollView, textView: textView, indicator: refreshIndicator, example: example)
    }
    
    // MARK: -
    
    /// Show only customized UTIs.
    @IBAction func handleFilterButton(_ sender: NSButton) {
        filterOnlyChanged = sender.state == .on
        
        sender.image = NSImage(named: sender.state == .on ? "Customized-ON_Normal" : "Customized_Normal")
        sender.contentTintColor = sender.state == .on ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
    }
    
    @IBAction func handleUtiThemeCheckbox(_ sender: NSButton) {
        utiThemeLightIcon.isEnabled = sender.state == .on
        utiThemeDarkIcon.isEnabled = sender.state == .on
        
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiCustomCSSCheckbox(_ sender: NSButton) {
        utiCustomCSSButton.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiFontCheckbox(_ sender: NSButton) {
        utiFontChooseButton.isEnabled = sender.state == .on
        utiFontPreviewTextField.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiWordWrapCheckbox(_ sender: NSButton) {
        utiWordWrapPopup.isEnabled = sender.state == .on
        utiLineLengthTextField.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiLineNumbersCheckbox(_ sender: NSButton) {
        utiLineNumbersPopup.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiTabSpacesCheckbox(_ sender: NSButton) {
        utiTabSpacesSlider.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiArgumentsCheckbox(_ sender: NSButton) {
        utiArgumentsTextField.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    @IBAction func handleUtiPreprocessorCheckbox(_ sender: NSButton) {
        utiPreprocessorTextField.isEnabled = sender.state == .on
        refreshUtiPreview(sender)
    }
    
    /// Refresh UTI preview.
    @IBAction func refreshUtiPreview(_ sender: Any) {
        let settings = getUtiSettings()
        
        self.refreshPreview(light: utiPreviewThemeControl.selectedSegment == 0, settings: settings, webView: utiWebView, scrollText: utiScrollView, textView: utiTextView, indicator: utiRefreshIndicator, example: getExample(forUTI: currentUTISettings?.uti ?? ""))
    }
    
    /// Refresh a preview.
    /// - parameters:
    ///   - light: Use light or dark theme.
    ///   - settings: Settings to use.
    ///   - webView:
    ///   - scrollText:
    ///   - textView:
    ///   - indicator:
    ///   - example: Url of a file to render. Nil to render the standard theme settings preview.
    private func refreshPreview(light: Bool, settings: SCSHSettings, webView: WKWebView, scrollText: NSScrollView, textView: NSTextView, indicator: NSProgressIndicator, example: URL?) {
        let custom_settings = SCSHSettings(settings: settings)
        
        if light {
            custom_settings.theme = custom_settings.lightTheme
            custom_settings.rtfBackgroundColor = custom_settings.rtfLightBackgroundColor
        } else {
            custom_settings.theme = custom_settings.darkTheme
            custom_settings.rtfBackgroundColor = custom_settings.rtfDarkBackgroundColor
        }
        
        indicator.startAnimation(self)
        
        if let url = example {
            /// Show a file.
            if custom_settings.format == .html {
                webView.isHidden = true
                service?.htmlColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary) { (html, extra, error) in
                    DispatchQueue.main.async {
                        webView.loadHTMLString(html, baseURL: nil)
                        indicator.stopAnimation(self)
                        webView.isHidden = false
                    }
                }
            } else {
                scrollText.isHidden = true
                service?.rtfColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary) { (response, effective_settings, error) in
                    let text: NSAttributedString
                    if let e = error {
                        text = NSAttributedString(string: String(data: response, encoding: .utf8) ?? e.localizedDescription)
                    } else {
                        text = NSAttributedString(rtf: response, documentAttributes: nil) ?? NSAttributedString(string: "Conversion error!")
                    }
                    
                    DispatchQueue.main.async {
                        textView.textStorage?.setAttributedString(text)
                        if let bg = effective_settings[SCSHSettings.Key.rtfBackgroundColor] as? String, let c = NSColor(fromHexString: bg) {
                            textView.backgroundColor = c
                        } else {
                            textView.backgroundColor = .clear
                        }
                        indicator.stopAnimation(self)
                        scrollText.isHidden = false
                    }
                }
            }
        } else {
            // Show standard theme preview.
            if let theme = getTheme(name: custom_settings.theme) {
                if custom_settings.format == .html {
                    webView.loadHTMLString(theme.getHtmlExample(fontName: settings.fontFamily ?? "Menlo", fontSize: (settings.fontSize ?? 12) * 0.75), baseURL: nil)
                } else {
                    let example = theme.getAttributedExample(fontName: custom_settings.fontFamily ?? "Menlo", fontSize: (custom_settings.fontSize ?? 12) * 0.75)
                    textView.textStorage?.setAttributedString(example)
                    
                    if let bg = custom_settings.rtfBackgroundColor, let c = NSColor(fromHexString: bg) {
                        textView.backgroundColor = c
                    } else {
                        textView.backgroundColor = .clear
                    }
                }
                indicator.stopAnimation(self)
            }
        }
    }
    
    // MARK: -
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            let anchor: String
            if tabView.selectedTabViewItem?.identifier as? String == "SpecificSettingsView" {
                anchor = "SyntaxHighlight_SPECIFIC_PREFERENCES"
            } else {
                anchor = "SyntaxHighlight_PREFERENCES"
            }
            
            NSHelpManager.shared.openHelpAnchor(anchor, inBook: locBookName)
        }
    }
    
    /// Save the settings.
    @IBAction func saveAction(_ sender: Any) {
        saveCurrentUtiSettings()
        
        let settings = self.getSettings()
        
        if let globalSettings = self.settings {
            for (_, utiSettings) in globalSettings.customizedSettings {
                if utiSettings.isCustomized {
                    settings.setUTISettings(utiSettings)
                }
            }
        }
        
        service?.setSettings(settings.toDictionary() as NSDictionary) { _ in
            DispatchQueue.main.async {
                self.view.window?.performClose(sender)
                
                NSApplication.shared.windows.forEach { (window) in
                    // Refresh all opened view.
                    if let c = window.contentViewController as? ViewController {
                        c.refresh(nil)
                    }
                }
            }
        }
    }
    
    /// Called when a theme is saved.
    @objc func onThemeDidSaved(_ notification: Notification) {
        guard let data = notification.object as? NotificationThemeSavedData else {
            return
        }
        guard let theme = SCSHTheme(dict: data.theme.toDictionary()) else {
            return
        }
        guard let i = themes.firstIndex(where: { $0.name == data.oldName && !$0.isStandalone }) else {
            // Addeded a new theme.
            var t = themes
            t.append(theme)
            t.sort { (a, b) in
                return a.desc < b.desc
            }
            themes = t
            return
        }
        
        // An exists theme is changed.
        
        /// Original name.
        let oldName = "!\(data.oldName)"
        /// Current name (may be different from the old name if the theme has been renamed).
        let newName = "!\(data.theme.name)"
        
        // Update the theme used in the settings.
        if let t = lightTheme, !t.isStandalone, t.name == data.oldName {
            lightTheme = theme
        }
        if self.settings?.lightTheme == oldName {
            self.settings?.lightTheme = newName
        }
        
        if let t = darkTheme, !t.isStandalone, t.name == data.oldName {
            darkTheme = theme
        }
        if self.settings?.darkTheme == oldName {
            self.settings?.darkTheme = newName
        }
        
        if let t = utiLightTheme, !t.isStandalone, t.name == data.oldName {
            utiLightTheme = theme
        }
        if let t = utiDarkTheme, !t.isStandalone, t.name == data.oldName {
            utiDarkTheme = theme
        }
        
        if newName != oldName {
            // Theme renamed, search inside the settings if it is used by some uti.
            for (_, settings) in self.settings?.customizedSettings ?? [:] {
                if settings.lightTheme == oldName {
                    settings.lightTheme = newName
                }
                if settings.darkTheme == oldName {
                    settings.darkTheme = newName
                }
            }
        }
        
        var t = themes
        t[i] = theme
        // Resort the themes, the descriotion may has been changed.
        t.sort { (a, b) in
            return a.desc < b.desc
        }
        themes = t
    }
    
    /// Called when a theme is deleted.
    @objc func onThemeDidDeleted(_ notification: Notification) {
        guard let name = notification.object as? NotificationThemeDeletedData else {
            return
        }
        guard let i = themes.firstIndex(where: { $0.name == name && !$0.isStandalone }) else {
            // Theme non presents in the list.
            return
        }
        
        let theme = themes[i]
        /// First standalone light theme.
        let ltheme = themes.first(where: { $0.isLight && $0.isStandalone } )
        /// First standalone dark theme.
        let dtheme = themes.first(where: { $0.isDark && $0.isStandalone } )
        
        let oldName = "!\(name)"
        
        if lightTheme == theme {
            lightTheme = ltheme
        }
        if settings?.lightTheme == oldName {
            settings?.lightTheme = ltheme?.name
        }
        if darkTheme == theme {
            darkTheme = dtheme
        }
        if settings?.darkTheme == oldName {
            settings?.darkTheme = dtheme?.name
        }
        
        if utiLightTheme == theme {
            utiLightTheme = ltheme
        }
        if utiDarkTheme == theme {
            utiDarkTheme = dtheme
        }
        
        
        for (_, settings) in self.settings?.customizedSettings ?? [:] {
            if settings.lightTheme == oldName {
                settings.lightTheme = ltheme?.name
            }
            if settings.darkTheme == oldName {
                settings.darkTheme = dtheme?.name
            }
        }
        
        themes.remove(at: i)
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileTypes.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn?.identifier.rawValue == "Icon" {
            return fileTypes[row].icon
        } else if tableColumn?.identifier.rawValue == "Changed" {
            return settings?.hasCustomizedUTI(fileTypes[row].uti.UTI) ?? false ? "M" : ""
        } else {
            return fileTypes[row].fullDescription
        }
    }
}

// MARK: - NSTableViewDelegate
extension PreferencesViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let index = self.tableView.selectedRow
        guard index >= 0 else {
            return
        }
        
        _ = selectUTI(self.fileTypes[index].uti.UTI)
    }
    
    func tableView(_ tableView: NSTableView, toolTipFor cell: NSCell, rect: NSRectPointer, tableColumn: NSTableColumn?, row: Int, mouseLocation: NSPoint) -> String {
        return self.fileTypes[row].uti.UTI
    }
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        if let c = cell as? NSTextFieldCell {
            if fileTypes[row].extensions.count > 0 && fileTypes[row].suppressedExtensions.count == fileTypes[row].extensions.count {
                c.textColor = NSColor.disabledControlTextColor
            } else {
                c.textColor = NSColor.textColor
            }
        }
    }
}

// MARK: - NSFontChanging
extension PreferencesViewController: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        
        if tabView.selectedTabViewItem?.identifier as? String == "GlobalSettingsView" {
            refreshFontPanel(withFont: font, isGlobal: true)
            refreshPreview(self)
        } else if tabView.selectedTabViewItem?.identifier as? String == "SpecificSettingsView" && utiFontChecbox.state == .on {
            refreshFontPanel(withFont: font, isGlobal: false)
            refreshUtiPreview(self)
        }
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}
