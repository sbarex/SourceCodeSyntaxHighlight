//
//  PreferencesViewController.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 08/11/2019.
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
    @IBOutlet weak var themeLightPopup: NSPopUpButton!
    @IBOutlet weak var themeDarkPopup: NSPopUpButton!
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
    @IBOutlet weak var utiThemeLightPopup: NSPopUpButton!
    @IBOutlet weak var utiThemeDarkPopup: NSPopUpButton!
    
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
                utiThemeLightPopup.isEnabled = utiThemeCheckbox.state == .on
                utiThemeDarkPopup.isEnabled = utiThemeCheckbox.state == .on
                
                let lightTheme = currentUTISettings.lightTheme ?? settings?.lightTheme ?? ""
                let lightIndex = themes.firstIndex(where: { $0.name == lightTheme }) ?? 0
                utiThemeLightPopup.selectItem(at: lightIndex)
                
                let darkTheme = currentUTISettings.darkTheme ?? settings?.darkTheme ?? ""
                let darkIndex = themes.firstIndex(where: { $0.name  == darkTheme }) ?? 0
                utiThemeDarkPopup.selectItem(at: darkIndex)
                
                utiFontChecbox.state = currentUTISettings.fontFamily != nil ? .on : .off
                utiFontPreviewTextField.isEnabled = utiFontChecbox.state == .on
                utiFontChooseButton.isEnabled = utiFontChecbox.state == .on
                if let f = NSFont(name: currentUTISettings.fontFamily ?? settings?.fontFamily ?? "Menlo", size: CGFloat(currentUTISettings.fontSize ?? settings?.fontSize ?? 12)) {
                    self.refreshFontPanel(withFont: f, isGlobal: false)
                }
                
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
    
    // MARK: -
    override func viewDidLoad() {
        // Populate UTIs list.
        allFileTypes = (NSApplication.shared.delegate as? AppDelegate)?.fetchHandledUTIs() ?? []
        fileTypes = allFileTypes
        
        let defaults = UserDefaults.standard
        /// Current OS style.
        let macosThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        previewThemeControl.setSelected(true, forSegment: macosThemeLight ? 0 : 1)
        utiPreviewThemeControl.setSelected(true, forSegment: macosThemeLight ? 0 : 1)
        
        // Populate the example files list.
        examples = []
        examplesPopup.removeAllItems()
        examplesPopup.addItem(withTitle: "Theme colors")
        examplesPopup.menu?.addItem(NSMenuItem.separator())
        if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for file in files {
                    let title: String
                    if let uti = UTI(URL: file) {
                        title = uti.description + " (." + file.pathExtension + ")"
                        examples.append((url: file, title: title, uti: uti.UTI))
                    } else {
                        title = file.lastPathComponent
                        examples.append((url: file, title: title, uti: ""))
                    }
                    
                }
                examples.sort { (a, b) -> Bool in
                    a.title < b.title
                }
                
                for file in examples {
                    let m = NSMenuItem(title: file.title, action: nil, keyEquivalent: "")
                    m.toolTip = file.uti
                    examplesPopup.menu?.addItem(m)
                }
            }
        }
        examplesPopup.isEnabled = true
        
        fetchSettings()
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
                DispatchQueue.main.async {
                    self.themes = results.map({ SCSHTheme(dict: $0) })
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
        themeLightPopup.removeAllItems()
        themeDarkPopup.removeAllItems()
        
        utiThemeLightPopup.removeAllItems()
        utiThemeDarkPopup.removeAllItems()
        
        var i = 0
        var lightIndex = -1
        var darkIndex = -1
        
        var lightIndexUti = -1
        var darkIndexUti = -1
        
        for theme in self.themes {
            let name = theme.name
            
            if name == self.settings?.lightTheme {
                lightIndex = i
            }
            if name == self.settings?.darkTheme {
                darkIndex = i
            }
            
            if name == currentUTISettings?.lightTheme {
                lightIndexUti = i
            }
            if name == currentUTISettings?.darkTheme {
                darkIndexUti = i
            }
            
            let desc = theme.fullDesc
            
            themeLightPopup.addItem(withTitle: desc)
            themeDarkPopup.addItem(withTitle: desc)
            
            utiThemeLightPopup.addItem(withTitle: desc)
            utiThemeDarkPopup.addItem(withTitle: desc)
            
            i += 1
        }
        
        themeLightPopup.isEnabled = themes.count > 0
        themeDarkPopup.isEnabled = themes.count > 0
        
        if themes.count == 0 {
            themeLightPopup.addItem(withTitle: "No theme available")
            themeDarkPopup.addItem(withTitle: "No theme available")
            
            utiThemeLightPopup.addItem(withTitle: "No theme available")
            utiThemeDarkPopup.addItem(withTitle: "No theme available")
        } else {
            if lightIndex >= 0 {
                themeLightPopup.selectItem(at: lightIndex)
            }
            if darkIndex >= 0 {
                themeDarkPopup.selectItem(at: darkIndex)
            }
            if lightIndexUti >= 0 {
                utiThemeLightPopup.selectItem(at: lightIndexUti)
            }
            if darkIndexUti >= 0 {
                utiThemeDarkPopup.selectItem(at: darkIndexUti)
            }
        }
    }
    
    /// Get theme at the index.
    func getTheme(at index: Int) -> SCSHTheme? {
        if themes.count == 0 || index < 0 || index >= themes.count {
            return nil
        }
        return themes[index]
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
        var settings = SCSHSettings()
        settings.highlightProgramPath = self.settings?.highlightProgramPath ?? "-"
        settings.format = formatModeControl.selectedSegment == 0 ? .html : .rtf
        
        if let theme = getTheme(at: themeLightPopup.indexOfSelectedItem) {
            settings.lightTheme = theme.name
            settings.lightThemeIsBase16 = theme.isBase16
            settings.rtfLightBackgroundColor = theme.backgroundColor
        }
        if let theme = getTheme(at: themeDarkPopup.indexOfSelectedItem) {
            settings.darkTheme = theme.name
            settings.darkThemeIsBase16 = theme.isBase16
            settings.rtfDarkBackgroundColor = theme.backgroundColor
        }
        
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
    func getUtiSettings() -> SCSHSettings
    {
        var settings = getSettings()
        
        if utiThemeCheckbox.state == .on {
            if let theme = getTheme(at: utiThemeLightPopup.indexOfSelectedItem) {
                settings.lightTheme = theme.name
                settings.lightThemeIsBase16 = theme.isBase16
                settings.rtfLightBackgroundColor = theme.backgroundColor
            }
            if let theme = getTheme(at: utiThemeDarkPopup.indexOfSelectedItem) {
                settings.darkTheme = theme.name
                settings.darkThemeIsBase16 = theme.isBase16
                settings.rtfDarkBackgroundColor = theme.backgroundColor
            }
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
        var utiSettings = SCSHSettings(UTI: uti)
        
        if utiSpecificArgumentsTextField.stringValue.isEmpty {
            utiSettings.utiExtra = nil
        } else {
            utiSettings.utiExtra = utiSpecificArgumentsTextField.stringValue
        }
        
        if utiThemeCheckbox.state == .on {
            if let theme = getTheme(at: utiThemeLightPopup.indexOfSelectedItem) {
                utiSettings.lightTheme = theme.name
                utiSettings.lightThemeIsBase16 = theme.isBase16
                utiSettings.rtfLightBackgroundColor = theme.backgroundColor
            }
            if let theme = getTheme(at: utiThemeDarkPopup.indexOfSelectedItem) {
                utiSettings.darkTheme = theme.name
                utiSettings.darkThemeIsBase16 = theme.isBase16
                utiSettings.rtfDarkBackgroundColor = theme.backgroundColor
            }
        } else {
            utiSettings.lightTheme = nil
            utiSettings.lightThemeIsBase16 = nil
            utiSettings.rtfLightBackgroundColor = nil
            utiSettings.darkTheme = nil
            utiSettings.darkThemeIsBase16 = nil
            utiSettings.rtfDarkBackgroundColor = nil
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
        if tabView.tabViewItems.first?.tabState == .selectedTab {
            fontFamily = settings?.fontFamily ?? "Menlo"
            fontSize = settings?.fontSize ?? 10
        } else {
            fontFamily = currentUTISettings?.fontFamily ?? "Menlo"
            fontSize = currentUTISettings?.fontSize ?? 10
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
    
    /// Handle format output change.
    @IBAction func handleFormatChange(_ sender: NSSegmentedControl) {
        if sender == self.formatModeControl {
            webView.isHidden = sender.indexOfSelectedItem != 0
            scrollView.isHidden = sender.indexOfSelectedItem == 0
            refreshPreview(sender)
        } else {
            utiWebView.isHidden = sender.indexOfSelectedItem != 0
            utiScrollView.isHidden = sender.indexOfSelectedItem == 0
            refreshUtiPreview(sender)
        }
    }
    
    /// Handle theme change.
    @IBAction func handleThemeChange(_ sender: NSPopUpButton) {
        if (sender == themeLightPopup && previewThemeControl.selectedSegment == 0) || sender == themeDarkPopup && previewThemeControl.selectedSegment == 1 {
            refreshPreview(sender)
        } else if (sender == utiThemeLightPopup && utiPreviewThemeControl.selectedSegment == 0) || sender == utiThemeDarkPopup && utiPreviewThemeControl.selectedSegment == 1 {
            refreshUtiPreview(sender)
        }
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
        
        themeLightPopup.removeAllItems()
        themeLightPopup.isEnabled = false
        themeLightPopup.addItem(withTitle: "loading…")
        
        themeDarkPopup.removeAllItems()
        themeDarkPopup.isEnabled = false
        themeDarkPopup.addItem(withTitle: "loading…")
        
        utiThemeLightPopup.removeAllItems()
        utiThemeLightPopup.isEnabled = false
        utiThemeLightPopup.addItem(withTitle: "loading…")
        
        utiThemeDarkPopup.removeAllItems()
        utiThemeDarkPopup.isEnabled = false
        utiThemeDarkPopup.addItem(withTitle: "loading…")
        
        self.service?.getThemes(highlight: self.settings?.highlightProgramPath ?? "-") { (results, error) in
            DispatchQueue.main.async {
                self.themes = results.map({ SCSHTheme(dict: $0) })
                self.refreshPreview(self)
                if self.currentUTISettings != nil {
                    self.refreshUtiPreview(self)
                }
            }
        }
    }
    
    // MARK: -
    
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
        
        sender.image = NSImage(named: sender.state == .on ? "WorkingCopyNavigatorTemplate-ON_Normal" : "WorkingCopyNavigatorTemplate_Normal")
        sender.contentTintColor = sender.state == .on ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
    }
    
    @IBAction func handleUtiThemeCheckbox(_ sender: NSButton) {
        utiThemeLightPopup.isEnabled = sender.state == .on
        utiThemeDarkPopup.isEnabled = sender.state == .on
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
        var custom_settings = SCSHSettings(settings: settings)
        
        if light {
            custom_settings.theme = custom_settings.lightTheme
            custom_settings.themeIsBase16 = custom_settings.lightThemeIsBase16
            custom_settings.rtfBackgroundColor = custom_settings.rtfLightBackgroundColor
        } else {
            custom_settings.theme = custom_settings.darkTheme
            custom_settings.themeIsBase16 = custom_settings.darkThemeIsBase16
            custom_settings.rtfBackgroundColor = custom_settings.rtfDarkBackgroundColor
        }
        
        indicator.startAnimation(self)
        
        if let url = example {
            /// Show a file.
            if custom_settings.format == .html {
                webView.isHidden = true
                service?.htmlColorize(url: url, overrideSettings: custom_settings.toDictionary() as NSDictionary) { (html, extra, error) in
                    DispatchQueue.main.async {
                        webView.loadHTMLString(html, baseURL: nil)
                        indicator.stopAnimation(self)
                        webView.isHidden = false
                    }
                }
            } else {
                scrollText.isHidden = true
                service?.rtfColorize(url: url, overrideSettings: custom_settings.toDictionary() as NSDictionary) { (response, effective_settings, error) in
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
            if let theme: SCSHTheme = themes.first(where: { $0.name == custom_settings.theme }) {
                if custom_settings.format == .html {
                    webView.loadHTMLString(theme.getHtmlExample(fontName: settings.fontFamily ?? "Menlo", fontSize: (settings.fontSize ?? 12) * 1), baseURL: nil)
                } else {
                    textView.textStorage?.setAttributedString(theme.getAttributedExample(fontName: custom_settings.fontFamily ?? "Menlo", fontSize: custom_settings.fontSize ?? 12))
                    
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
    
    /// Save the settings.
    @IBAction func saveAction(_ sender: Any) {
        saveCurrentUtiSettings()
        
        var settings = self.getSettings()
        
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
            // refreshPreview(self)
        } else if tabView.selectedTabViewItem?.identifier as? String == "SpecificSettingsView" && utiFontChecbox.state == .on {
            refreshFontPanel(withFont: font, isGlobal: false)
            // refreshUtiPreview(self)
        }
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}
