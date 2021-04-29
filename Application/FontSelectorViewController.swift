//
//  FontSelectorViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 08/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class FontSelectorViewController: NSViewController {
    @IBOutlet weak var fontPopupMenu: NSPopUpButton!
    @IBOutlet weak var fontSizeField: NSTextField!
    
    typealias FontInfo = (name: String, title: String, font: NSFont)
    var fonts: [NSFont] = []
    
    var handler: ((String, CGFloat, Bool)->Void)?
    
    @objc dynamic var fontSize: CGFloat = 12 {
        didSet {
            handler?(fontName, self.fontSize, false)
        }
    }
    @objc dynamic var fontName: String = "-" {
        didSet {
            handler?(fontName, self.fontSize, false)
        }
    }
    
    override func viewDidLoad() {
        var fontNames: Set<String> = Set(NSFontManager.shared.availableFontNames(with: [.fixedPitchFontMask]) ?? [])
        fontNames.subtract(Set(NSFontManager.shared.availableFontNames(with: [.fixedPitchFontMask, .boldFontMask]) ?? [])) // Remove the bold variants
        fontNames.subtract(Set(NSFontManager.shared.availableFontNames(with: [.fixedPitchFontMask, .italicFontMask]) ?? [])) // Remove the italic variants
        
        var minimumCharacterSetMutable = CharacterSet()
        
        minimumCharacterSetMutable.formUnion(CharacterSet(charactersIn: "0"..."9"))
        minimumCharacterSetMutable.formUnion(CharacterSet(charactersIn: "a"..."z"))
        minimumCharacterSetMutable.formUnion(CharacterSet(charactersIn: "A"..."Z"))
        
        for name in fontNames {
            guard let font = NSFont(name: name, size: 0) else {
                continue
                
            }
            guard let displayName = font.displayName, !displayName.isEmpty else {
                continue
            }
            guard let firstChar = displayName.first, firstChar != "#" && firstChar != "." else {
                continue
            }
            guard font.coveredCharacterSet.isSuperset(of: minimumCharacterSetMutable) else {
                continue // Weed out some useless fonts, like Monotype Sorts
            }
            fonts.append(font)
        }
        
        let insertFontItem = { (_ font: NSFont) in
            // fontPopupMenu.addItem(withTitle: item.title)
            
            let menu = NSMenuItem(title: font.displayName ?? font.fontName, action: nil, keyEquivalent: "")
            let astr = NSAttributedString(string: font.displayName ?? font.fontName, attributes: [.font: font])
            menu.attributedTitle = astr
            menu.representedObject = font
            menu.toolTip = font.displayName ?? font.fontName
            self.fontPopupMenu.menu?.addItem(menu)
        }
        
        fonts.sorted(by: { $0.displayName!.lowercased() < $1.displayName!.lowercased()}).forEach { item in
            insertFontItem(item)
        }
        
        if fonts.first(where: {$0.fontName == fontName}) == nil {
            if let font = NSFont(name: fontName, size: 0), font.displayName != nil {
                fonts.append(font)
                
                fontPopupMenu.menu?.addItem(NSMenuItem.separator())
                insertFontItem(font)
            }
        }
        
        if fontName == "-" {
            fontPopupMenu.selectItem(at: 0)
        } else if let font = fonts.first(where: { $0.fontName == fontName}) {
            fontPopupMenu.selectItem(withTitle: font.displayName!)
        }
    }
    
    @IBAction func openFontPanel(_ sender: Any) {
        handler?(fontName, self.fontSize, true)
    }
    
    @IBAction func handleFontPopup(_ sender: Any) {
        if fontPopupMenu.indexOfSelectedItem == 0 {
            // ui-monospace
            self.fontName = "-"
        } else if let font = fontPopupMenu.selectedItem?.representedObject as? NSFont {
            self.fontName = font.fontName
        }
    }
    
    @IBAction func handleDone(_ sender: Any) {
        handler?(fontName, self.fontSize, false)
        self.dismiss(self)
    }
}
