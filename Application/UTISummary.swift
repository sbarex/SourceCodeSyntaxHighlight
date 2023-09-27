//
//  UTISummary.swift
//  Syntax Highlight
//
//  Created by Sbarex on 03/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation
import AppKit

class UTISummary: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    
    var allFileTypes: [UTI] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.allFileTypes = (NSApplication.shared.delegate as? AppDelegate)?.handledUTIs.sorted(by: { $0.description < $1.description }) ?? []
    }
}

extension UTISummary: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return allFileTypes.count
    }
    
    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        let tableColumn = tableView.tableColumns[column]
        let text: [String]
        switch tableColumn.identifier.rawValue {
        case "uti":
            text = allFileTypes.map { return $0.UTI }
        case "mime":
            text = allFileTypes.map { return $0.mimeTypes.joined(separator: ", ") }
        case "ext":
            text = allFileTypes.map { return $0.extensions.joined(separator: ", ") }
        case "desc":
            text = allFileTypes.map { return $0.description }
        default:
            return 100
        }
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: nil) as? NSTableCellView
        let font = cell?.textField?.font ?? NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        
        var greatest: CGFloat = 0
        for s in text {
            let w = (s as NSString).size(withAttributes: [.font: font])
            greatest = max(greatest, w.width)
        }
        return greatest + 20
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sort = tableView.sortDescriptors.first else {
            return
        }
        switch sort.key {
        case "desc":
            allFileTypes = allFileTypes.sorted(by: { sort.ascending ?  $0.description < $1.description : $0.description > $1.description})
        case "uti":
            allFileTypes = allFileTypes.sorted(by: { sort.ascending ? $0.UTI < $1.UTI : $0.UTI > $1.UTI})
        case "ext":
            allFileTypes = allFileTypes.sorted(by: { sort.ascending ? $0.extensions.first ?? "" < $1.extensions.first ?? "" : $0.extensions.first ?? "" > $1.extensions.first ?? ""})
        case "mime":
            allFileTypes = allFileTypes.sorted(by: { sort.ascending ? $0.mimeTypes.first ?? "" < $1.mimeTypes.first ?? "" : $0.mimeTypes.first ?? "" > $1.mimeTypes.first ?? ""})
        default:
            break
        }
    }
}

extension UTISummary: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: nil) as! NSTableCellView
        switch tableColumn?.identifier.rawValue ?? "" {
        case "uti":
            cell.textField?.stringValue = allFileTypes[row].UTI
        case "mime":
            cell.textField?.stringValue = allFileTypes[row].mimeTypes.joined(separator: ", ")
        case "ext":
            cell.textField?.stringValue = allFileTypes[row].extensions.joined(separator: ", ")
        case "desc":
            cell.textField?.stringValue = allFileTypes[row].description
        default:
            break
        }
        return cell
    }
}
