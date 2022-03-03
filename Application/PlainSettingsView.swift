//
//  PlainSettingsViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 17/09/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class PlainSettingsView: NSView, SettingsSplitViewElement {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var delButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    @IBOutlet weak var binaryPopupButton: NSPopUpButton!
    @IBOutlet weak var binaryLabel: NSTextField!
    
    var settings: Settings? {
        return SCSHWrapper.shared.settings
    }
    
    var plainSettings: [PlainSettings] {
        return SCSHWrapper.shared.settings?.getPlainSettings() ?? []
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
        
        delButton.isEnabled = false
        editButton.isEnabled = false
        upButton.isEnabled = false
        downButton.isEnabled = false
        
        self.tableView.doubleAction = #selector(self.handleDoublClickTable(_:))
        initSettings()
        self.tableView.reloadData()
        
        if #available(macOS 12.0, *) {
            binaryLabel.stringValue = "Images, audios, movies and PDF files are always displayed."
        } else {
            binaryLabel.stringValue = "Images are always displayed."
        }
    }
    
    deinit {
    }
    
    @discardableResult
    func initSettings() -> Bool {
        self.binaryPopupButton.selectItem(at: settings?.isDumpPlainData ?? true ? 1 : 0)
        self.tableView?.reloadData()
        return true
    }
    
    func updateControls() {
        self.delButton.isEnabled = self.tableView.selectedRow >= 0
        self.editButton.isEnabled = self.tableView.selectedRow >= 0
        self.upButton.isEnabled = self.tableView.selectedRow > 0
        self.downButton.isEnabled = self.tableView.selectedRow >= 0 && self.tableView.selectedRow < self.tableView.numberOfRows - 1
    }
    
    @IBAction func handleDoublClickTable(_ sender: Any) {
        guard let settings = SCSHWrapper.shared.settings else {
            return
        }
        guard tableView.selectedRow >= 0 else {
            return
        }
        guard let vc = NSStoryboard(name: "Storyboard", bundle: nil).instantiateController(withIdentifier: "PlainStyleEditor") as? PlainSettingsEditorViewController else {
            return
        }
        let index = tableView.selectedRow
        vc.plainSettings = plainSettings[index]
        vc.handler = { [weak self] (plain_settings) in
            guard plain_settings != settings.getPlainSettings()[index] else {
                return
            }
            settings.replacePlainSettings(plain_settings, at: index)
            self?.tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(0...2))
        }
        self.window?.contentViewController?.presentAsSheet(vc)
    }
    
    @IBAction func handleAddButton(_ sender: NSButton) {
        guard let settings = SCSHWrapper.shared.settings else {
            return
        }
        guard let vc = NSStoryboard(name: "Storyboard", bundle: nil).instantiateController(withIdentifier: "PlainStyleEditor") as? PlainSettingsEditorViewController else {
            return
        }
        let index = tableView.selectedRow
        vc.plainSettings = nil
        vc.handler = { [weak self] (plain_settings) in
            guard let me = self else { return }
            settings.insertPlainSettings(settings: plain_settings, at: index + 1)
            me.tableView.insertRows(at: IndexSet(integer:index + 1), withAnimation: .slideDown)
            me.tableView.selectRowIndexes(IndexSet(integer: index + 1), byExtendingSelection: false)
            me.updateControls()
        }
        self.window?.contentViewController?.presentAsSheet(vc)
    }
    @IBAction func handleDelButton(_ sender: NSButton) {
        guard let settings = SCSHWrapper.shared.settings else {
            return
        }
        guard tableView.selectedRow >= 0 && tableView.selectedRow < settings.getPlainSettings().count else {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Are you sure to remove this item?"
        alert.addButton(withTitle: "Remove").keyEquivalent = "\r"
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        
        alert.alertStyle = .critical
        if alert.runModal() == .alertFirstButtonReturn {
            settings.removePlainSettings(at: tableView.selectedRow)
            self.tableView.removeRows(at: IndexSet(integer: self.tableView.selectedRow), withAnimation: .slideUp)
            self.tableView.deselectAll(self)
            updateControls()
        }
    }
    @IBAction func handleEditButton(_ sender: NSButton) {
        self.handleDoublClickTable(sender)
    }
    @IBAction func handleUpButton(_ sender: NSButton) {
        guard let settings = SCSHWrapper.shared.settings else {
            return
        }
        let index = tableView.selectedRow
        guard index >= 1 else {
            return
        }
        let p = settings.removePlainSettings(at: index)
        settings.insertPlainSettings(settings: p, at: index - 1)
        self.tableView.moveRow(at: index, to: index - 1)
        self.tableView.selectRowIndexes(IndexSet(integer: index - 1), byExtendingSelection: false)
        updateControls()
    }
    @IBAction func handleDownButton(_ sender: NSButton) {
        guard let settings = SCSHWrapper.shared.settings else {
            return
        }
        let index = tableView.selectedRow
        guard index <= self.tableView.numberOfRows - 2 else {
            return
        }
        let p = settings.removePlainSettings(at: index)
        settings.insertPlainSettings(settings: p, at:index+1)
        self.tableView.moveRow(at: index, to: index + 1)
        self.tableView.selectRowIndexes(IndexSet(integer: index + 1), byExtendingSelection: false)
        updateControls()
    }
    
    @IBAction func handleBinaryButton(_ sender: NSPopUpButton) {
        settings?.isDumpPlainData = sender.indexOfSelectedItem == 1
    }
}

extension PlainSettingsView: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateControls()
    }
    
    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        var w: CGFloat = 0
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        outerLoop: for setting in plainSettings {
            let s: String
            switch column {
            case 0:
                s = setting.patternFile
            case 1:
                s = setting.patternMime
            case 2:
                s = setting.UTI.isEmpty ? "General" : setting.UTI
            case 3:
                s = setting.syntax.isEmpty ? "Plain text" : setting.syntax
            default:
                break outerLoop
            }
            var size = (s as NSString).size(withAttributes: [.font: font]).width + 8
            if column == 0 {
                if setting.isRegExp {
                    size += 24
                }
                if setting.isCaseSensitive {
                    size += 24
                }
            }
            w = max(w, size)
        }
        return w
    }
}

extension PlainSettingsView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.plainSettings.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn?.identifier.rawValue == "pattern" {
            return self.plainSettings[row].patternFile
        } else if tableColumn?.identifier.rawValue == "mime" {
            return self.plainSettings[row].patternMime
        } else if tableColumn?.identifier.rawValue == "uti" {
            return self.plainSettings[row].UTI.isEmpty ? "General" : self.plainSettings[row].UTI
        } else if tableColumn?.identifier.rawValue == "syntax" {
            return self.plainSettings[row].syntax.isEmpty ? "Plain text" : self.plainSettings[row].syntax
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "pattern" {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PatternCell"), owner: nil) as! PatternTableCellView
            cellView.textField?.stringValue = self.plainSettings[row].patternFile
            cellView.caseSensitiveImageView.isHidden = !self.plainSettings[row].isCaseSensitive
            cellView.regExpImageView.isHidden = !self.plainSettings[row].isRegExp
            return cellView
        } else if tableColumn?.identifier.rawValue == "mime" {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PatternCell"), owner: nil) as! PatternTableCellView
            cellView.textField?.stringValue = self.plainSettings[row].patternMime
            cellView.caseSensitiveImageView.isHidden = !self.plainSettings[row].isCaseSensitive
            cellView.regExpImageView.isHidden = !self.plainSettings[row].isRegExp
            return cellView
        } else {
            let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: nil) as! NSTableCellView
            
            cellView.textField?.stringValue = self.tableView(tableView, objectValueFor: tableColumn, row: row) as? String ?? ""
            
            return cellView
        }
    }
}

class PatternTableCellView: NSTableCellView {
    @IBOutlet weak var caseSensitiveImageView: NSImageView!
    @IBOutlet weak var regExpImageView: NSImageView!
}
