//
//  PlainSettingsEditorViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 18/09/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class PlainSettingsEditorViewController: NSViewController {
    @IBOutlet weak var patternTextField: NSTextField!
    @IBOutlet weak var regExpButton: NSButton!
    @IBOutlet weak var caseSensitiveButton: NSButton!
    @IBOutlet weak var syntaxPopupButton: NSPopUpButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var doneButton: NSButton!
    
    var selectedRow: Int = -1
    
    /// All supported UTIs.
    var allFileTypes: [UTI] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var availableSyntax: [String: HighlightWrapper.Language] = [:] {
        didSet {
            AppDelegate.initSyntaxPopup(syntaxPopupButton, availableSyntax: availableSyntax, extraItems: ["Auto detect from mime type", "Plain text"])
        }
    }
    
    var plainSettings: PlainSettings? {
        didSet {
            initSettings()
        }
    }
    
    var handler: ((PlainSettings)->Void)?
    
    override func viewDidLoad() {
        AppDelegate.initSyntaxPopup(syntaxPopupButton, availableSyntax: availableSyntax, extraItems: ["Auto detect from mime type", "Plain text"])
        allFileTypes = ((NSApplication.shared.delegate as? AppDelegate)?.handledUTIs ?? []).filter({ uti in
            guard uti.isDynamic, let settings = SCSHWrapper.shared.settings else {
                return true
            }
            if let _ = settings.searchStandaloneUTI(for: uti) {
                return false
            } else {
                return true
            }
        })
        
        initSettings()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if tableView.selectedRow >= 0 {
            tableView.scrollRowToVisible(tableView.selectedRow)
        }
    }
    
    func initSettings() {
        patternTextField?.stringValue = plainSettings?.pattern ?? ""
        regExpButton?.state = plainSettings?.isRegExp ?? false ? .on : .off
        caseSensitiveButton?.state = plainSettings?.isCaseSensitive ?? false ? .on : .off
        availableSyntax = HighlightWrapper.shared.languages
        
        let keys = Array(availableSyntax.keys.sorted(by: {$0.compare($1, options: .caseInsensitive) == .orderedAscending }))
        
        let stx = plainSettings?.syntax ?? "auto"
        if stx.isEmpty || stx == "txt" {
            syntaxPopupButton?.selectItem(at: 1)
        } else if stx == "auto" {
            syntaxPopupButton?.selectItem(at: 0)
        } else {
            if let i = keys.firstIndex(where: { availableSyntax[$0]?.extensions.contains(stx) ?? false }) {
                syntaxPopupButton?.selectItem(at: i + 3)
            } else {
                syntaxPopupButton?.selectItem(at: 0)
            }
        }
        let uti = plainSettings?.UTI ?? "auto"
        let index: Int
        if uti == "auto" {
            index = 0
        } else if uti.isEmpty {
            index = 1
        } else if let i = allFileTypes.firstIndex(where: { $0.UTI == uti }) {
            index = i + 2
        } else {
            index = 0
        }
        tableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView?.scrollRowToVisible(index)
        
        doneButton?.isEnabled = !(plainSettings?.pattern ?? "").isEmpty
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func handleDone(_ sender: Any) {
        var stx = "auto"
        if syntaxPopupButton.indexOfSelectedItem == 1 {
            stx = "" // txt
        } else if syntaxPopupButton.indexOfSelectedItem > 1 {
            let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
            let desc = String(keys[syntaxPopupButton.indexOfSelectedItem - 3])
            if let `extension` = availableSyntax[desc]?.extensions.first {
                stx = `extension`
            }
        }
        
        let uti: String
        if tableView.selectedRow == 0 {
            uti = "auto"
        } else if tableView.selectedRow == 1 {
            uti = ""
        } else {
            uti = allFileTypes[tableView.selectedRow - 2].UTI
        }
        
        handler?(PlainSettings(pattern: self.patternTextField.stringValue, isRegExp: regExpButton.state == .on, isCaseInsensitive: caseSensitiveButton.state == .off, UTI: uti, syntax: stx))
        
        self.dismiss(self)
    }
}

extension PlainSettingsEditorViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return allFileTypes.count + 2
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow >= 0 {
            if selectedRow >= 0 {
                tableView.reloadData(forRowIndexes: IndexSet(integer: selectedRow), columnIndexes: IndexSet(integer: 0))
            }
            tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.selectedRow), columnIndexes: IndexSet(integer: 0))
        }
        selectedRow = tableView.selectedRow
    }
}

extension PlainSettingsEditorViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "RadioColumn" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("RadioCell"), owner: nil) as! RadioCellView
            cell.radioButton.state = tableView.selectedRow == row ? .on : .off
            cell.tableView = tableView
            cell.radioButton.tag = row
            return cell
        } else if tableColumn?.identifier.rawValue == "ImageColumn" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("ImageCell"), owner: nil) as! NSTableCellView
            cell.imageView?.image = row <= 1 ? nil : allFileTypes[row - 2].image
            
            return cell
        } else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("UTICell"), owner: nil) as! UTICellView
            if row == 0 {
                cell.imageView?.image = nil
                cell.textField?.stringValue = "Auto detect from mime type"
                cell.UTILabel?.isHidden = true
                cell.textField?.textColor = .labelColor
            } else if row == 1 {
                cell.imageView?.image = nil
                cell.textField?.stringValue = "General settings"
                cell.UTILabel?.isHidden = true
                cell.textField?.textColor = .labelColor
            } else {
                cell.fillWithUTI(allFileTypes[row - 2], showUTI: false)
                cell.UTILabel?.isHidden = false
            }
            
            return cell
        }
    }
}


extension PlainSettingsEditorViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textFiled = obj.object as? NSTextField, textFiled == patternTextField else {
            return
        }
        doneButton.isEnabled = !textFiled.stringValue.isEmpty
    }
}

// MARK: -

class RadioCellView: NSTableCellView {
    @IBOutlet weak var radioButton: NSButton!
    
    weak var tableView: NSTableView?
    
    @IBAction func handleRadioButton(_ sender: NSButton) {
        tableView?.selectRowIndexes(IndexSet(integer: sender.tag), byExtendingSelection: false)
    }
}
