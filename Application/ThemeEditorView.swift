//
//  ThemeEditorView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 13/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa



class ThemeEditorView: NSView, SettingsSplitViewElement {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var horizontalLine1: NSBox!
    @IBOutlet weak var horizontalLine2: NSBox!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var boldButton: NSButton!
    @IBOutlet weak var italicButton: NSButton!
    @IBOutlet weak var underlineButton: NSButton!
    @IBOutlet weak var CSSButton: NSButton!
    @IBOutlet weak var actionPopupButton: NSPopUpButton!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var styleLabel: NSTextField!
    @IBOutlet weak var styleSegmentesControl: NSSegmentedControl!
    
    @IBOutlet weak var newKeywordMenuItem: NSMenuItem!
    @IBOutlet weak var revealMenuItem: NSMenuItem!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
    
    @IBOutlet weak var messageLabel: NSTextField!
    
    var theme: SCSHTheme? {
        didSet {
            guard oldValue != theme else {
                return
            }
            
            oldValue?.delegate = nil
            theme?.delegate = self
            
            if let theme = self.theme {
                scrollView.isHidden = false
                horizontalLine1.isHidden = false
                horizontalLine2.isHidden = false
                
                colorWell.isHidden = false
                boldButton.isHidden = false
                italicButton.isHidden = false
                underlineButton.isHidden = false
                CSSButton.isHidden = false
                
                descriptionLabel.isHidden = false
                descriptionTextField.isHidden = false
                descriptionTextField.stringValue = theme.desc
                descriptionTextField.isEnabled = !theme.isStandalone
                styleLabel.isHidden = false
                styleSegmentesControl.isHidden = false
                styleSegmentesControl.isEnabled = !theme.isStandalone
                if theme.isLight && theme.isDark {
                    styleSegmentesControl.setSelected(true, forSegment: 2)
                } else if theme.isLight {
                    styleSegmentesControl.setSelected(true, forSegment: 0)
                } else if theme.isDark {
                    styleSegmentesControl.setSelected(true, forSegment: 1)
                } else {
                    styleSegmentesControl.setSelected(true, forSegment: 2)
                }
                
                actionPopupButton.isHidden = false
                messageLabel.isHidden = true
                
                newKeywordMenuItem.isEnabled = !theme.isStandalone
                deleteMenuItem.isEnabled = !theme.isStandalone
                revealMenuItem.isEnabled = theme.exists
            } else {
                scrollView.isHidden = true
                horizontalLine1.isHidden = true
                horizontalLine2.isHidden = true
                
                colorWell.isHidden = true
                boldButton.isHidden = true
                italicButton.isHidden = true
                underlineButton.isHidden = true
                CSSButton.isHidden = true
                
                descriptionLabel.isHidden = true
                descriptionTextField.isHidden = true
                styleLabel.isHidden = true
                styleSegmentesControl.isHidden = true
                
                actionPopupButton.isHidden = true
                messageLabel.isHidden = false
                
                newKeywordMenuItem.isEnabled = false
                deleteMenuItem.isEnabled = false
                revealMenuItem.isEnabled = false
            }
            
            property = nil
            
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            tableView.scrollRowToVisible(0)
            
            requestPreviewRefresh()
        }
    }
    
    var property: SCSHTheme.PropertyName? {
        didSet {
            guard property != oldValue else {
                return
            }
            refreshPropertyButtons()
        }
    }
    
    internal func refreshPropertyButtons() {
        if let property = self.property, let theme = self.theme {
            colorWell.isEnabled = !theme.isStandalone
            colorWell.color = NSColor(fromHexString: theme[property]!.color) ?? .clear
            
            let special = property == .canvas || property == .lspHover
            boldButton.isHidden = special
            italicButton.isHidden = special
            underlineButton.isHidden = special
            CSSButton.isHidden = false
            
            if let prop = theme[property] as? SCSHTheme.Property {
                let customStyle = prop.getCustomStyle(for: "html")
                
                colorWell.isEnabled = !theme.isStandalone && customStyle?.override != true
                
                boldButton.isEnabled = !theme.isStandalone && customStyle?.override != true
                boldButton.state = prop.isBold ? .on : .off
                italicButton.isEnabled = !theme.isStandalone && customStyle?.override != true
                italicButton.state = prop.isItalic ? .on : .off
                underlineButton.isEnabled = !theme.isStandalone && customStyle?.override != true
                underlineButton.state = prop.isUnderline ? .on : .off
                
                CSSButton.state = customStyle != nil ? .on : .off
                CSSButton.isEnabled = CSSButton.state == .on || !theme.isStandalone
            } else {
                boldButton.state = .off
                italicButton.state = .off
                underlineButton.state = .off
                CSSButton.state = .off
                CSSButton.isEnabled = false
            }
            colorWell.isHidden = property == .lspHover
        } else {
            colorWell.isHidden = true
            boldButton.isHidden = true
            italicButton.isHidden = true
            underlineButton.isHidden = true
            colorWell.isEnabled = false
            colorWell.color = .clear
            boldButton.isEnabled = false
            italicButton.isEnabled = false
            underlineButton.isEnabled = false
            CSSButton.isHidden = true
        }
    }
    
    var isAdvancedSettingsVisible: Bool = false {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var numberOfStandardTokens: Int {
        return SCSHTheme.PropertyName.numberOfStandardCases
    }
    var numberOfKeywords: Int {
        return theme?.keywords.count ?? 0
    }
    var numberOfLSPTokesn: Int {
        return isAdvancedSettingsVisible ? SCSHTheme.PropertyName.numberOfLSPCases : 0
    }
    
    var rowIndexOfStandardGroup: Int {
        return 0
    }
    
    var rowIndexOfLSP: Int {
        return isAdvancedSettingsVisible ? numberOfStandardTokens + 1 : -1
    }
    
    var rowIndexOfKeywords: Int {
        return isAdvancedSettingsVisible ? numberOfStandardTokens + numberOfLSPTokesn + 2 : numberOfStandardTokens + 1
    }

    func propertyNameIndexFromRow(_ index: Int) -> Int {
        if index == rowIndexOfStandardGroup || index == rowIndexOfKeywords || index == rowIndexOfLSP {
            return -1
        }
        var row = index - 1 // Remove first standard header
        
        if index > numberOfStandardTokens {
            row -= 1 // Remove LS / Keywords head.
            
            if !isAdvancedSettingsVisible {
                row += SCSHTheme.PropertyName.numberOfLSPCases
            } else if index > rowIndexOfLSP {
                row -= 1
            }
            
        }
        
        return row
    }
    
    func propertyNameFromRow(_ index: Int) -> SCSHTheme.PropertyName? {
        return SCSHTheme.PropertyName.init(index: propertyNameIndexFromRow(index))
    }
    
    func rowIndexFromPropertyName(_ name: SCSHTheme.PropertyName) -> Int {
        if name.isStandard {
            return name.index + 1 // title of standard section
        } else if name.isLSP {
            return isAdvancedSettingsVisible ? name.index + 3 : -1
        } else if name.isKeyword {
            var index = name.index + 2 // title of standard and keywords section
            if isAdvancedSettingsVisible {
                index += 1 // title of LS section
            } else {
                index -= SCSHTheme.PropertyName.numberOfLSPCases
            }
            return index
        } else {
            return -1
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
        
        scrollView.isHidden = true
        horizontalLine1.isHidden = true
        horizontalLine2.isHidden = true
        
        colorWell.isHidden = true
        boldButton.isHidden = true
        italicButton.isHidden = true
        underlineButton.isHidden = true
        CSSButton.isHidden = true
        
        descriptionLabel.isHidden = true
        descriptionTextField.isHidden = true
        styleLabel.isHidden = true
        styleSegmentesControl.isHidden = true
        
        actionPopupButton.isHidden = true
        messageLabel.isHidden = false
        
        newKeywordMenuItem.isEnabled = false
        deleteMenuItem.isEnabled = false
        
        NSColorPanel.shared.isContinuous = self.colorWell.isContinuous
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChanged(_:)), name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDeleted(_:)), name: .CustomThemeRemoved, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.removeObserver(self, name: .CustomThemeRemoved, object: nil)
    }
    
    @objc internal func handleThemeSelected(_ notification: Notification) {
        if let theme = notification.object as? SCSHTheme {
            self.theme = theme
        } else {
            self.theme = nil
        }
    }
    
    @objc internal func handleThemeChanged(_ notification: Notification) {
        guard let theme = notification.object as? SCSHThemePreview, theme == self.theme else {
            return
        }
        requestPreviewRefresh()
    }
    
    @objc internal func handleThemeDeleted(_ notification: Notification) {
        if let theme = notification.object as? SCSHTheme, theme.nameForSettings == self.theme?.nameForSettings {
            self.theme = nil
        }
    }
    
    func selectProperty(_ property: SCSHTheme.PropertyName) {
        let row = self.rowIndexFromPropertyName(property)
        if row > 0 {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.scrollRowToVisible(row)
        }
    }
    
    @IBAction internal func deleteTheme(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        HighlightWrapper.shared.removeCustomTheme(theme, withAsk: true, sheetWindow: self.contentView.window, withErrorMessage: true) { (success, error) in
            if success {
                self.theme = nil
            }
        }
    }
    
    @IBAction func handleDuplicate(_ sender: Any) {
        guard let theme = self.theme else {
            return
        }
        
        _ = HighlightWrapper.shared.duplicateTheme(theme: theme)
    }
    
    @IBAction func handleDescChanged(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else { return }
        theme.desc = descriptionTextField.stringValue
    }
    
    
    @IBAction func handleStyleChanged(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else { return }
        if self.styleSegmentesControl.indexOfSelectedItem == 0 {
            theme.isLight = true
        } else if self.styleSegmentesControl.indexOfSelectedItem == 1 {
            theme.isDark = true
        } else {
            theme.isLight = false
            theme.isDark = false
        }
    }
    
    func addKeword(atIndex index: Int) {
        guard  let theme = self.theme, !theme.isStandalone, theme.keywords.count < 25 else {
            return
        }
        
        tableView.beginUpdates()
        
        let n = theme.keywords.count
        let keyword = SCSHTheme.Property(color: NSColor.random().toHexString() ?? "#000000")
        let name = index < 0 ? theme.appendKeyword(keyword) : theme.insertKeyword(keyword, at: index)
        
        let newIndex = rowIndexFromPropertyName(name)
        if n == 0 {
            tableView.insertRows(at: IndexSet(integer: rowIndexOfKeywords), withAnimation: .slideUp)
        }
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .slideUp)
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: newIndex...rowIndexFromPropertyName(.keyword(index: theme.keywords.count-1))), columnIndexes: IndexSet(0...1))
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(newIndex)
        tableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
    }
    
    func delKeword(atIndex index: Int) {
        guard  let theme = self.theme, !theme.isStandalone, index >= 0 && index < theme.keywords.count else {
            return
        }
        let alert = NSAlert()
        alert.messageText = "Are you sure to remove the keyword \(index+1)?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes").keyEquivalent = "\r"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        alert.beginSheetModal(for: self.contentView.window!) { (response) in
            guard response == .alertFirstButtonReturn else { return }
            
            self.tableView.beginUpdates()
            
            theme.removeKeyword(at: index)
            
            var newIndex = self.rowIndexFromPropertyName(.keyword(index: index-1 > 0 ? index-1 : 0))
                
            self.tableView.removeRows(at: IndexSet(integer: self.rowIndexFromPropertyName(.keyword(index: index))), withAnimation: .slideDown)
            if theme.keywords.count == 0 {
                self.tableView.removeRows(at: IndexSet(integer: self.rowIndexOfKeywords), withAnimation: .slideDown)
                newIndex -= 2
            } else {
                self.tableView.reloadData(forRowIndexes: IndexSet(integersIn: newIndex...self.rowIndexFromPropertyName(.keyword(index: theme.keywords.count-1))), columnIndexes: IndexSet(0...1))
            }
        
            self.tableView.endUpdates()
            
            self.tableView.scrollRowToVisible(newIndex)
            self.tableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
        }
    }
    
    @IBAction func handleAddKeyword(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone else {
            return
        }
        
        if let menu = sender as? NSMenuItem, let keyword = (menu.representedObject as? SCSHTheme.PropertyName)?.keywordIndex {
            if menu.tag == 1 {
                addKeword(atIndex: -1)
            } else {
                addKeword(atIndex: menu.tag == 2 ? keyword : keyword + 1)
            }
        } else {
            addKeword(atIndex: -1)
        }
    }
    
    @IBAction func handleDelKeyword(_ sender: NSMenuItem) {
        guard let theme = self.theme, !theme.isStandalone, let keyword = (sender.representedObject as? SCSHTheme.PropertyName)?.keywordIndex else {
            return
        }
        self.delKeword(atIndex: keyword)
    }
    
    @IBAction func handleBold(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone, let prop_name = (sender as? NSMenuItem)?.representedObject as? SCSHTheme.PropertyName ?? self.property, let prop = theme[prop_name] as? SCSHTheme.Property else { return }
        prop.isBold = !prop.isBold
        boldButton.state = prop.isBold ? .on : .off
        let index = self.rowIndexFromPropertyName(prop_name)
        tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }
    
    @IBAction func handleItalic(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone, let prop_name = (sender as? NSMenuItem)?.representedObject as? SCSHTheme.PropertyName ?? self.property, let prop = theme[prop_name] as? SCSHTheme.Property else { return }
        prop.isItalic = !prop.isItalic
        italicButton.state = prop.isItalic ? .on : .off
        let index = self.rowIndexFromPropertyName(prop_name)
        tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }
    
    @IBAction func handleUnderline(_ sender: Any) {
        guard let theme = self.theme, !theme.isStandalone, let prop_name = (sender as? NSMenuItem)?.representedObject as? SCSHTheme.PropertyName ?? self.property, let prop = theme[prop_name] as? SCSHTheme.Property else { return }
        prop.isUnderline = !prop.isUnderline
        underlineButton.state = prop.isUnderline ? .on : .off
        let index = self.rowIndexFromPropertyName(prop_name)
        tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }
    
    @IBAction func handleCSS(_ sender: Any) {
        guard let theme = self.theme, let prop_name = (sender as? NSMenuItem)?.representedObject as? SCSHTheme.PropertyName ?? self.property, let prop = theme[prop_name], let vc = NSStoryboard(name: "Storyboard", bundle: nil).instantiateController(withIdentifier: "CustomStyleEditor") as? CSSControlViewController else {
            return
        }
        
        vc.mode = .themeProperty
        vc.isEditable = !theme.isStandalone
        let propertyStyle = prop.getCustomStyle(for: "html")
        vc.cssCode = propertyStyle?.style ?? ""
        vc.isStandardPropertiesOverridden = propertyStyle?.override ?? false
        vc.handler = { [weak self] (css, override, status) in
            guard status else { return }
            prop.setCustomStyle(for: "html", style: (style: css, override: override))
            self?.tableView.reloadData(forRowIndexes: IndexSet(integer: self?.rowIndexFromPropertyName(prop_name) ?? -1), columnIndexes: IndexSet(0...1))
            self?.refreshPropertyButtons()
        }
        self.window?.contentViewController?.presentAsSheet(vc)
    }
    
    @IBAction func handleColorChange(_ sender: NSColorWell) {
        guard let prop_name = self.property, let theme = self.theme, let color = sender.color.toHexString(), let prop = theme[prop_name] else { return }
        prop.color = color
        if prop is SCSHTheme.Property {
            let row = self.rowIndexFromPropertyName(prop_name)
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0...1))
            if prop_name == .plain {
                tableView.reloadData(forRowIndexes: IndexSet(integer: self.rowIndexFromPropertyName(.canvas)), columnIndexes: IndexSet(0...1))
            }
        } else {
            tableView.reloadData()
        }
    }
    
    @IBAction func exportTheme(_ sender: Any) {
        theme?.browseToExport()
    }
    
    @IBAction func revealTheme(_ sender: Any) {
        guard let path = self.theme?.path else {
            return
        }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
    
    func requestPreviewRefresh() {
        guard let settings = SCSHWrapper.shared.settings?.duplicate(), let theme = self.theme else {
            previewView?.settings = nil
            return
        }
        
        settings.format = .html // Prefer html engine to handle the custom CSS
        settings.isLightThemeNameDefined = true
        settings.lightThemeName = theme.nameForSettings
        settings.lightBackgroundColor = theme.backgroundColor
        settings.lightForegroundColor = theme.foregroundColor
        
        settings.isDarkThemeNameDefined = true
        settings.darkThemeName = theme.nameForSettings
        settings.darkBackgroundColor = theme.backgroundColor
        settings.darkForegroundColor = theme.foregroundColor
        settings.isLineNumbersDefined = true
        settings.isLineNumbersVisible = true
        settings.isArgumentsDefined = true
        settings.arguments += " --plug-in=html_editor"
        
        previewView?.settings = settings
        previewView?.highlightedProperty = self.propertyNameFromRow(self.tableView.selectedRow)
    }
}

// MARK: - NSTableViewDelegate
extension ThemeEditorView: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let prop = propertyNameFromRow(tableView.selectedRow) {
            self.property = prop
        } else {
            self.property = nil
        }
        previewView?.highlightedProperty = self.property
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == rowIndexOfStandardGroup || row == rowIndexOfKeywords || row == rowIndexOfLSP {
            if tableColumn?.identifier.rawValue == "style" {
                return nil
            }
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupCell"), owner: nil) as? NSTableCellView
            if row == rowIndexOfStandardGroup {
                cell?.textField?.stringValue = "Standard tokens"
            } else if row == rowIndexOfKeywords {
                cell?.textField?.stringValue = "Keywords"
            } else if row == rowIndexOfLSP {
                cell?.textField?.stringValue = "Language Server semantic tokens"
            }
            return cell
        } else if tableColumn?.identifier.rawValue == "style" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeCSS"), owner: nil) as? NSTableCellView
            
            if let prop = propertyNameFromRow(row), let theme = self.theme {
                let style = theme[prop]?.getCustomStyle(for: "html")
                if style == nil {
                    cell?.imageView?.image = nil
                } else if style!.override {
                    if #available(macOS 11.0, *) {
                        cell?.imageView?.image = NSImage(systemSymbolName: "safari.fill", accessibilityDescription: nil)
                    } else {
                        cell?.imageView?.image = NSImage(named: "safari.fill")
                    }
                } else {
                    if #available(macOS 11.0, *) {
                        cell?.imageView?.image = NSImage(systemSymbolName: "safari", accessibilityDescription: nil)
                    } else {
                        cell?.imageView?.image = NSImage(named: "safari")
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemePropertyCell"), owner: nil) as? ThemeCellView
            cell?.addKeywordAction = { [weak self] index in
                self?.addKeword(atIndex: index+1)
            }
            cell?.delKeywordAction = { [weak self] index in
                self?.delKeword(atIndex: index)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return row == rowIndexOfStandardGroup || row == rowIndexOfKeywords || row == rowIndexOfLSP
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row != rowIndexOfStandardGroup && row != rowIndexOfKeywords && row != rowIndexOfLSP
    }
}

// MARK: - NSTableViewDataSource
extension ThemeEditorView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let theme = self.theme {
            return 1 + SCSHTheme.PropertyName.numberOfStandardCases + 1 + theme.keywords.count +  (isAdvancedSettingsVisible ? 1 + SCSHTheme.PropertyName.numberOfLSPCases : 0)
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let prop = propertyNameFromRow(row), let theme = self.theme {
            return (theme: theme, prop_name: prop)
        } else {
            return nil
        }
    }
}

// MARK: - NSMenuDelegate
extension ThemeEditorView: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let prop_name = self.propertyNameFromRow(tableView.clickedRow) else {
            menu.items.forEach { (item) in
                item.isEnabled = false
                item.isHidden = true
            }
            return
        }
        
        let is_keyword = prop_name.isKeyword
        menu.items.forEach { (item) in
            item.representedObject = prop_name
            item.isEnabled = item.tag == -4 || !(self.theme?.isStandalone ?? true)
            if item.tag == -4 {
                item.title = (self.theme?.isStandalone ?? true) ? "Show CSS…" : "Customize CSS…"
            }
            
            if item.tag > 0 {
                if item.tag == 1 && is_keyword {
                    item.isHidden = true
                } else {
                    item.isHidden = item.tag > 1 && !is_keyword
                }
            } 
            
            let prop: SCSHTheme.PropertyBase? = self.theme?[prop_name]
            if prop_name == SCSHTheme.PropertyName.canvas {
                if item.tag < 0 {
                    item.isHidden = true
                }
            } else if let prop = prop as? SCSHTheme.Property {
                if item.tag < 0 {
                    item.isHidden = false
                }
                if item.tag == -1 {
                    item.state = prop.isBold ? .on : .off
                } else if item.tag == -2 {
                    item.state = prop.isItalic ? .on : .off
                } else if item.tag == -3 {
                    item.state = prop.isUnderline ? .on : .off
                }
            }
        }
    }
}

// MARK: -
class ThemeCellView: NSTableCellView {
    @IBOutlet weak var backgroundView: NSView?
    
    @IBOutlet weak var addKeyButton: NSButton!
    @IBOutlet weak var delKeyButton: NSButton!
    
    var addKeywordAction: ((_ index: Int)->Void)?
    var delKeywordAction: ((_ index: Int)->Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.objectValue = nil
        self.addKeywordAction = nil
        self.delKeywordAction = nil
    }
    
    override var tag: Int {
        if let value = objectValue as? (theme: SCSHTheme, prop_name: SCSHTheme.PropertyName), let index = value.prop_name.keywordIndex {
            return index
        } else {
            return -1
        }
    }
    
    override var objectValue: Any? {
        didSet {
            if let value = objectValue as? (theme: SCSHTheme, prop_name: SCSHTheme.PropertyName), let prop = value.theme[value.prop_name] {
                let style = prop.getCustomStyle(for: "html")
                if style == nil || !style!.override {
                    let background = NSColor(fromHexString: value.theme.backgroundColor) ?? .clear
                    backgroundView?.layer?.backgroundColor = background.cgColor
                    
                    if value.prop_name == .canvas || value.prop_name == .lspHover {
                        textField?.textColor = NSColor(fromHexString: value.theme.foregroundColor) ?? .labelColor
                    } else {
                        textField?.textColor = NSColor(fromHexString: prop.color) ?? .labelColor
                    }
                    if let pp = prop as? SCSHTheme.Property {
                        textField?.attributedStringValue = pp.getAttributedString(name: value.prop_name, withFont: textField?.font ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular))
                    } else {
                        textField?.stringValue = value.prop_name.name
                    }
                } else {
                    backgroundView?.layer?.backgroundColor = NSColor.clear.cgColor
                    
                    textField?.textColor = .labelColor
                    textField?.stringValue = value.prop_name.name
                }
                
                addKeyButton.isHidden = !(!value.theme.isStandalone && value.prop_name.isKeyword)
                delKeyButton.isHidden = !(!value.theme.isStandalone && value.prop_name.isKeyword)
            } else {
                backgroundView?.layer?.backgroundColor = .clear
                textField?.stringValue = ""
                
                addKeyButton.isHidden = true
                delKeyButton.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView?.wantsLayer = true
        backgroundView?.layer?.cornerRadius = 4
    }
    
    @IBAction internal func handleAddKeyword(_ sender: Any) {
        addKeywordAction?(self.tag)
    }
    
    @IBAction internal func handleDelKeyword(_ sender: Any) {
        delKeywordAction?(self.tag)
    }
}

// MARK: -
extension ThemeEditorView: SCSHThemeDelegate {
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme) {
        if theme.isDirty {
            SCSHWrapper.shared.settings?.isDirty = true
        }
    }
}
