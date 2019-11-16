//
//  CustomTypeViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 15/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import Syntax_Highlight_XPC_Service

class DropView: NSTextField {
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
        self.layer?.borderColor = NSColor.gridColor.cgColor
        self.layer?.borderWidth = 4
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.layer?.borderColor = NSColor.selectedControlColor.cgColor
        return .every
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.borderColor = NSColor.gridColor.cgColor
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        if let fileUrl = sender.draggingPasteboard.pasteboardItems?.first?.propertyList(forType: .fileURL) as? String, let url = URL(string: fileUrl) {
            
            do {
                let v = try url.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey])
                if let uti = v.typeIdentifier {
                    let s = NSMutableAttributedString()
                    
                    let u = UTI(uti)
                    dropDelegate?.setUTI(u)
                    
                    var label: String = u.description
                    if u.extensions.count > 0 {
                        label += (label.isEmpty ? "" : " ") + "[.\(u.extensions.joined(separator: ", ."))]"
                    }
                    
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
        
                    if !label.isEmpty {
                        s.append(NSAttributedString(string: label + "\n", attributes: [NSAttributedString.Key.paragraphStyle: style]))
                    }
                    s.append(NSAttributedString(string: uti, attributes: [NSAttributedString.Key.font : NSFont.systemFont(ofSize: NSFont.systemFontSize(for: NSControl.ControlSize.small)), NSAttributedString.Key.paragraphStyle: style]))
                    
                    self.attributedStringValue = s
                }
            } catch {
                dropDelegate?.setUTI(nil)
            }
        } else {
            dropDelegate?.setUTI(nil)
        }
        self.layer?.borderColor = NSColor.gridColor.cgColor
    }
}

protocol DropViewDelegate: class {
    func setUTI(_ type: UTI?)
}

class CustomTypeViewController: NSViewController, DropViewDelegate {
    @IBOutlet weak var dropView: DropView!
    @IBOutlet weak var warningLabel: NSTextField!
    @IBOutlet weak var warningImage: NSImageView!
    @IBOutlet weak var saveButton: NSButton?
    
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    var handledUTIs: [UTIDesc] = []
    
    var UTI: UTI? {
        didSet {
            warningLabel.isHidden = true
            warningImage.isHidden = true
            saveButton?.isEnabled = false
            isUTIValid = false
            
            if let uti = self.UTI {
                if let _ = handledUTIs.first(where: { $0.uti == uti }) {
                    self.warningLabel.stringValue = "Format recognized by the extension."
                    self.warningImage.image = NSImage(named: NSImage.statusAvailableName)
                    
                    self.warningLabel.isHidden = false
                    self.warningImage.isHidden = false
                    self.saveButton?.isEnabled = false
                    
                    return
                } else {
                    service?.areSomeSyntaxSupported(uti.extensions, overrideSettings: nil, reply: { (state) in
                        self.warningLabel.stringValue = state ? "Format handled by highlight but not by the extension" : "Format not supported by highlight."
                        self.warningImage.image = NSImage(named: state ? NSImage.statusPartiallyAvailableName : NSImage.statusUnavailableName)
                        self.warningLabel.isHidden = state
                        self.warningImage.isHidden = state
                        self.saveButton?.isEnabled = true
                        
                        self.isUTIValid = state
                    })
                }
                
            }
        }
    }
    
    fileprivate(set) var isUTIValid: Bool = false
    
    override func viewDidLoad() {
        self.dropView.dropDelegate = self
        
        self.warningLabel.isHidden = true
        self.warningImage.isHidden = true
        self.saveButton?.isEnabled = false
        
        handledUTIs = (NSApplication.shared.delegate as? AppDelegate)?.fetchHandledUTIs() ?? []
    }
    
    func setUTI(_ type: UTI?) {
        self.UTI = type
    }
    
    @IBAction func doSave(_ sender: Any) {
        if isUTIValid, let url = (NSApplication.shared.delegate as? AppDelegate)?.getQLAppexUrl(), let bundle = Bundle(url: url) {
            
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.informativeText = "Modifiy the supported format break code signature!\nDo you want to continue?"
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
}
