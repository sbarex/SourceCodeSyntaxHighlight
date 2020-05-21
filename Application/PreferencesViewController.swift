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
typealias ExampleInfo = (url: URL, title: String, uti: String)
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
    
    @IBOutlet weak var generalTabButton: NSButton!
    @IBOutlet weak var appearanceTabButton: NSButton!
    @IBOutlet weak var extraTabButton: NSButton!
    
    @IBOutlet weak var tabView: NSTabView!
    
    /// List of UTIs and global settings.
    @IBOutlet weak var tableView: NSTableView!
    /// Search field for filter the UTI list.
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var filterButton: NSButton!
            
    /// Preview view.
    @IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var utiTextField: NSTextField!
    @IBOutlet weak var extensionsTitleTextField: NSTextField!
    @IBOutlet weak var utiErrorButton: NSButton!
                            
    @IBOutlet weak var globalSettingsView: GlobalSettingsView!
    @IBOutlet weak var appearanceView: AppearanceView!
    @IBOutlet weak var extraSettingsView: ExtraSettingsView!
    
    internal var initialized = false
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    /// Global settings.
    var settings: SCSHSettings?
    
    /// List of themes.
    var themes: [SCSHTheme] = [] {
        didSet {
            self.previewView.themes = themes
            self.appearanceView.themes = themes
        }
    }
    
    /// List of example files.
    private var examples: [ExampleInfo] = [] {
        didSet {
            previewView.examples = examples
        }
    }
    
    /// All supported UTIs.
    var allFileTypes: [UTIDesc] = []
    
    /// Filtered supported UTIs.
    var fileTypes: [UTIDesc] = [] {
        didSet {
            guard oldValue != fileTypes else {
                return
            }
            tableView?.reloadData()
            tableView?.isEnabled = true // fileTypes.count > 0
        }
    }
    
    var currentUTI: UTIDesc?
    
    /// Filter for the UTI description.
    var filter: String = "" {
        didSet {
            guard oldValue != filter else {
                return
            }
            
            filterUTIs()
        }
    }
    
    /// Show only UTI with custom settings.
    var filterOnlyChanged: Bool = false {
        didSet {
            guard oldValue != filterOnlyChanged else {
                return
            }
            
            filterUTIs()
        }
    }
    
    
    var lightTheme: SCSHTheme?
    var darkTheme: SCSHTheme?
    
    var utiLightTheme: SCSHTheme?
    var utiDarkTheme: SCSHTheme?
    
    /// UTI settings in the detail view.
    var currentUTISettings: SCSHUTIBaseSettings? {
        didSet {
            if let utiSettings = oldValue {
                saveCurrentUtiSettings(utiSettings.uti)
            } else {
                saveGlobalSettings()
            }
            
            generalTabButton.isEnabled = currentUTISettings != nil
            generalTabButton.isHidden = currentUTISettings != nil
            if generalTabButton.isHidden && generalTabButton.state == .on {
                tabView.selectTabViewItem(at: 1)
                appearanceTabButton.state = .on
                generalTabButton.state = .off
            }
            
            previewView.isLooked = true
            
            if let currentUTISettings = self.currentUTISettings {
                guard let format = fileTypes.first(where: { $0.uti.UTI == currentUTISettings.uti }) else {
                    return
                }
                
                appearanceView.populateFromSettings(currentUTISettings)
                extraSettingsView.populateFromSettings(currentUTISettings)
                
                previewView.selectExampleForUTI(currentUTISettings.uti)
                
                descriptionTextField.stringValue = format.description
                utiTextField.stringValue = format.uti.UTI
                utiTextField.isHidden = false
                extensionsTitleTextField.stringValue = format.extensions.count > 0 ? "." + format.extensions.joined(separator: ", .") : ""
                utiErrorButton.isHidden = format.getSuppressedExtensions(handledUti: allFileTypes.map({ $0.uti.UTI })).count == 0
                
                if let i = fileTypes.firstIndex(where: { $0.uti.UTI == currentUTISettings.uti }) {
                    if tableView.selectedRow != i + 3 {
                        tableView.selectRowIndexes(IndexSet(integer: i + 3), byExtendingSelection: false)
                        tableView.scrollRowToVisible(i + 3)
                    }
                } else {
                    tableView.deselectAll(nil)
                }
            } else {
                descriptionTextField.stringValue = "Global settings"
                utiTextField.isHidden = true
                extensionsTitleTextField.stringValue = ""
                utiErrorButton.isHidden = true
                                
                if let settings = self.settings {
                    appearanceView.populateFromSettings(settings)
                    extraSettingsView.populateFromSettings(settings)
                }
            }
            previewView.isLooked = false
            previewView.refresh(self)
        }
    }
    
    deinit {
        // Remove the theme observer.
        NotificationCenter.default.removeObserver(self, name: .themeDidSaved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .themeDidDeleted, object: nil)
    }
    
    // MARK: -
    override func viewDidLoad() {
        globalSettingsView.delegate = self
        appearanceView.delegate = self
        extraSettingsView.delegate = self
                
        previewView.getSettings = {
            let settings: SCSHSettings
            if self.tableView.selectedRow != 1 {
                settings = self.getUtiSettings()
            } else {
                settings = self.getSettings()
            }
            self.appearanceView.mergeSettings(on: settings)
            self.extraSettingsView.mergeSettings(on: settings)
            
            return settings
        }
        
        // Populate UTIs list.
        allFileTypes = (NSApplication.shared.delegate as? AppDelegate)?.fetchHandledUTIs() ?? []
        fileTypes = allFileTypes
        
        // Populate the example files list.
        examples = (NSApplication.shared.delegate as? AppDelegate)?.getAvailableExamples() ?? []
                
        // Select the global settings on the UTI list.
        tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        
        // Fetch the global settings.
        fetchSettings()
        
        // Register the observers for theme save and delete notifications.
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
        }
    }
    
    // MARK: - Settings
    
    /// Filter the visible UTIs based on search criteria.
    func filterUTIs() {
        guard !filter.isEmpty || filterOnlyChanged else {
            fileTypes = self.allFileTypes
            return
        }
        
        let filter = self.filter.lowercased()
        fileTypes = self.allFileTypes.filter({ (uti) -> Bool in
            if filterOnlyChanged && !(settings?.hasCustomizedSettings(forUTI: uti.uti.UTI) ?? false) {
                return false
            }
            if !filter.isEmpty && !uti.fullDescription.lowercased().contains(filter) && !uti.uti.UTI.lowercased().contains(filter) {
                return false;
            }
            return true
        })
    }
    
    /// Fetch current settings.
    private func fetchSettings() {
        guard let service = self.service else {
            return
        }
        service.getSettings() {
            if let s = $0 as? [String: Any] {
                self.settings = SCSHSettings(settings: s)
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
            self.globalSettingsView.highlightPaths = []
            self.service?.locateHighlight { (paths) in
                var hl_paths: [HighlightPath] = []
                
                let currentHighlightPath = self.settings?.highlightProgramPath
                var found = false
                for info in paths {
                    guard info.count == 3, let path = info[0] as? String, let ver = info[1] as? String, let embedded = info[2] as? Bool else {
                        continue
                    }
                    hl_paths.append((path: embedded ? "-" : path, ver: ver, embedded: embedded))
                    
                    if let p = currentHighlightPath, (p == "-" && embedded) || p == path {
                        if embedded {
                            self.settings?.highlightProgramPath = "-"
                        }
                        found = true
                    }
                }
                if !found, let p = currentHighlightPath {
                    // Append current customized path.
                    hl_paths.append((path: p, ver: "", embedded: false))
                }
                self.globalSettingsView.highlightPaths = hl_paths
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
            // Initialize all gui controls.
            DispatchQueue.main.async {
                self.populateSettings()
            }
        default:
            return
        }
    }
    
    /// Initialize gui elements with current global settings.
    private func populateSettings() {
        // HTML/RTF format
        self.appearanceView.renderMode = self.settings?.format ?? .html
        self.extraSettingsView.renderMode = self.settings?.format ?? .html
        self.previewView.renderMode = self.settings?.format ?? .html
        
        initialized = true
        
        if settings != nil {
            globalSettingsView.populateFromSettings(settings!)
            appearanceView.populateFromSettings(settings!)
            extraSettingsView.populateFromSettings(settings!)
            
            previewView.refresh(self)
        }
        
        saveButton.isEnabled = settings != nil
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
    
    /// Return the url of an example file for specified UTI.
    func getExample(forUTI uti: String)-> URL? {
        return getExampleInfo(forUTI: uti)?.url
    }
    
    func getExampleInfo(forUTI uti: String)-> ExampleInfo? {
        if let e = examples.first(where: { $0.uti == currentUTISettings?.uti }) {
            // Exists an example specific for the requested UTI.
            return e
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
            return e
        }
        
        return nil
    }
    
    /// Get current edited global settings, without any custom settings for UTIs.
    func getSettings() -> SCSHSettings {
        let settings = SCSHSettings(settings: self.settings ?? SCSHSettings())
        globalSettingsView.saveSettings(on: settings)
        
        return settings
    }
    
    func selectUTI(_ uti: String) -> Bool {
        if let utiDesc = allFileTypes.first(where: { $0.uti.UTI == uti }) {
            currentUTI = utiDesc
            currentUTISettings = settings?.getCustomizedSettings(forUTI: uti)
            return true
        }
        return false
    }
    
    func selectGlobalSettings() {
        currentUTISettings = nil
        currentUTI = nil
        descriptionTextField.stringValue = "Global settings"
        utiTextField.isHidden = true
        extensionsTitleTextField.stringValue = ""
        utiErrorButton.isHidden = true
        
        generalTabButton.isHidden = false
        generalTabButton.isEnabled = true
    }
    
    /// Get a settings based on current customized global with apply the customization of active UTI.
    func getUtiSettings() -> SCSHSettings {
        let settings = getSettings()
        if let uti = self.currentUTISettings {
            settings.overrideSpecialSettings(from: uti)
            settings.override(fromSettings: uti)
        }
        
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
        let utiSettings = SCSHUTIBaseSettings(UTI: uti)
        if let s = settings?.getCustomizedSettings(forUTI: uti) {
            utiSettings.specialSettings = s.specialSettings
        }
        appearanceView.saveSettings(on: utiSettings)
        extraSettingsView.saveSettings(on: utiSettings)
        
        settings?.setCustomizedSettingsForUTI(utiSettings)
        
        if let i = fileTypes.firstIndex(where: { $0.uti.UTI == utiSettings.uti }) {
            tableView.reloadData(forRowIndexes: IndexSet(integer: i + 3), columnIndexes: IndexSet(integer: 2))
        }
    }
    
    func saveGlobalSettings() {
        if let settings = self.settings {
            appearanceView.saveSettings(on: settings)
            extraSettingsView.saveSettings(on: settings)
        }
    }
    
    // MARK: -
    
    // Called from refresh menu item.
    @IBAction func refresh(_ sender: Any) {
        previewView.refresh(sender)
    }
    
    /// Refresh global preview.
    @IBAction func refreshPreview(_ sender: Any) {
        previewView.refresh(self)
    }
    
    @IBAction func performFindPanelAction(_ sender: Any?) {
        self.view.window?.makeFirstResponder(searchField)
    }
    
    // MARK: -
    
    /// Show only custom UTIs.
    @IBAction func handleFilterButton(_ sender: NSButton) {
        filterOnlyChanged = sender.state == .on
        
        sender.image = NSImage(named: sender.state == .on ? "Customized-ON_Normal" : "Customized_Normal")
        sender.contentTintColor = sender.state == .on ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
    }
    
    // MARK: -
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            let anchor: String
            // MARK: FIXME
            if tabView.selectedTabViewItem?.identifier as? String == "Global" {
                anchor = "SyntaxHighlight_GLOBAL_PREFERENCES"
            } else if tabView.selectedTabViewItem?.identifier as? String == "Appearance" {
                anchor = "SyntaxHighlight_APPEARANCE_PREFERENCES"
            } else {
                anchor = "SyntaxHighlight_EXTRA_PREFERENCES"
            }
            
            NSHelpManager.shared.openHelpAnchor(anchor, inBook: locBookName)
        }
    }
    
    /// Save the settings.
    @IBAction func saveAction(_ sender: Any) {
        saveCurrentUtiSettings()
        
        let settings = self.getSettings()
        if tableView.selectedRow == 1 {
            appearanceView.saveSettings(on: settings)
            extraSettingsView.saveSettings(on: settings)
        } else if let uti = currentUTISettings?.uti {
            saveCurrentUtiSettings(uti)
        }
        
        if let globalSettings = self.settings {
            for (_, utiSettings) in globalSettings.customizedSettings {
                if utiSettings.isCustomized {
                    settings.setCustomizedSettingsForUTI(utiSettings)
                }
            }
        }
        
        self.view.window?.styleMask.remove(NSWindow.StyleMask.closable)
        
        saveButton.isEnabled = false
        cancelButton.isEnabled = false
        
        service?.setSettings(settings.toDictionary() as NSDictionary) { _ in
            DispatchQueue.main.async {
                self.saveButton.isEnabled = true
                self.cancelButton.isEnabled = true
                self.view.window?.styleMask.insert(NSWindow.StyleMask.closable)
                
                NSApplication.shared.windows.forEach { (window) in
                    // Refresh all opened view.
                    if let c = window.contentViewController as? ViewController {
                        c.refresh(nil)
                    }
                }
                
                //if (NSApplication.shared.delegate as? AppDelegate)?.documentsOpenedAtStart ?? false {
                    self.view.window?.performClose(sender)
                //}
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
            // Added a new theme.
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
            // Theme renamed, search inside the settings if it is used by some UTI.
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
        // Resort the themes, the description may has been changed.
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
    
    // MARK: -
    @IBAction func handleTabButton(_ sender: NSButton) {
        sender.state = .on
        if sender.identifier == NSUserInterfaceItemIdentifier("General") {
            tabView.selectTabViewItem(at: 0)
            extraTabButton.state = .off
            appearanceTabButton.state = .off
        } else if sender.identifier == NSUserInterfaceItemIdentifier("Appearance") {
            tabView.selectTabViewItem(at: 1)
            extraTabButton.state = .off
            generalTabButton.state = .off
        } else if sender.identifier == NSUserInterfaceItemIdentifier("Extra") {
            tabView.selectTabViewItem(at: 2)
            generalTabButton.state = .off
            appearanceTabButton.state = .off
        }
    }
}

// MARK: - NSTableViewDataSource
extension PreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 2 + (self.fileTypes.count > 0 ? 1 : 0) + fileTypes.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
       if tableColumn?.identifier.rawValue == "Icon" {
            return row < 3 ? nil : fileTypes[row-3].icon
        } else if tableColumn?.identifier.rawValue == "Changed" {
            return row < 3 ? "" : settings?.hasCustomizedSettings(forUTI: fileTypes[row - 3].uti.UTI) ?? false ? "M" : ""
        } else {
            if row == 0 {
                return "Global settings"
            } else if row == 1 {
                return "global"
            } else if row == 2 {
                return "Specific settings"
            } else {
                return fileTypes[row-3].fullDescription
            }
        }
    }
}

// MARK: - NSTableViewDelegate
extension PreferencesViewController: NSTableViewDelegate {
    func tableViewSelectionIsChanging(_ notification: Notification) {
        if currentUTI == nil {
            if settings != nil {
                // Save the appaerance settings of the global settings.
                appearanceView.saveSettings(on: settings!)
                extraSettingsView.saveSettings(on: settings!)
            }
        } else {
            saveCurrentUtiSettings(currentUTI!.uti.UTI)
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let index = self.tableView.selectedRow
        guard index >= 0 else {
            return
        }
        
        if index > 2 {
            _ = selectUTI(self.fileTypes[index - 3].uti.UTI)
        } else if index == 1 {
            selectGlobalSettings()
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return row == 0 || row == 2
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return row == 0 || row == 2 ? 30 : 38
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row != 0 && row != 2
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let column = tableColumn {
            let v = tableView.makeView(withIdentifier: column.identifier, owner: self) as! NSTableCellView
            v.toolTip = ""
            if column.identifier == NSUserInterfaceItemIdentifier("Icon") {
                if row > 2 {
                    v.imageView?.image = fileTypes[row - 3].icon
                } else {
                    v.imageView?.image = nil
                }
            } else if column.identifier == NSUserInterfaceItemIdentifier("Name") {
                if row > 2 {
                    let suppressed = fileTypes[row - 3].extensions.count > 0 && fileTypes[row - 3].suppressedExtensions.count == fileTypes[row - 3].extensions.count
                    if let cell = v as? UTITableCellView {
                        v.textField?.stringValue = fileTypes[row - 3].description
                        cell.extensionTextField.stringValue = fileTypes[row - 3].extensions.count > 0 ? "." + fileTypes[row - 3].extensions.joined(separator: ", .") : ""
                        cell.extensionTextField.isHidden = false
                        cell.extensionTextField.textColor = suppressed ?  .disabledControlTextColor : .labelColor
                    } else {
                        v.textField?.stringValue = fileTypes[row - 3].fullDescription
                    }
                    v.toolTip = self.fileTypes[row - 3].uti.UTI
                    
                    v.textField?.textColor = suppressed ? .disabledControlTextColor : .labelColor
                } else if row == 1 {
                    v.textField?.stringValue = "Global"
                    v.textField?.textColor = .labelColor
                    if let cell = v as? UTITableCellView {
                        cell.extensionTextField.isHidden = true
                    }
                } 
            } else if column.identifier == NSUserInterfaceItemIdentifier("Changed") {
                v.imageView?.isHidden = !(row > 2 && settings?.hasCustomizedSettings(forUTI: fileTypes[row - 3].uti.UTI) ?? false)
            }
            return v
        } else {
            let v = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("GroupCell"), owner: self) as! NSTableCellView
            v.textField?.stringValue = row == 0 ? "Global settings" : "Specific settings"
            return v
        }
    }
}



// MARK: - NSTabViewDelegate
extension PreferencesViewController: NSTabViewDelegate {
    
}

extension PreferencesViewController: AppearanceViewDelegate {
    func appearance(appearanceView: AppearanceView, requestBrowserForTheme theme: SCSHTheme?, mode: ThemeStyleFilterEnum, fromView: NSView,  onComplete: @escaping (_ theme: SCSHTheme?)->Void) {
        guard let vc = self.storyboard?.instantiateController(withIdentifier:"ThemeSelector") as? ThemeSelectorViewController else {
            return
        }
        
        vc.style = mode
        vc.handler = { theme in
            onComplete(theme)
        }
        vc.allThemes = self.themes.map({ SCSHThemePreview(theme: $0) })
        
        self.present(vc, asPopoverRelativeTo: fromView.bounds, of: fromView, preferredEdge: NSRectEdge.maxY, behavior: NSPopover.Behavior.semitransient)
    }
    
    func appearanceRequestRefreshPreview(appearanceView: AppearanceView) {
        previewView.refresh(appearanceView)
    }
    
    func appearance(appearanceView: AppearanceView, requestCustomStyle style: String, showingUTIWarning: Bool, onComplete: @escaping (_ style: String)->Void) {
        guard let vc = self.storyboard?.instantiateController(withIdentifier: "CustomStyleEditor") as? CSSControlView else {
            return
        }
        vc.cssCode = style
        vc.isUTIWarningHidden = !showingUTIWarning
        vc.handler = { css in
            onComplete(css)
        }
        self.presentAsSheet(vc)
    }
}

extension PreferencesViewController: ExtraSettingsViewDelegate {
    func extraSettingsRequestRefreshPreview(extraSettingsView: ExtraSettingsView) {
        previewView.refresh(extraSettingsView)
    }
}

extension PreferencesViewController: GlobalSettingsViewDelegate {
    /// Shows the about highlight window,
    func globalSettings(globalSettingsView: GlobalSettingsView, showHighlightInfoForPath path: String?) {
        service?.highlightInfo(highlight: path ?? "-", reply: { (result) in
            if let vc = self.storyboard?.instantiateController(withIdentifier: "HighlightInfo") as? InfoHighlightController {
                vc.text = result
                self.presentAsSheet(vc)
            }
        })
    }
    
    /// Handle format output change.
    func globalSettings(_ globalSettingsView: GlobalSettingsView, outputModeChangedTo format: SCSHBaseSettings.Format) {
        appearanceView.renderMode = format
        extraSettingsView.renderMode = format
        previewView.renderMode = format
        
        previewView.refresh(globalSettingsView)
    }
    
    func globalSettings(_ globalSettingsView: GlobalSettingsView, highlightPathChangedTo path: String?) {
        self.themes = []
        self.appearanceView.themes = []
        
        self.service?.getThemes(highlight: path ?? "-") { (results, error) in
            var themes: [SCSHTheme] = []
            for dict in results {
                if let d = dict as? [String: Any], let theme = SCSHTheme(dict: d) {
                    themes.append(theme)
                }
            }
            DispatchQueue.main.async {
                self.themes = themes
                self.appearanceView.themes = themes
                self.previewView.themes = themes
                self.previewView.refresh(self)
            }
        }
        self.service?.highlightAvailableSyntax(highlight: path ?? "-", reply: { (result) in
            if let result = result as? [String: [String: Any]] {
                self.extraSettingsView.availableSyntax = result
            }
        })
    }
}
