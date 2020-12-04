//
//  CustomTypeViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 15/11/2019.
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
import Syntax_Highlight_XPC_Service

enum UTISupported {
    case unknown
    case no
    case yes
    case highlight
}

class UTIStatus {
    let UTI: UTI
    var supported: UTISupported = .unknown
    let standard: Bool
    init(UTI: UTI, standard: Bool) {
        self.UTI = UTI
        self.standard = standard
    }
}

class DropView: NSView {
    weak var dropDelegate: DropViewDelegate?
    
    var acceptableTypes: [NSPasteboard.PasteboardType] { return [.fileURL] }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        registerForDraggedTypes(acceptableTypes)
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
        self.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.layer?.borderWidth = 4
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.layer?.borderColor = NSColor.selectedControlColor.cgColor
        self.dropDelegate?.enterDrag(sender)
        return .every
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.borderColor = NSColor.gridColor.cgColor
        self.dropDelegate?.exitDrag(sender)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.dropDelegate?.endDrag(sender)
        self.layer?.borderColor = NSColor.gridColor.cgColor
    }
}

class ActionTableCellView: NSTableCellView {
    @IBOutlet weak var popupButton: NSPopUpButton!
}

protocol DropViewDelegate: class {
    func enterDrag(_ sender: NSDraggingInfo)
    func exitDrag(_ sender: NSDraggingInfo?)
    func endDrag(_ sender: NSDraggingInfo)
}

class CustomTypeViewController: NSViewController, DropViewDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var dropView: DropView!
    @IBOutlet weak var labelView: NSTextField!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var handledLegend: NSStackView!
    @IBOutlet weak var notHandledLegend: NSStackView!
    @IBOutlet weak var supportedLegend: NSStackView!
    
    private var firstDrop = true
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    var handledUTIs: [UTIDesc] = []
    
    var UTIs: [UTIStatus] = [] {
        didSet {
            self.handledLegend.isHidden = true
            self.notHandledLegend.isHidden = true
            self.supportedLegend.isHidden = true
            if (self.UTIs.count > 0) {
                for (i, uti) in self.UTIs.enumerated() {
                    if let _ = handledUTIs.first(where: { $0.uti == uti.UTI }) {
                        uti.supported = .yes
                        self.handledLegend.isHidden = false
                    } else {
                        service?.areSomeSyntaxSupported(uti.UTI.extensions, overrideSettings: nil, reply: { (state) in
                            self.notHandledLegend.isHidden = state
                            self.supportedLegend.isHidden = !state
                            uti.supported = state ? .highlight : .no
                            let c = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("status"))
                            self.tableView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: c))
                        })
                    }
                }
            }
            
            self.tableView.reloadData()
        }
    }
        
    override func viewDidLoad() {
        self.dropView.dropDelegate = self
        
        handledUTIs = (NSApplication.shared.delegate as? AppDelegate)?.fetchHandledUTIs() ?? []
        
        self.handledLegend.isHidden = true
        self.notHandledLegend.isHidden = true
        self.supportedLegend.isHidden = true
    }
    
    func enterDrag(_ sender: NSDraggingInfo) {
        self.scrollView.isHidden = true
    }
    func exitDrag(_ sender: NSDraggingInfo?) {
        self.scrollView.isHidden = firstDrop
    }
    func endDrag(_ sender: NSDraggingInfo) {
        if let fileUrl = sender.draggingPasteboard.pasteboardItems?.first?.propertyList(forType: .fileURL) as? String, let url = URL(string: fileUrl) {
            
            var UTIs: [UTIStatus] = []
            
            do {
                let v = try url.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey])
                if let uti = v.typeIdentifier {
                    UTIs.append(UTIStatus(UTI: UTI(uti), standard: true))
                }
            } catch {
            }
            
            let ext = url.pathExtension
            if !ext.isEmpty {
                let tags = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, ext as CFString, nil)
                if let t = tags?.takeRetainedValue() as? [String] {
                    for u in t {
                        if UTIs.first(where: { $0.UTI.UTI == u }) == nil {
                            UTIs.append(UTIStatus(UTI: UTI(u), standard: false))
                        }
                    }
                }
            }
            self.UTIs = UTIs
            self.scrollView.isHidden = false
            firstDrop = false
        } else {
            self.UTIs = []
            self.scrollView.isHidden = true
        }
    }
    
    @IBAction func addSupportForUTI(_ sender: NSPopUpButton) {
        guard UTIs[sender.tag].supported != .yes  else {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Sorry but this action is not supported because strip the code signature and make the extension unusable!"
        alert.addButton(withTitle: "OK")
        
        alert.alertStyle = .warning
        
        alert.runModal()
        /*
        
        
        let uti = UTIs[sender.tag]
        
        let alert = NSAlert()
        alert.window.title = "Warning"
        alert.messageText = "Adding a custom format WILL REMOVE the code signature and may make it IMPOSSIBLE TO RUN THE APPLICATION. This operation cannot be undone. Please take a backup of the app."
        alert.informativeText = "Do you want to continue?"
        var b = alert.addButton(withTitle: "Continue")
        b.keyEquivalent = ""
        b = alert.addButton(withTitle: "Cancel")
        b.keyEquivalent = "\u{1b}" // ESC
        
        alert.alertStyle = .critical    
        
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        
        service?.registerUTI(uti.UTI.UTI, result: { result in
            print("registration: \(result ? "OK" : "KO")")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = result ? "Custom UTI registered" : "Warning"
                alert.informativeText = result ? "Restart the app to see the customized UTI.\nIf the app don't start you must reset the code signature with this terminal command: /usr/bin/codesign --remove-signature PATH_OF_THE_APP" : "Unable to add the requested UTI format."
                alert.addButton(withTitle: "OK")
                alert.alertStyle = result ? .informational : .warning
                alert.runModal()
            }
        })
        /*
        let task = Process()
        
        // helper tool path
        task.launchPath = Bundle.main.path(forResource: "relaunch", ofType: nil)!
        // self PID as a argument
        task.arguments = [String(ProcessInfo.processInfo.processIdentifier)]
        task.launch()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.terminate(self)
        }
 */
 */
    }
    
    /*
    @IBAction func doSave(_ sender: Any) {
        if isUTIValid, let url = (NSApplication.shared.delegate as? AppDelegate)?.getQLAppexUrl(), let bundle = Bundle(url: url) {
            
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.informativeText = "Modify the supported format break code signature!\nDo you want to continue?"
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .critical
            
            guard alert.runModal() == .alertFirstButtonReturn else {
                return
            }
            
            let u = bundle.bundleURL.appendingPathComponent("Contents/info.plist")
            if let d = NSMutableDictionary(contentsOf: u) {
                if let NSExtension = d["NSExtension"] as? NSMutableDictionary, let NSExtensionAttributes = NSExtension["NSExtensionAttributes"] as? NSMutableDictionary, let QLSupportedContentTypes = NSExtensionAttributes["QLSupportedContentTypes"] as? NSMutableArray, let UTI = self.UTI?.UTI {
                    QLSupportedContentTypes.add(UTI)
                    print(QLSupportedContentTypes)
                    
                    do {
                        try d.write(to: u)
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Unable to apply the changes!"
                        alert.informativeText = error.localizedDescription
                        alert.addButton(withTitle: "Close")
                        alert.alertStyle = .critical
                        alert.runModal()
                    }
                }
            }
            print(u)
        }
        dismiss(sender)
    }
     */
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.UTIs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let uti = self.UTIs[row]
        let font: NSFont
        if uti.standard {
            font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        } else {
            font = NSFont.labelFont(ofSize: NSFont.systemFontSize)
        }
        
        guard let tableColumn = tableColumn else {
            return NSTableCellView()
        }
        let view = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        
        if tableColumn.identifier == NSUserInterfaceItemIdentifier("description") {
            view.textField?.attributedStringValue = NSAttributedString(string: uti.UTI.description, attributes: [NSAttributedString.Key.font: font])
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("UTI") {
            view.textField?.attributedStringValue = NSAttributedString(string: uti.UTI.UTI, attributes: [NSAttributedString.Key.font: font])
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("status") {
            switch (uti.supported) {
            case .yes:
                view.imageView?.image = NSImage(named: NSImage.statusAvailableName)
            case .no:
                view.imageView?.image = NSImage(named: NSImage.statusUnavailableName)
            case .highlight:
                view.imageView?.image = NSImage(named: NSImage.statusPartiallyAvailableName)
            case .unknown:
                view.imageView?.image = NSImage(named: NSImage.statusNoneName)
            }
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("ext") {
            view.textField?.stringValue = uti.UTI.extensions.joined(separator: ", ")
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("action")/*, let cell = view as? ActionTableCellView */ {
            return nil
            
            /*cell.popupButton.tag = row
            cell.popupButton.isEnabled = UTIs[row].supported != .yes*/
        }
        
        return view
    }
}
