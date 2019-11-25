//
//  ThemesViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 18/11/2019.
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

class ThemesViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var filterThemePopup: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var changedFilterButton: NSButton!
    
    @IBOutlet weak var addThemeButton: NSButton!
    @IBOutlet weak var delThemeButton: NSButton!
    
    @IBOutlet weak var examplesPopup: NSPopUpButton!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var addKeywordMenuItem: NSMenuItem!
    @IBOutlet weak var delThemeMenuItem: NSMenuItem!
    @IBOutlet weak var actionsPupupButton: NSPopUpButton!
    @IBOutlet weak var saveButton: NSButton!
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    /// All (unfiltered) standard themes.
    var allThemes: [SCSHThemePreview] = [] {
        didSet {
            refreshThemes(custom: false)
        }
    }
    
    /// All (unfiltered) custom themes.
    var allCustomThemes: [SCSHThemePreview] = [] {
        didSet {
            refreshThemes(custom: true)
        }
    }
    
    /// Filtered standard themes.
    var themes: [SCSHThemePreview] = [] {
        didSet {
            if oldValue != themes {
                outlineView?.reloadItem("Standard", reloadChildren: true)
                if let t = themes.first(where: { $0.theme == self.theme }) {
                    let i = outlineView.row(forItem: t)
                    if i >= 0 {
                        // Reselect current theme.
                        outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    }
                }
            }
        }
    }
    
    /// Filtered custom themes.
    var customThemes: [SCSHThemePreview] = [] {
        didSet {
            if oldValue != customThemes {
                outlineView?.reloadItem("Custom", reloadChildren: true)
                if let t = customThemes.first(where: { $0.theme == self.theme }) {
                    let i = outlineView.row(forItem: t)
                    if i >= 0 {
                        // Reselect current theme.
                        outlineView?.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    }
                }
            }
        }
    }
    
    /// Current theme.
    var theme: SCSHTheme? {
        didSet {
            oldValue?.delegate = nil
            theme?.delegate = self
            refreshThemeViews()
        }
    }
    
    /// Filter for theme name.
    var filter: String = "" {
        didSet {
            refreshThemes()
        }
    }
    /// Filter fot theme style (light/dark).
    var style: ThemeStyleFilterEnum = .all {
        didSet {
            refreshThemes()
        }
    }
    
    /// Filter for only changed themes.
    var showOnlyChanged: Bool = false {
        didSet {
            self.changedFilterButton.image = NSImage(named: showOnlyChanged ? NSImage.statusAvailableName : NSImage.statusNoneName)
            
            refreshThemes()
        }
    }
    
    /// List of available source file examples.
    var examples: [ExampleItem] = []
    
    /// Url of the xpc bundle.
    var xpcURL: URL?
    
    override func viewDidLoad() {
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
        
        // Register a custom js handler.
        webView.configuration.userContentController.add(self, name: "jsHandler")
        
        service?.getXPCPath() {
            self.xpcURL = $0
        }
        
        // Fetch the themes.
        service?.getThemes() { (results, error) in
            var themes: [SCSHThemePreview] = []
            for dict in results {
                if let d = dict as? [String: Any], let theme = SCSHTheme(dict: d) {
                    themes.append(SCSHThemePreview(theme: theme))
                }
            }
            
            DispatchQueue.main.async {
                self.outlineView.beginUpdates()
                self.allThemes = themes.filter({ $0.theme.isStandalone })
                self.allCustomThemes = themes.filter({ !$0.theme.isStandalone })
                self.outlineView.endUpdates()
                if self.allThemes.count > 0 {
                    self.outlineView.expandItem("Standard")
                }
                if self.allCustomThemes.count > 0 {
                    self.outlineView.expandItem("Custom")
                }
            }
        }
        
        refreshThemeViews()
    }
    
    // Called from refresh menu item.
    @IBAction func refresh(_ sender: Any) {
        refreshPreview(sender)
    }
    
    /// Refresh the preview.
    @IBAction func refreshPreview(_ sender: Any) {
        guard let theme = self.theme else {
            webView.isHidden = true
            return
        }
        
        let example: URL?
        if examplesPopup.indexOfSelectedItem == 0 || examples.count == 0 {
            example = nil
        } else {
            example = self.examples[examplesPopup.indexOfSelectedItem-2].url
        }
            
        self.webView.isHidden = true
        if let url = example {
            /// Show a file.
            var settings: [String: Any] = [
                SCSHSettings.Key.theme: theme.name,
                SCSHSettings.Key.inline_theme: theme.toDictionary(),
                SCSHSettings.Key.embedCustomStyle: false,
                SCSHSettings.Key.lineNumbers: true,
                SCSHSettings.Key.customCSS: "* { box-sizing: border-box; } html, body { height: 100%; margin: 0; } body { padding: 0; }"
            ]
            
            // Embed jquery.
            if let url = xpcURL?.appendingPathComponent("Contents/Resources/highlight/share/plugins/html_jquery.lua") {
                settings[SCSHSettings.Key.extraArguments] = "--plug-in=\(url.path.g_shell_quote())"
            }
            
            service?.htmlColorize(url: url, overrideSettings: settings as NSDictionary) { (html, extra, error) in
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(html, baseURL: nil)
                }
            }
        } else {
            // Show standard theme preview.
            var schema = theme.getHtmlExample(fontName: "Menlo", fontSize: 12 * 0.75, showColorCodes: false)
            // Embed jquery.
            if let url = (NSApplication.shared.delegate as? AppDelegate)?.getQLAppexUrl()?.appendingPathComponent("Contents/XPCServices/Syntax Highlight XPC Service.xpc/Contents/Resources/highlight/share/plugins/jquery-3.4.1.min.js"), let s = try? String(contentsOf: url) {
                schema = schema.replacingOccurrences(of: "<head>", with: "<head>\n<script type='text/javascript'>\(s)</script>")
            }
            
            webView.loadHTMLString(schema, baseURL: nil)
        }
    }
    
    /// Update the list of themes based of the requested style.
    @IBAction func handleFilterStyle(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 {
            style = .all
        } else if sender.indexOfSelectedItem == 1 {
            style = .light
        } else if sender.indexOfSelectedItem == 2 {
            style = .dark
        }
    }
    
    /// Update the list of themes shoowing only changed themes.
    @IBAction func handleOnlyChangedFilter(_ sender: NSButton) {
        showOnlyChanged = !showOnlyChanged
    }
    
    /// Append a custom theme to the list.
    func appendCustomTheme(_ newTheme: SCSHTheme) {
        newTheme.isStandalone = false
        // newTheme.addObserver(self, forKeyPath: "isDirty", options: [], context: nil)
        
        var themes = allCustomThemes
        themes.append(SCSHThemePreview(theme: newTheme))
        themes.sort { (t1, t2) -> Bool in
            return t1.theme.desc < t2.theme.desc
        }
        
        view.window?.isDocumentEdited = true
        
        outlineView.beginUpdates()
        allCustomThemes = themes
        outlineView.endUpdates()
            
        /// Index of inserted theme
        if let i = customThemes.firstIndex(where: { $0.theme == newTheme }) {
            // Expand the list of custom themes.
            outlineView.expandItem("Custom")
            let item = customThemes[i]
            let row = outlineView.row(forItem: item)
            if row >= 0 {
                // Select the new theme.
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                // Scroll to the theme row.
                outlineView.scrollRowToVisible(row)
            }
        }
    }
    
    // Called from the File/Duplicate menu.
    @IBAction func duplicateDocument(_ sender: Any) {
        handleDuplicate(sender)
    }
    
    /// Duplicate the current theme.
    @IBAction func handleDuplicate(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        
        guard let newTheme = SCSHTheme(dict: theme.toDictionary()) else {
            return
        }
        
        // List of current customized theme names.
        var names = customThemes.map({ $0.theme.name })
        if theme.isStandalone {
            names.append(theme.name)
        }
        /// New name based to the source theme.
        let themeName = theme.name.duplicate(format: "%@_copy_%d", suffixPattern: #"_+copy_+(?<n>\d+)"#, list: names)
        
        newTheme.name = themeName
        
        appendCustomTheme(newTheme)
        
        self.theme = newTheme
    }
    
    /// Add a new empty theme.
    @IBAction func handleAddTheme(_ sender: Any) {
        let themeName = "new_theme".duplicate(format: "%@_%d", suffixPattern: #"_(?<n>\d+)"#, list: customThemes.map({ $0.theme.name }))
        let newTheme = SCSHTheme(name: themeName)
        newTheme.isStandalone = false
        newTheme.desc = "My custom theme".duplicate(format: "%@ %d", suffixPattern: #" (?<n>\d+)"#, list: customThemes.map({ $0.theme.desc }))
        newTheme.isDirty = true
        
        appendCustomTheme(newTheme)
        
        self.theme = newTheme
    }
    
    /// Delete the current theme.
    @IBAction func handleDelTheme(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Warning"
        alert.informativeText = "Are you sure to delete this custom theme?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = .warning
        
        alert.beginSheetModal(for: self.view.window!) { (response) in
            guard response == .alertFirstButtonReturn else {
                return
            }
            self.removeTheme()
        }
    }
    
    func removeTheme() {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let update = { () in
            /// Index of the theme in the list
            guard let index = self.allCustomThemes.firstIndex(where: { $0.theme == theme }) else {
                return
            }
            
            self.outlineView.beginUpdates()
            if let i = self.customThemes.firstIndex(where: { $0.theme == theme }) {
                // Remove the row of deleted theme.
                self.outlineView.removeItems(at: IndexSet(integer: i), inParent: "Custom", withAnimation: NSTableView.AnimationOptions.slideLeft)
            }
            
            // Remove the theme from the list
            let t = self.allCustomThemes.remove(at: index)
            t.theme.delegate = nil
            
            self.outlineView.endUpdates()
            
            // Update the dirty status of the windows.
            self.view.window?.isDocumentEdited = self.customThemes.first(where: { $0.theme.isDirty }) != nil
                
            if self.theme == theme {
                self.theme = nil
            }
            
            NotificationCenter.default.post(name: .themeDidDeleted, object: NotificationThemeDeletedData(theme.name))
        }
        
        if theme.originalName.isEmpty {
            // Theme never saved.
            update()
        } else {
            service?.deleteTheme(name: theme.originalName) { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        update()
                    }
                } else {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        
                        alert.messageText = "Unable to delete the theme \(theme.name)!"
                        alert.informativeText = error?.localizedDescription ?? ""
                        alert.addButton(withTitle: "Close")
                        
                        alert.alertStyle = .critical
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    /// Add a new kwyword to the current theme.
    @IBAction func handleAddKeyword(_ sender: NSButton) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        tableView.beginUpdates()
        let keyword = SCSHTheme.Property(color: NSColor.random().toHexString())
        
        let index = tableView.row(for: sender)
        let newIndex: Int
        if index >= 0 {
            let k = index - 3 - SCSHTheme.Property.Name.standardProperties.count
            theme.insertKeyword(keyword, at: k + 1)
            newIndex = index+1
        } else {
            theme.appendKeyword(keyword)
            newIndex = theme.numberOfProperties + 3 - 1
        }
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .slideRight)
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: newIndex..<theme.numberOfProperties+3-1), columnIndexes: IndexSet(integersIn: 0...1))
        
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(newIndex)
        refreshPreview(sender)
    }
    
    @IBAction func handleAddKeywordFromMenu(_ sender: NSMenuItem) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        tableView.beginUpdates()
        let keyword = SCSHTheme.Property(color: NSColor.random().toHexString())
        theme.appendKeyword(keyword)
        let newIndex = theme.numberOfProperties + 3 - 1
        
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .slideRight)
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(newIndex)
        refreshPreview(sender)
    }
    
    /// Delete a keyword from the current theme.
    @IBAction func handleDelKeyword(_ sender: NSButton) {
        guard  let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        let index = tableView.row(for: sender)
        guard index >= 0 else {
            return
        }
        
        tableView.beginUpdates()
        // Remove the keyword row.
        tableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideRight)
        // Refresh the next keywords (necessary to rename them).
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: index..<theme.numberOfProperties+3-1), columnIndexes: IndexSet(integersIn: 0...1))
        
        let k = index - 3 - SCSHTheme.Property.Name.standardProperties.count
        theme.removeKeyword(at: k)
        
        tableView.endUpdates()
        
        refreshPreview(sender)
    }
    
    // Invoked by save menu item.
    @IBAction func saveDocument(_ sender: Any) {
        let responder = self.view.window?.firstResponder
        self.view.window?.makeFirstResponder(nil)
        resignFirstResponder()
        
        if let theme = self.theme, theme.isDirty {
            _ = saveTheme(theme)
        }
        // Restore previous responder.
        self.view.window?.makeFirstResponder(responder)
        responder?.resignFirstResponder()
    }
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            let anchor = "SyntaxHighlight_THEMES"
            
            NSHelpManager.shared.openHelpAnchor(anchor, inBook: locBookName)
        }
    }
    
    /// Save a theme.
    func saveTheme(_ theme: SCSHTheme, reply: ((Bool)->Void)? = nil) {
        guard theme.isDirty, !theme.isStandalone else {
            reply?(true)
            return
        }
        
        if theme.originalName == "" || theme.originalName != theme.name, let _ = customThemes.first(where: { $0.theme != theme && $0.theme.originalName == theme.name }) {
            let alert = NSAlert()
            
            alert.messageText = "Error"
            alert.informativeText = "Unable to save the theme \(theme.name) because another already exists with the same name!"
            alert.addButton(withTitle: "Close")
            
            alert.alertStyle = .critical
            reply?(false)
        }
        
        service?.saveTheme(theme.toDictionary() as NSDictionary) { (success, error) in
            if success {
                let oldName = theme.originalName
                theme.originalName = theme.name
                theme.isDirty = false
                NotificationCenter.default.post(name: .themeDidSaved, object: NotificationThemeSavedData(theme: theme, oldName: oldName))
                reply?(true)
            } else {
                print(error ?? "unknown error")
                DispatchQueue.main.sync {
                    let alert = NSAlert()
                    
                    alert.messageText = "Unable to save the theme \(theme.name)!"
                    alert.informativeText = error?.localizedDescription ?? ""
                    alert.addButton(withTitle: "Close")
                    
                    alert.alertStyle = .critical
                    alert.runModal()
                    reply?(false)
                }
            }
        }
    }
    
    /// Update the list of theme visible in the outline view.
    func refreshThemes(custom: Bool? = nil) {
        let filter_func = { (theme: SCSHThemePreview) -> Bool in
            if self.filter != "" {
                guard let _ = theme.theme.desc.range(of: self.filter, options: String.CompareOptions.caseInsensitive) else {
                    // Name don't match the search cryteria.
                    return false
                }
            }
            
            if self.showOnlyChanged && !theme.theme.isStandalone && !theme.theme.isDirty {
                // Theme is not changed or is not standalone.
                return false
            }
            
            switch self.style {
            case .light:
                if !theme.theme.isLight {
                    // Theme is not light.
                    return false
                }
            case .dark:
                if !theme.theme.isDark {
                    // Theme is not dark.
                    return false
                }
            default:
                break
            }
            
            return true
        }
        
        if custom == nil || custom == false {
            themes = allThemes.filter(filter_func)
        }
        if custom == nil || custom == true {
            customThemes = allCustomThemes.filter(filter_func).sorted(by: { $0.theme.desc < $1.theme.desc })
        }
    }
    
    /// Refresh the theme elements.
    func refreshThemeViews() {
        tableView?.reloadData()
        
        delThemeButton.isEnabled = !(theme?.isStandalone ?? true)
        
        examplesPopup.isEnabled = theme != nil
        refreshButton.isEnabled = theme != nil
        
        addKeywordMenuItem.isEnabled = !(theme?.isStandalone ?? true)
        actionsPupupButton.isEnabled = theme != nil
        saveButton.isEnabled = theme?.isDirty ?? false
        delThemeMenuItem.isEnabled = !(theme?.isStandalone ?? true)
        
        refreshPreview(self)
        
        let dirty = theme?.isDirty ?? false
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isEnabled = dirty
            fileMenu.submenu?.item(withTag: 102)?.isEnabled = customThemes.first(where: {$0.theme.isDirty}) != nil
        }
    }
}

// MARK: SCSHThemeDelegate
extension ThemesViewController: SCSHThemeDelegate {
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme) {
        if theme.isDirty {
            self.view.window?.isDocumentEdited = true
        } else {
            self.view.window?.isDocumentEdited = customThemes.first(where: { $0.theme.isDirty }) != nil
        }
        
        if theme == self.theme {
            refreshPreview(self)
            if let t = customThemes.first(where: { $0.theme == theme }) {
                // Reset current immage forcing refresh.
                t.image = nil
                // Reload the row.
                outlineView.reloadItem(t)
            }
            saveButton.isEnabled = theme.isDirty
        }
    }
    
    func themeDidChangeName(_ theme: SCSHTheme) {
        if let t = customThemes.first(where: { $0.theme == theme }) {
            // Relod the row in the outline view.
            outlineView.reloadItem(t)
        }
    }
    
    func themeDidChangeDescription(_ theme: SCSHTheme) {
        if let t = customThemes.first(where: { $0.theme == theme }) {
            outlineView.beginUpdates()
            
            // Reload the row in the outline view.
            outlineView.reloadItem(t)
            // Research and resort the list.
            refreshThemes(custom: true)
            
            outlineView.endUpdates()
        }
    }
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHThemePropertyProtocol) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
        if theme == self.theme {
            refreshPreview(self)
        }
    }
    
    func themeDidChangeCategories(_ theme: SCSHTheme) {
        // Research and resort the list.
        refreshThemes(custom: true)
    }
    
    func themeDidAddKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
    }
    
    func themeDidRemoveKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {
        if let t = allCustomThemes.first(where: { $0.theme == theme }) {
            // Reset the image forcing refresh.
            t.image = nil
            // Reload the row in the outline view if is presents.
            outlineView.reloadItem(t)
        }
    }
}

// MARK: - NSControlTextEditingDelegate
extension ThemesViewController: NSControlTextEditingDelegate {
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
       
        filter = self.searchField.stringValue
    }
}

// MARK: - NSOutlineViewDataSource
extension ThemesViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 2 // Standard and Custom item.
        } else if item as? String == "Standard" {
            // Standalone filtered themes.
            return themes.count
        } else if item as? String == "Custom" {
            // Customized filtered themes.
            return customThemes.count
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let theme = item as? SCSHThemePreview {
            return theme
        } else if item as? String == "Standard" || item as? String == "Custom" {
            return item
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            if index == 0 {
                return "Standard"
            } else {
                return "Custom"
            }
        } else if item as? String == "Standard" {
            return themes[index]
        } else if item as? String == "Custom" {
            return customThemes[index]
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is SCSHThemePreview {
            return false
        } else {
            return true
        }
    }
}

// MARK: - NSOutlineViewDelegate
extension ThemesViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return item as? String != nil  // Allow expansion of only Standard and custom items.
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let s = item as? String {
            if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleCell"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = s
                return cell
            }
        } else if let _ = item as? SCSHThemePreview {
            if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeCell"), owner: self) as? ThemeTableCellView {
                // The value for cell is passed with objectValue.
                return cell
            }
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if let _ = item as? SCSHThemePreview {
            return 70
        } else {
            return outlineView.rowHeight
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return item is SCSHThemePreview // Are selectable only theme rows.
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if outlineView.selectedRow >= 0, let item = outlineView.item(atRow: outlineView.selectedRow) as? SCSHThemePreview {
            self.theme = item.theme
        }
    }
    
    /*
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return item is String
    }
 */
}

// MARK: - WKNavigationDelegate
extension ThemesViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let c = NSColor.selectedControlColor.toHexString()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            // Encapsulate a script to handle click on the property elements.
            self.webView.evaluateJavaScript("""
            (function() {
                if (window.css_initialized) {
                    return;
                }
                window.css_initialized = true
                const style=document.createElement('style');
                style.type='text/css';
                const css = "<style type='text/css'>* {transition: background-color 0.5s; box-sizing: border-box; } .blink {background-color: \(c);}</style>";
                
                
                style.appendChild(document.createTextNode(css));
                document.getElementsByTagName('head')[0].appendChild(style);
                
                window.blinkProperty = function(selector) {
                    const color = "\(c)";
                    console.log(selector);
                    const e = jQuery(selector).addClass("blink");
                    window.setTimeout(function() {
                        e.removeClass("blink");
                    }, 500);
                }

                window.jQuery('html').css({ height: "100%" });
                window.jQuery('body').css({ height: "100%" });
                window.jQuery('.hl').click(function(event) {
                    let classes = [];
                    const css = this.classList;
                    classes.push(this.tagName)
                    for (var i = 0; i < css.length; i++) {
                        classes.push(css.item(i))
                    }
                    window.webkit.messageHandlers.jsHandler.postMessage({classes: classes, text: this.innerHTML});
                    event.stopPropagation();
                });
            })();
                
            true; // result returned to swift
            """){ (result, error) in
                if let e = error {
                    print(e)
                }
            }
        })
        
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.isHidden = false
    }
}

// MARK: - WKScriptMessageHandler
extension ThemesViewController: WKScriptMessageHandler {
    /// Handle messages from the webkit.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "jsHandler", let result = message.body as? [String: Any], let classes = result["classes"] as? [String] else {
            return
        }
        
        let name: SCSHTheme.Property.Name
        if classes.first == "BODY" {
            name = .canvas
        } else {
            guard let className = classes.last, let n = SCSHTheme.Property.Name.nameForCSSClass(className) else {
                
                return
            }
            name = n
        }
        
        var index: Int?
        if name.isKeyword {
            index = SCSHTheme.Property.Name.indexOfKeyword(name)
            if index != nil {
                index = index! + SCSHTheme.Property.Name.standardProperties.count
            }
        } else {
            index = SCSHTheme.Property.Name.standardProperties.firstIndex(of: name)
        }
        
        guard index != nil else {
            return
        }
        
        tableView.scrollRowToVisible(index! + 3)
        
        if let row = tableView.rowView(atRow: index! + 3, makeIfNecessary: false) {
            // Blink the row.
            row.wantsLayer = true
            let layer = row.layer
            let anime = CABasicAnimation(keyPath: "backgroundColor")
            anime.fromValue = layer?.backgroundColor
            anime.toValue = NSColor.selectedControlColor.cgColor
            anime.duration = 0.25
            anime.autoreverses = true
            anime.repeatCount = 1
            layer?.add(anime, forKey: "backgroundColor")
        }
    }
}

// MARK: - NSTableViewDataSource
extension ThemesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return theme != nil ? theme!.numberOfProperties + 3 : 0 // Number of properties + name, description and style.
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row < 3 {
            if tableColumn?.identifier.rawValue == "label" {
                if row == 0 {
                    return "Name"
                } else if row == 1 {
                    return "Description"
                } else if row == 2 {
                    return "Style"
                }
            } else {
                return theme
            }
        } else if let name = SCSHTheme.Property.Name.nameAtIndex(row - 3) {
            let r: ThemePropertyData = (theme: theme, propertyName: name)
            
            return r
        }
        return nil
    }
}

// MARK: - NSTableViewDelegate
extension ThemesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "label" {
            if row < 3 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeNameLabelCell"), owner: self)
            } else if row >= 3 && row < theme!.numberOfProperties + 3 - theme!.keywords.count {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemePropertyLabelCell"), owner: self)
            } else {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeKeywordLabelCell"), owner: self)
            }
        } else {
            if row == 0 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeNameCell"), owner: self)
            } else if row == 1 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeDescriptionCell"), owner: self)
            } else if row == 2 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeStyleCell"), owner: self)
            } else {
                if tableColumn?.identifier.rawValue == "label" {
                } else {
                    return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemePropertyCell"), owner: self)
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row > 4
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row > 4, let name = SCSHTheme.Property.Name.nameAtIndex(row-3) else {
            return
        }
        
        let cssClass = "."+name.getCSSClasses().joined(separator: ".")
        webView.evaluateJavaScript(#"blinkProperty("\#(cssClass)")"#, completionHandler: nil)
       
        self.tableView.deselectRow(row)
    }
}

// MARK: - Theme Property Cells View

typealias ThemePropertyData = (theme: SCSHTheme?, propertyName: SCSHTheme.Property.Name)

// Theme cell with icon and description for the outline view.
class ThemeTableCellView: NSTableCellView {
    @IBOutlet weak var changedLabel: NSView!
    
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? SCSHThemePreview {
                if theme.image == nil {
                    theme.image = theme.theme.getImage(size: CGSize(width: 100, height: 100), font: NSFont(name: "Menlo", size: 4) ?? NSFont.systemFont(ofSize: 4))
                }
                
                imageView?.image = theme.image
                let label = NSMutableAttributedString()
                if !theme.theme.desc.isEmpty {
                    label.append(NSAttributedString(string: "\(theme.theme.desc)\n", attributes: [.font: NSFont.labelFont(ofSize: NSFont.systemFontSize)]))
                }
                label.append(NSAttributedString(string: "\(theme.theme.name)", attributes: [.font: NSFont.labelFont(ofSize: NSFont.smallSystemFontSize)]))
                    
                textField?.attributedStringValue = label
                changedLabel.isHidden = !theme.theme.isDirty
            } else {
                imageView?.image = nil
                textField?.stringValue = ""
                changedLabel.isHidden = true
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    internal func initialize() {
        imageView?.wantsLayer = true
        // Round the image.
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderColor = NSColor.gridColor.cgColor
        imageView?.layer?.borderWidth = 1
    }
}

/// Show the color and style of a single property of a theme.
class ThemePropertyTableCellView: NSTableCellView {
    @IBOutlet weak var style: NSSegmentedControl!
    @IBOutlet weak var colorWell: NSColorWell!
    
    override var objectValue: Any? {
        didSet {
            refreshCell()
        }
    }
    
    func refreshCell() {
        if let data = objectValue as? ThemePropertyData, let prop = data.theme?[data.propertyName]  {
            if let prop = prop as? SCSHTheme.Property {
                style?.setSelected(prop.isBold, forSegment: 0)
                style?.setSelected(prop.isItalic, forSegment: 1)
                style?.setSelected(prop.isUnderline, forSegment: 2)
                style?.isEnabled = true // !(data.theme?.isStandalone ?? true)
                style?.isHidden = false
            } else {
                style?.isHidden = true
            }
            
            colorWell?.color = NSColor(fromHexString: prop.color) ?? .clear
            colorWell?.isEnabled = true
            colorWell?.isBordered = !(data.theme?.isStandalone ?? true)
        } else {
            style?.isEnabled = false
            style?.setSelected(false, forSegment: 0)
            style?.setSelected(false, forSegment: 1)
            style?.setSelected(false, forSegment: 2)
            
            colorWell?.isEnabled = false
            colorWell?.color = .clear
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        guard let data = objectValue as? ThemePropertyData else {
            return
        }
        if data.theme?.isStandalone ?? true {
            // Ignore the input.
            refreshCell()
        } else {
            if let prop = data.theme?[data.propertyName] as? SCSHTheme.Property {
                prop.isBold = sender.isSelected(forSegment: 0)
                prop.isItalic = sender.isSelected(forSegment: 1)
                prop.isUnderline = sender.isSelected(forSegment: 2)
            }
        }
    }
    
    @IBAction func handleColorChange(_ sender: NSColorWell) {
        guard let data = objectValue as? ThemePropertyData else {
            return
        }
        if data.theme?.isStandalone ?? true {
            // Ignore the input.
            refreshCell()
        } else {
            data.theme?[data.propertyName]?.color = sender.color.toHexString()
        }
    }
}


/// Show the label of a property of a theme.
class ThemePropertyLabelTableCellView: NSTableCellView {
     override var objectValue: Any? {
        didSet {
            if let data = objectValue as? ThemePropertyData {
                textField?.stringValue = data.propertyName.description
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
    }
}

/// Show the label of a kyword of a theme.
class ThemeKeywordLabelTableCellView: NSTableCellView {
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var delButton: NSButton!
    
    override var objectValue: Any? {
        didSet {
            if let data = objectValue as? ThemePropertyData {
                textField?.stringValue = data.propertyName.description
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
        addButton.isHidden = true
        delButton.isHidden = true
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard let data = objectValue as? ThemePropertyData, let theme = data.theme, !theme.isStandalone else {
            return
        }
        addButton.isHidden = false
        delButton.isHidden = false
    }
    override func mouseExited(with event: NSEvent) {
        addButton.isHidden = true
        delButton.isHidden = true
    }
}

/// Global style (dark or light) for a theme.
class ThemeStyleTableCellView: NSTableCellView {
    @IBOutlet weak var style: NSSegmentedControl?

    override var objectValue: Any? {
        didSet {
            refreshCell()
        }
    }
    
    func refreshCell() {
        if let theme = objectValue as? SCSHTheme {
            style?.setSelected(theme.isLight, forSegment: 0)
            style?.setSelected(theme.isDark, forSegment: 1)
            style?.isEnabled = true // !theme.isStandalone
        } else {
            style?.setSelected(false, forSegment: 0)
            style?.setSelected(false, forSegment: 0)
            style?.isEnabled = false
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        guard let theme = objectValue as? SCSHTheme else {
            return
        }
        if theme.isStandalone {
            // Ignore the input.
            refreshCell()
        } else {
            theme.isLight = sender.isSelected(forSegment: 0)
        }
    }
}

/// String label.
class ThemeLabelTableCellView: NSTableCellView {
    override var objectValue: Any? {
        didSet {
            if let string = objectValue as? String {
                textField?.stringValue = string
            }
        }
    }
}

class ThemeTextFieldTableCellView: NSTableCellView, NSTextFieldDelegate {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? SCSHTheme {
                //textField?.isBordered = !theme.isStandalone
                textField?.drawsBackground = !theme.isStandalone
                textField?.isEditable = !theme.isStandalone
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField?.stringValue = ""
        textField?.isEditable = false
    }
    
    @IBAction func handleChange(_ sender: NSTextField) {
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        if let t = notification.object as? NSTextField {
            handleChange(t)
        }
    }
    
    func textDidChange(_ notification: Notification) {
        if let t = notification.object as? NSTextField {
            handleChange(t)
        }
    }
}

/// Name of the theme.
class ThemeNameTableCellView: ThemeTextFieldTableCellView {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? SCSHTheme {
                textField?.stringValue = theme.name
            }
        }
    }
    @IBAction override func handleChange(_ sender: NSTextField) {
        if let theme = objectValue as? SCSHTheme {
            theme.name = sender.stringValue
        }
    }
}

/// Description of a theme.
class ThemeDescriptionTableCellView: ThemeTextFieldTableCellView {
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? SCSHTheme {
                textField?.stringValue = theme.desc
            }
        }
    }
    
    @IBAction override func handleChange(_ sender: NSTextField) {
        if let theme = objectValue as? SCSHTheme {
            theme.desc = sender.stringValue
        }
    }
}

class ThemeNameFormatter: Formatter {
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange proposedSelRangePtr: NSRangePointer?, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let s = partialStringPtr.pointee as String
        
        let regex = try! NSRegularExpression(pattern: #"([^-a-zA-Z0-9_])"#, options: [.caseInsensitive])
        let range = NSMakeRange(0, s.count)
        let modString = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "_")
        
        if s != modString {
            partialStringPtr.pointee = modString as NSString
            return false
        }
        return true
    }
    
    override func string(for obj: Any?) -> String? {
        if let s = obj as? String {
            return s
        } else {
            return nil
        }
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as AnyObject
        if let s = obj?.pointee as? String {
            let regex = try! NSRegularExpression(pattern: #"([^-a-zA-Z0-9_])"#, options: [.caseInsensitive])
            let range = NSMakeRange(0, s.count)
            let modString = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "_")
            
            if s != modString {
                obj?.pointee = modString as NSString
                error?.pointee = "Invalid characters: allow only letters, numbers, hypen and underscore."
                return false
            }
            
            return true
        } else {
            return false
        }
    }
}

// MARK: - ThemesWindowController
class ThemesWindowController: NSWindowController, NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isHidden = false
        }
    }
    func windowDidResignKey(_ notification: Notification) {
        if let fileMenu = NSApplication.shared.menu?.item(withTag: 100) {
            fileMenu.submenu?.item(withTag: 101)?.isHidden = true
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let contentViewController = self.contentViewController as? ThemesViewController else {
            return true
        }
        if let _ = contentViewController.customThemes.first(where: { $0.theme.isDirty } ) {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.informativeText = "There are some modified themes. Do you want to save them before closing?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            
            alert.alertStyle = .warning
            
            switch alert.runModal() {
            case .alertThirdButtonReturn, .cancel: // Cancel
                return false
            case .alertSecondButtonReturn, .abort: // No
                return true
            case .alertFirstButtonReturn, .OK: // Yes, save!
                break
            default:
                return true
            }
        }
        return true
    }
}
