//
//  WarningUTIViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 11/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
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

class WarningUTIViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var warningLabelView: NSTextField!
    @IBOutlet weak var warningImageView: NSImageView!
    
    var data: [(suppress: UTI.SuppressedExtension, handled: Bool)] = [] {
        didSet {
            tableView?.reloadData()
            let unhandled = data.firstIndex(where: { !$0.handled }) != nil
            warningLabelView?.isHidden = !unhandled
            warningImageView?.isHidden = !unhandled
        }
    }
    
    override func viewDidLoad() {
        self.tableView.doubleAction = #selector(self.handleDoubleClick(_:))
        
        let unhandled = data.firstIndex(where: { !$0.handled }) != nil
        warningLabelView?.isHidden = !unhandled
        warningImageView?.isHidden = !unhandled
    }
    
    @objc func handleDoubleClick(_ sender: Any) {
        guard sender as? NSTableView == tableView, tableView.selectedRow >= 0, data[tableView.selectedRow].handled else {
            return
        }
        
        if let vc = self.presentingViewController as? SettingsSplitElement {
            vc.settingsController?.selectUTI(UTI(data[tableView.selectedRow].suppress.uti))
        }
        self.dismiss(self)
    }
}

extension WarningUTIViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn?.identifier.rawValue == "Ext" {
            return data[row].suppress.ext
        } else if tableColumn?.identifier.rawValue == "UTI" {
            return data[row].suppress.uti
        } else if tableColumn?.identifier.rawValue == "Desc" {
            let u = UTI(data[row].suppress.uti)
            let s = u.description
            if !data[row].handled, let image = NSImage(named: NSImage.statusPartiallyAvailableName) {
                let imageAttachment = NSTextAttachment()
                let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
                imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height).rounded() / 2, width: image.size.width, height: image.size.height)
                imageAttachment.image = image
                let imageString = NSAttributedString(attachment: imageAttachment)
                
                let fullString = NSMutableAttributedString()
                fullString.append(imageString)
                fullString.append(NSAttributedString(string: " \(s)"))
                
                return fullString
            } else {
                return s
            }
        }
        return nil
    }
}

extension WarningUTIViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, toolTipFor cell: NSCell, rect: NSRectPointer, tableColumn: NSTableColumn?, row: Int, mouseLocation: NSPoint) -> String {
        if data[row].handled {
            return "Double click to go to this file type."
        }
        
        if tableColumn?.identifier.rawValue == "Desc" && !data[row].handled {
            return "This file type is not currently supported."
        } else {
            return ""
        }
    }
}
