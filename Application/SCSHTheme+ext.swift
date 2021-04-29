//
//  SCSHTheme+ext.swift
//  Syntax Highlight
//
//  Created by Sbarex on 13/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

extension SCSHTheme {
    var attributedDesc: NSAttributedString {
        let getImage: (()->NSImage?) = {
            let image: NSImage?
            if #available(OSX 11.0, *) {
                image = NSImage(systemSymbolName: "safari", accessibilityDescription: nil)
            } else {
                image = NSImage(named: "safari")
            }
            return image
        }
        
        let fullString = NSMutableAttributedString()
        
        if self.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)), let image = getImage() {
            let imageAttachment = NSTextAttachment()
            //let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            //imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height).rounded() / 2, width: image.size.width, height: image.size.height)
            imageAttachment.image = image
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            fullString.append(imageString)
            fullString.append(NSAttributedString(string: " \(self.desc)"))
        } else {
            fullString.append(NSAttributedString(string: self.desc))
        }
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        fullString.addAttributes([NSAttributedString.Key.paragraphStyle : style], range: NSRange(location: 0, length: fullString.length))
        return fullString
    }
    
    func browseToExport() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.allowedFileTypes = ["theme"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "\(self.name).theme"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let view = SaveAsFormatView(frame: NSRect(x: 0, y: 0, width: 200, height: 50))
        savePanel.accessoryView = view
        view.savePanel = savePanel
        
        let result = savePanel.runModal()
        
        guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let dst = savePanel.url else {
            return
        }
        
        do {
            if dst.pathExtension == "theme" {
                if self.exists {
                    if FileManager.default.fileExists(atPath: dst.path) {
                        try FileManager.default.removeItem(at: dst)
                    }
                    try FileManager.default.copyItem(atPath: path, toPath: dst.path)
                    let newAttributes = [FileAttributeKey.modificationDate: NSDate()]
                    try? FileManager.default.setAttributes(newAttributes, ofItemAtPath: dst.path)
                } else {
                    let lua = self.getLua()
                    try lua.write(to: dst, atomically: true, encoding: .utf8)
                }
            } else {
                let css = self.getCSSStyle()
                try css.write(to: dst, atomically: true, encoding: .utf8)
            }
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Unable to export the theme!"
            alert.addButton(withTitle: "Cancel")
            alert.runModal()
        }
    }
}
