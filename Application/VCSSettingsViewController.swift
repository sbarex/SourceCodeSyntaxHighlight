//
//  VCSSettingsViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 10/10/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation
import AppKit

class VCSSettingsViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    
    var gitPath: String = ""
    var hgPath: String = ""
    // var svnPath: String = ""
    
    var customizeColor = true
    var editLightColor = "#"
    var editDarkColor = "#"
    var addLightColor = "#"
    var addDarkColor = "#"
    var delLightColor = "#"
    var delDarkColor = "#"
    
    var settings: SettingsBase? {
        didSet {
            initSettings()
        }
    }
    
    var onDismiss: (()->Void)?
    
    @discardableResult
    func initSettings() -> Bool {
        tableView?.beginUpdates()
        guard let settings = self.settings else {
            tableView?.endUpdates()
            return false
        }
        
        addLightColor = settings.vcsAddLightColor
        addDarkColor = settings.vcsAddDarkColor
        editLightColor = settings.vcsEditLightColor
        editDarkColor = settings.vcsEditDarkColor
        delLightColor = settings.vcsDelLightColor
        delDarkColor = settings.vcsDelDarkColor
        customizeColor = settings.isVCSDefined
        
        if let settings = settings as? Settings {
            gitPath = settings.gitPath
            hgPath = settings.hgPath
            // svnPath = settings.svnPath
            customizeColor = true
        }
        
        tableView?.reloadData()
        tableView?.endUpdates()
        return true
    }
    
    @IBAction func handleSave(_ sender: Any) {
        if customizeColor {
            settings?.isVCSDefined = true
            settings?.vcsAddLightColor = addLightColor
            settings?.vcsAddDarkColor = addDarkColor
            settings?.vcsEditLightColor = editLightColor
            settings?.vcsEditDarkColor = editDarkColor
            settings?.vcsDelLightColor = delLightColor
            settings?.vcsDelDarkColor = delDarkColor
        } else {
            settings?.isVCSDefined = false
        }
        if let settings = settings as? Settings {
            settings.gitPath = gitPath
            settings.hgPath = hgPath
            // settings.svnPath = svnPath
            settings.isVCSDefined = true
        }
        
        self.dismiss(sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSettings()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        onDismiss?()
    }
}

// MARK: -

extension VCSSettingsViewController: BrowseCellDelegate {
    func browseCell(_ cell: BrowseCell, didChangeValue url: URL?) {
        if cell.textField?.tag == 0 {
            self.gitPath = url?.path ?? ""
        } else if cell.textField?.tag == 1 {
            self.hgPath = url?.path ?? ""
        } /*else if cell.textField?.tag == 2 {
            self.svnPath = url?.path ?? ""
        }*/
    }
}

extension VCSSettingsViewController: VCSColorCellDelegate {
    func colorCellDidChange(_ cell: VCSColorCell) {
        if cell.tag == 0 {
            self.addLightColor = cell.lightColor.color.toHexString() ?? "#C9DEC1"
            self.addDarkColor = cell.darkColor.color.toHexString() ?? "#009924"
        } else if cell.tag == 1 {
            self.editLightColor = cell.lightColor.color.toHexString() ?? "#C3D6E8"
            self.editDarkColor = cell.darkColor.color.toHexString() ?? "#1AABFF"
        } else if cell.tag == 2 {
            self.delLightColor = cell.lightColor.color.toHexString() ?? "#ff0000"
            self.delDarkColor = cell.darkColor.color.toHexString() ?? "#ff0000"
        }
    }
}

class MyNSTableRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get {
            return false
        }
        set {
            
        }
    }
}
// MARK: - NSTableViewDelegate
extension VCSSettingsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return MyNSTableRowView()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let settings = self.settings else {
            return nil
        }
        var r = row
        
        if tableColumn?.identifier.rawValue != "value" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: row <= 1 ? "LabelCell" : "LabelCell2"), owner: nil) as! NSTableCellView
            if settings is Settings {
                if r < 2 {
                    if r == 0 {
                        cell.textField?.stringValue = "git path"
                    } else if r == 1 {
                        cell.textField?.stringValue = "hg path"
                    } /*else if r == 2 {
                        cell.textField?.stringValue = "svn path"
                    }*/
                    return cell
                }
                r -= 2
            }
            if r == 0 {
                cell.textField?.stringValue = "new lines"
            } else if r == 1 {
                cell.textField?.stringValue = "changed lines"
            } else if r == 2 {
                cell.textField?.stringValue = "removed lines"
            }
            return cell
        } else {
            if settings is Settings {
                if r < 2 {
                    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PathCell"), owner: nil) as! BrowseCell
                    cell.textField?.isEditable = true
                    cell.textField?.isEnabled = true
                    cell.browseButton.isEnabled = true
                    cell.delegate = self
                    cell.textField?.tag = r
                    if r == 0 {
                        cell.url = gitPath.isEmpty ? nil : URL(fileURLWithPath: gitPath)
                        // cell.textField?.toolTip = ""
                    } else if r == 1 {
                        cell.url = hgPath.isEmpty ? nil : URL(fileURLWithPath: hgPath)
                    } /*else if r == 2 {
                        cell.url = svnPath.isEmpty ? nil : URL(fileURLWithPath: svnPath)
                    }*/
                    return cell
                }
                r -= 2
            }
            
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColorCell"), owner: nil) as! VCSColorCell
            cell.delegate = self
            cell.tag = r
            cell.lightColor.isEnabled = customizeColor
            cell.darkColor.isEnabled = customizeColor
            if r == 0 {
                cell.lightColor.color = NSColor(fromHexString: self.addLightColor) ?? .systemGreen
                cell.darkColor.color = NSColor(fromHexString: self.addDarkColor) ?? .systemGreen
            } else if r == 1 {
                cell.lightColor.color = NSColor(fromHexString: self.editLightColor) ?? .systemBlue
                cell.darkColor.color = NSColor(fromHexString: self.editDarkColor) ?? .systemBlue
            } else if r == 2 {
                cell.lightColor.color = NSColor(fromHexString: self.delLightColor) ?? .systemRed
                cell.darkColor.color = NSColor(fromHexString: self.delDarkColor) ?? .systemRed
            }
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row <= 1 {
            return tableView.rowHeight
        } else {
            return 40
        }
    }
}

// MARK: - NSTableViewDataSource
extension VCSSettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let settings = self.settings else {
            return 0
        }
        return settings is Settings ? 5 : 3
    }
}

// MARK: -

@objc
protocol VCSColorCellDelegate: AnyObject {
    @objc
    optional func colorCellDidChange(_ cell: VCSColorCell)
}

class VCSColorCell: NSTableCellView {
    private var _tag: Int = 0
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    @IBOutlet weak var lightColor: NSColorWell!
    @IBOutlet weak var darkColor: NSColorWell!
    
    @IBAction func handleColor(_ sender: NSColorWell) {
        delegate?.colorCellDidChange?(self)
    }
    
    weak var delegate: VCSColorCellDelegate?
}
