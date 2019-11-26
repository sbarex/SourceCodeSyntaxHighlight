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

class SCSHThemePreview: Equatable {
    static func == (lhs: SCSHThemePreview, rhs: SCSHThemePreview) -> Bool {
        return lhs.theme == rhs.theme
    }
    
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

enum ThemeOriginFilterEnum: Int {
    case all
    case standalone
    case customized
}

class ThemeSelectorViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var themeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var originFilterControl: NSSegmentedControl!
    
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
            guard oldValue != filter else {
                return
            }
            refreshThemes()
        }
    }
    var style: ThemeStyleFilterEnum = .all {
        didSet {
            guard style != style else {
                return
            }
            refreshThemes()
        }
    }
    var origin: ThemeOriginFilterEnum = .all {
        didSet {
            guard origin != origin else {
                return
            }
            refreshThemes()
        }
    }
    
    @IBAction func handleStyleChange(_ sender: NSSegmentedControl) {
        if let style = ThemeStyleFilterEnum(rawValue: sender.selectedSegment) {
            self.style = style
        }
    }
    
    @IBAction func handleOriginChange(_ sender: NSSegmentedControl) {
        if let origin = ThemeOriginFilterEnum(rawValue: sender.selectedSegment) {
            self.origin = origin
        }
    }
    
    func refreshThemes() {
        themes = allThemes.filter({ theme in
            guard filter != "" || style != .all || origin != .all else {
                return true
            }
            if filter != "" {
                guard let _ = theme.theme.desc.range(of: filter, options: String.CompareOptions.caseInsensitive) else {
                    return false
                }
            }
            
            switch origin {
            case .all:
                break
            case .standalone:
                if !theme.theme.isStandalone {
                    return false
                }
            case .customized:
                if theme.theme.isStandalone {
                    return false
                }
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
        imageView?.layer?.cornerRadius = 8
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.gridColor.cgColor
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
