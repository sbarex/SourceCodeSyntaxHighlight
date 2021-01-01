//
//  ThemeCollectionViewItem.swift
//  Syntax Highlight
//
//  Created by Sbarex on 01/05/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa

class ThemeCollectionViewItem: NSCollectionViewItem {
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
    }
    
    var theme: SCSHThemePreview? {
        didSet {
            if let theme = self.theme {
                self.textField?.stringValue = theme.theme.desc
                self.textField?.toolTip = theme.theme.desc
                
                if theme.image == nil {
                    theme.image = theme.theme.getImage(size: CGSize(width: 90, height: 90), font: NSFont(name: "Menlo", size: 4) ?? NSFont.systemFont(ofSize: 4))
                }
                
                self.imageView?.image = theme.image
                self.imageView?.toolTip = theme.theme.desc
            } else {
                self.textField?.stringValue = ""
                self.textField?.toolTip = nil
                self.imageView?.image = nil
                self.imageView?.toolTip = nil
            }
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView?.image = nil
        self.imageView?.toolTip = nil
        
        self.textField?.stringValue = ""
        self.textField?.toolTip = nil
    }
}
