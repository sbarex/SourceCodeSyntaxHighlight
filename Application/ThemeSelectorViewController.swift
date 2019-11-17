//
//  ThemeSelectorViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 17/11/2019.
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

class SCSHThemePreview {
    let theme: SCSHTheme
    var image: NSImage?
    
    init(theme: SCSHTheme) {
        self.theme = theme
        self.image = nil
    }
}

enum ThemeStyleFilterEnum: Int {
    case all
    case light
    case dark
}

class ThemeSelectorViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var themeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var searchField: NSSearchField!
    
    var handler: ((SCSHTheme)->Void)?
    
    var allThemes: [SCSHThemePreview] = [] {
        didSet {
            refreshThemes()
        }
    }
    
    internal var themes: [SCSHThemePreview] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var filter: String = "" {
        didSet {
            refreshThemes()
        }
    }
    var style: ThemeStyleFilterEnum = .all {
        didSet {
            refreshThemes()
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        if let style = ThemeStyleFilterEnum(rawValue: sender.selectedSegment) {
            self.style = style
        }
    }
    
    func refreshThemes() {
        print("filter themes", filter, style.rawValue)
        themes = allThemes.filter({ theme in
            guard filter != "" || style != .all else {
                return true
            }
            if filter != "" && !theme.theme.desc.contains(filter) {
                return false
            }
            
            switch style {
            case .light:
                if !theme.theme.categories.contains("light") {
                    return false
                }
            case .dark:
                if !theme.theme.categories.contains("dark") {
                    return false
                }
            default:
                break
            }
            
            return true
        })
    }
    
    override func viewDidLoad() {
        searchField.stringValue = filter
        themeSegmentedControl.setSelected(true, forSegment: style.rawValue)
        
        refreshThemes()
    }
    
    
}

// MARK: - NSControlTextEditingDelegate
extension ThemeSelectorViewController: NSControlTextEditingDelegate {
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
       
        filter = self.searchField.stringValue
    }
}

// MARK: - NSCollectionViewDelegate
extension ThemeSelectorViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let i = indexPaths.first?.item {
            let theme = self.themes[i]
            handler?(theme.theme)
            dismiss(self)
        }
    }
}

// MARK: - NSCollectionViewDataSource
extension ThemeSelectorViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let a = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeCollectionViewItem"), for: indexPath) as! ThemeCollectionViewItem
        a.theme = themes[indexPath.item]
        return a
        // return themes[indexPath.item]
    }
    
    
}

class ThemeCollectionViewItem: NSCollectionViewItem {
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 6
        imageView?.layer?.masksToBounds = true
    }
    
    var theme: SCSHThemePreview? {
        didSet {
            if let theme = self.theme {
                self.textField?.stringValue = theme.theme.desc
                
                if theme.image == nil {
                    let format = theme.theme.getAttributedExample(fontName: "Menlo", fontSize: 4, showColorCodes: false)
                    
                    var rect = self.view.bounds
                    rect.size.height -= textField?.bounds.height ?? 0
                    
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
                    if let context = CGContext(
                        data: nil,
                        width: Int(rect.width),
                        height: Int(rect.height),
                        bitsPerComponent: 8,
                        bytesPerRow: 0,
                        space: colorSpace,
                        bitmapInfo: bitmapInfo.rawValue) {
                        
                        if let c = NSColor(fromHexString: theme.theme.backgroundColor) {
                            context.setFillColor(c.cgColor)
                            context.fill(rect)
                        }
                        
                        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
                        NSGraphicsContext.current = graphicsContext
                        
                        format.draw(in: rect)
                        
                        NSGraphicsContext.current = nil
                        
                        if let image = context.makeImage() {
                            theme.image =  NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
                        }
                    }
                }
                
                self.imageView?.image = theme.image
                
                /*
                if let rep = NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: Int(size.width),
                    pixelsHigh: Int(size.height),
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: NSColorSpaceName.calibratedRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0) {
                
                    if let context = NSGraphicsContext(bitmapImageRep: rep) {
                
                        NSGraphicsContext.saveGraphicsState()
                        NSGraphicsContext.current = context
                    
                        if let c = NSColor(fromHexString: theme.backgroundColor) {
                            c.set()
                            rect.fill()
                            
                            //context.cgContext.setFillColor(c.cgColor)
                            //context.cgContext.fill(rect)
                        }
    
                        // drawFunc()
                
                        NSGraphicsContext.restoreGraphicsState()
                    }
                
                    let image = NSImage(size: size)
                    image.addRepresentation(rep)
                }
                */
            } else {
                self.textField?.stringValue = ""
                self.imageView?.image = nil
            }
            
        }
    }
    
}
