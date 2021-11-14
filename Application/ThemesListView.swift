//
//  ThemesListView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 12/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class ThemesListView: NSView, SettingsSplitViewElement {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    /// Search field for filter the theme list.
    @IBOutlet weak var searchField: NSSearchField!
    
    @IBOutlet weak var filterPopupButton: NSPopUpButton!
    
    @IBOutlet weak var showOnlyLightMenuItem: NSMenuItem!
    @IBOutlet weak var showOnlyDarkMenuItem: NSMenuItem!
    @IBOutlet weak var showUnsavedMenuItem: NSMenuItem!
    
    @IBOutlet weak var exportMenuItem: NSMenuItem!
    @IBOutlet weak var exportMenuItem2: NSMenuItem!
    @IBOutlet weak var settingsMenuItem: NSMenu!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
    @IBOutlet weak var deleteMenuItem2: NSMenuItem!
    @IBOutlet weak var duplicateMenuItem: NSMenuItem!
    @IBOutlet weak var duplicateMenuItem2: NSMenuItem!
    @IBOutlet weak var revealMenuItem: NSMenuItem!
    @IBOutlet weak var revealMenuItem2: NSMenuItem!
    @IBOutlet weak var noResultsFoundWarning: NSTextField!
    
    /// All (unfiltered) standard themes.
    var allThemes: [SCSHThemePreview] = [] {
        didSet {
            allStandardThemes = allThemes.filter({ $0.isStandalone })
            allCustomThemes = allThemes.filter({ !$0.isStandalone })
        }
    }
    
    /// All (unfiltered) standard themes.
    fileprivate (set) var allStandardThemes: [SCSHThemePreview] = [] {
        didSet {
            filterThemes(custom: false)
        }
    }
    
    /// All (unfiltered) custom themes.
    var allCustomThemes: [SCSHThemePreview] = [] {
        didSet {
            filterThemes(custom: true)
        }
    }
    
    var themes: [SCSHThemePreview] = [] {
        didSet {
            if oldValue != themes {
                outlineView?.reloadData()
                noResultsFoundWarning.isHidden = !(themes.isEmpty && customThemes.isEmpty)
            }
        }
    }
    
    /// Filtered custom themes.
    var customThemes: [SCSHThemePreview] = [] {
        didSet {
            if oldValue != customThemes {
                outlineView?.reloadData()
                noResultsFoundWarning.isHidden = !(themes.isEmpty && customThemes.isEmpty)
            }
        }
    }
    
    /// Current theme.
    var theme: SCSHThemePreview? {
        didSet {
            guard oldValue != theme else {
                return
            }
            exportMenuItem.isEnabled = theme != nil
            revealMenuItem.isEnabled = theme?.exists ?? false
            duplicateMenuItem.isEnabled = theme != nil
            deleteMenuItem.isEnabled = !(theme?.isStandalone ?? true)
            
            themeEditView?.theme = theme
            
            if let theme = self.theme {
                let row: Int
                if theme.isStandalone, let index = themes.firstIndex(of: theme) {
                    row = index + 1
                } else if !theme.isStandalone, let index = customThemes.firstIndex(of: theme) {
                    row = index + 1 + themes.count + 1
                } else {
                    row = -1
                }
                if row >= 0 {
                    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                    outlineView.scrollRowToVisible(row)
                }
            }
        }
    }
    
    /// Filter for theme name.
    var filter: String = "" {
        didSet {
            filterThemes()
        }
    }
    
    /// Filter for theme style (light/dark).
    var style: ThemeStyleFilterEnum = .all {
        didSet {
            switch style {
            case .all:
                showOnlyLightMenuItem.state = .off
                showOnlyDarkMenuItem.state = .off
            case .light:
                showOnlyLightMenuItem.state = .on
                showOnlyDarkMenuItem.state = .off
            case .dark:
                showOnlyLightMenuItem.state = .off
                showOnlyDarkMenuItem.state = .on
            }
            filterThemes()
        }
    }
    
    /// Filter for only changed themes.
    var showOnlyChanged: Bool = false {
        didSet {
            showUnsavedMenuItem.state = showOnlyChanged ? .on : .off
            filterThemes()
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
        
        self.outlineView.beginUpdates()
        
        // Fetch the themes.
        self.allThemes = HighlightWrapper.shared.themes
        
        if self.allStandardThemes.count > 0 {
            self.outlineView.expandItem("Standard")
        }
        if self.allCustomThemes.count > 0 {
            self.outlineView.expandItem("Custom")
        }
        
        self.outlineView.endUpdates()
        if #available(macOS 11.0, *) { } else {
            self.outlineView.indentationPerLevel = 8
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeRefresh(_:)), name: .ThemeIsDirty, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeRefresh(_:)), name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDeleted(_:)), name: .CustomThemeRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeAdded(_:)), name: .CustomThemeAdded, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAdvancedSettings(_:)), name: .AdvancedSettings, object: nil)
        
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(_:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .ThemeIsDirty, object: nil)
        NotificationCenter.default.removeObserver(self, name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.removeObserver(self, name: .CustomThemeRemoved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .CustomThemeAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AdvancedSettings, object: nil)
        
        DistributedNotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    @objc internal func handleAdvancedSettings(_ notification: Notification) {
        let index = outlineView.selectedRow
        outlineView.reloadData()
        outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }
    
    @objc internal func interfaceModeChanged(_ sender: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.outlineView.reloadData()
        })
    }
    
    @objc internal func handleThemeRefresh(_ notification: Notification) {
        guard let theme = notification.object as? SCSHThemePreview else {
            return
        }
        if let index = self.themes.firstIndex(of: theme) {
            outlineView.reloadData(forRowIndexes: IndexSet(integer: index+1), columnIndexes: IndexSet(integer: 0))
        } else if let index = self.customThemes.firstIndex(of: theme) {
            outlineView.reloadData(forRowIndexes: IndexSet(integer: index+1 + (themes.isEmpty ? 0 : themes.count + 1)), columnIndexes: IndexSet(integer: 0))
        }
    }
    
    @objc internal func handleThemeDeleted(_ notification: Notification) {
        self.allCustomThemes = HighlightWrapper.shared.themes.filter({ !$0.isStandalone })
    }
    
    @objc internal func handleThemeAdded(_ notification: Notification) {
        self.allCustomThemes = HighlightWrapper.shared.themes.filter({ !$0.isStandalone })
        if let theme = notification.object as? SCSHThemePreview {
            self.theme = theme
        }
    }
    
    @IBAction func handleLightMenu(_ sender: Any) {
        if style == .light {
            style = .all
        } else {
            style = .light
        }
    }
    @IBAction func handleDarkMenu(_ sender: Any) {
        if style == .dark {
            style = .all
        } else {
            style = .dark
        }
    }
    
    @IBAction func handleUnsavedMenu(_ sender: Any) {
        self.showOnlyChanged = !self.showOnlyChanged
    }
    
    @IBAction func exportTheme(_ sender: Any) {
        guard let theme = sender as? NSMenuItem == exportMenuItem2 ? outlineView.item(atRow: outlineView.clickedRow) as? SCSHThemePreview : self.theme else {
            return
        }
        
        theme.browseToExport()
    }
    
    @IBAction func revealTheme(_ sender: Any) {
        guard let path = (sender as? NSMenuItem == revealMenuItem2 ? outlineView.item(atRow: outlineView.clickedRow) as? SCSHThemePreview : self.theme)?.path else {
            return
        }
        
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
    
    @IBAction func importTheme(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.showsTagField = false
        openPanel.allowedFileTypes = ["theme"]
        openPanel.isExtensionHidden = false
        openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = openPanel.runModal()
        
        guard result == .OK, let src = openPanel.url else {
            return
        }
        
        var theme: SCSHThemePreview?
        _ = withUnsafeMutablePointer(to: &theme) { (ptr) in
            highlight_get_theme(src.path, ptr) { (context, theme, exit_code) in
                if exit_code == EXIT_SUCCESS, let theme = theme {
                    let t = context?.assumingMemoryBound(to: SCSHTheme.self)
                    t?.pointee = SCSHThemePreview(cTheme: theme.pointee)
                }
            }
        }
        guard theme != nil else {
            let alert = NSAlert()
            alert.messageText = "Invalid file"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        var r = false
        do {
            r = try HighlightWrapper.shared.importCustomTheme(theme!, overwrite: false)
        } catch {
            if let e = error as? HighlightWrapperError {
                switch e {
                case .themeExists(let path):
                    let alert = NSAlert()
                    alert.messageText = "A theme already exists with the same name. \nDo you want to overwrite?"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
                    alert.addButton(withTitle: "Yes")
                    if alert.runModal() == .alertSecondButtonReturn {
                        do {
                            try FileManager.default.removeItem(at: path)
                            r = try HighlightWrapper.shared.importCustomTheme(theme!, overwrite: true)
                        } catch {
                            
                        }
                    } else {
                        return
                    }
                }
            }
        }
        guard r else {
            let alert = NSAlert()
            alert.messageText = "Unable to import the theme!"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Fetch the themes.
        let themes = HighlightWrapper.shared.themes
        
        self.outlineView.beginUpdates()
        self.allCustomThemes = themes.filter({ !$0.isStandalone })
        self.theme = theme
        self.outlineView.endUpdates()
    }
    
    /// Duplicate the current theme.
    @IBAction func handleDuplicate(_ sender: Any) {
        guard let theme = sender as? NSMenuItem == duplicateMenuItem2 ? outlineView.item(atRow: outlineView.clickedRow) as? SCSHThemePreview : self.theme else {
            return
        }
        
        _ = HighlightWrapper.shared.duplicateTheme(theme: theme)
    }
    
    @IBAction func handleAddTheme(_ sender: Any) {
        _ = HighlightWrapper.shared.addNewEmptyTheme()
    }
    
    /// Delete the current theme.
    @IBAction func handleDelTheme(_ sender: Any) {
        guard let theme = sender as? NSMenuItem == deleteMenuItem2 ? outlineView.item(atRow: outlineView.clickedRow) as? SCSHThemePreview : self.theme, !theme.isStandalone else {
            return
        }
        
        HighlightWrapper.shared.removeCustomTheme(theme, withAsk: true, sheetWindow: self.contentView.window, withErrorMessage: true) { (success, error) in
            if success {
                self.theme = nil
            }
        }
    }
    
    /// Update the list of theme visible in the outline view.
    func filterThemes(custom: Bool? = nil) {
        filterPopupButton.contentTintColor = (showOnlyChanged || style != .all) ? .controlAccentColor : nil
        
        let filter_func = { (theme: SCSHThemePreview) -> Bool in
            if !self.filter.isEmpty {
                guard theme.desc.range(of: self.filter, options: String.CompareOptions.caseInsensitive) != nil else {
                    // Description do not match the search criteria.
                    return false
                }
            }
            
            if self.showOnlyChanged && !theme.isDirty {
                // Theme is not changed or is not standalone.
                return false
            }
            
            switch self.style {
            case .light:
                if !theme.isLight {
                    // Theme is not light.
                    return false
                }
            case .dark:
                if !theme.isDark {
                    // Theme is not dark.
                    return false
                }
            default:
                break
            }
            
            return true
        }
        
        outlineView.beginUpdates()
        if custom == nil || custom == false {
            themes = allStandardThemes.filter(filter_func)
        }
        if custom == nil || custom == true {
            customThemes = allCustomThemes.filter(filter_func).sorted(by: { $0.desc < $1.desc })
        }
        var row: Int?
        if self.themes.count > 0 {
            self.outlineView.expandItem("Standard")
            if let theme = self.theme, let index = themes.firstIndex(of: theme) {
                row = index+1
            }
        }
        if self.customThemes.count > 0 {
            self.outlineView.expandItem("Custom")
            if let theme = self.theme, let index = customThemes.firstIndex(of: theme) {
                row = index + 1 + (self.themes.count > 0 ? self.themes.count + 1 : 0)
            }
        }
        outlineView.endUpdates()
        if row != nil {
            outlineView.selectRowIndexes(IndexSet(integer: row!), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row!)
        } else {
            exportMenuItem.isEnabled = false
            revealMenuItem.isEnabled = false
            deleteMenuItem.isEnabled = false
            duplicateMenuItem.isEnabled = false
        }
    }
}

// MARK: - NSControlTextEditingDelegate
extension ThemesListView: NSControlTextEditingDelegate {
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
       
        filter = self.searchField.stringValue
    }
}

// MARK: - NSOutlineViewDataSource
extension ThemesListView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            if themes.isEmpty && customThemes.isEmpty {
                return 0
            } else if !themes.isEmpty && !customThemes.isEmpty {
                return 2
            } else {
                return 1
            }
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
            if !themes.isEmpty && !customThemes.isEmpty {
                if index == 0 {
                    return "Standard"
                } else {
                    return "Custom"
                }
            } else if !themes.isEmpty {
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
extension ThemesListView: NSOutlineViewDelegate {
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
            return 100
        } else {
            return outlineView.rowHeight
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return item is SCSHThemePreview // Are selectable only theme rows.
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if outlineView.selectedRow >= 0, let item = outlineView.item(atRow: outlineView.selectedRow) as? SCSHThemePreview {
            self.theme = item
        }
    }
}

extension ThemesListView: NSMenuDelegate {
    var settingsController: SettingsSplitViewController? {
        return self.window?.windowController?.contentViewController as? SettingsSplitViewController
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let theme = outlineView.item(atRow: outlineView.clickedRow) as? SCSHThemePreview
        exportMenuItem2.isEnabled = theme != nil
        revealMenuItem2.isEnabled = theme != nil && theme!.exists
        duplicateMenuItem2.isEnabled = theme != nil
        deleteMenuItem2.isEnabled = theme != nil && !theme!.isStandalone
        let settings = theme != nil ? SCSHWrapper.shared.getFormatsUsedBy(theme: theme!.nameForSettings) : []
        settingsMenuItem.removeAllItems()
        
        let UTIs = (NSApplication.shared.delegate as? AppDelegate)?.handledUTIs ?? []
        for s in settings {
            if s is Settings {
                settingsMenuItem.addItem(withTitle: "General settings", action: #selector(self.handleSettingsMenu(_:)), keyEquivalent: "")
            } else if let s = s as? SettingsFormat {
                for u in UTIs {
                    if u.UTI == s.uti {
                        settingsMenuItem.addItem(withTitle: u.description, action: #selector(self.handleSettingsMenu(_:)), keyEquivalent: "").representedObject = u
                        break
                    }
                }
            }
        }
        
        if settingsMenuItem.items.isEmpty {
            settingsMenuItem.addItem(withTitle: "None", action: nil, keyEquivalent: "")
        }
    }
    
    @objc func handleSettingsMenu(_ sender: NSMenuItem) {
        if let u = sender.representedObject as? UTI {
            settingsController?.selectUTI(u)
        } else {
            settingsController?.mode = .global
        }
    }
}

// Theme cell with icon and description for the outline view.
class ThemeTableCellView: NSTableCellView {
    @IBOutlet weak var changedLabel: NSView!
    @IBOutlet weak var htmlLabel: NSView!
    @IBOutlet weak var usedLabel: NSView!
    
    override var objectValue: Any? {
        didSet {
            if let theme = objectValue as? SCSHThemePreview {
                imageView?.image = theme.image
                textField?.stringValue = theme.desc
                changedLabel.isHidden = !theme.isDirty
                htmlLabel.isHidden = !theme.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false))
                usedLabel.isHidden = SCSHWrapper.shared.getFormatsUsedBy(theme: theme.nameForSettings).isEmpty
            } else {
                imageView?.image = nil
                textField?.stringValue = ""
                changedLabel.isHidden = true
                htmlLabel.isHidden = true
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
        imageView?.layer?.cornerRadius = 4
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.gray.cgColor
    }
}
