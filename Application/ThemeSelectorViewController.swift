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

class SCSHThemePreview: SCSHTheme {
    fileprivate var _image_is_set = false
    fileprivate var _image: NSImage? = nil
    
    override internal func doRefresh() {
        invalidateImage()
        
        super.doRefresh()
    }
    
    @objc dynamic var image: NSImage? {
        if !_image_is_set {
            self._image = self.getImage(size: CGSize(width: 100, height: 100), fontSize: 8)
            _image_is_set = true
        }
        return _image
    }
    
    func invalidateImage() {
        self.willChangeValue(forKey: #keyPath(image))
        _image = nil
        _image_is_set = false
        self.didChangeValue(forKey: #keyPath(image))
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
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var lightMenuItem: NSMenuItem?
    @IBOutlet weak var darkMenuItem: NSMenuItem?
    @IBOutlet weak var standaloneMenuItem: NSMenuItem?
    @IBOutlet weak var customizedMenuItem: NSMenuItem?
    @IBOutlet weak var filterPopupButton: NSPopUpButton?
    
    var handler: ((SCSHTheme)->Void)?
    
    var allThemes: [SCSHThemePreview] {
        return HighlightWrapper.shared.themes
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
            guard oldValue != style else {
                return
            }
            switch style {
            case .all:
                lightMenuItem?.state = .off
                darkMenuItem?.state = .off
            case .light:
                lightMenuItem?.state = .on
                darkMenuItem?.state = .off
            case .dark:
                lightMenuItem?.state = .off
                darkMenuItem?.state = .on
            }
            refreshThemes()
        }
    }
    var origin: ThemeOriginFilterEnum = .all {
        didSet {
            guard oldValue != origin else {
                return
            }
            switch origin {
            case .all:
                standaloneMenuItem?.state = .off
                customizedMenuItem?.state = .off
            case .customized:
                standaloneMenuItem?.state = .off
                customizedMenuItem?.state = .on
            case .standalone:
                standaloneMenuItem?.state = .on
                customizedMenuItem?.state = .off
            }
            refreshThemes()
        }
    }
    
    @IBAction func handleLightMenuItem(_ sender: NSMenuItem) {
        if style == .light {
            style = .all
        } else {
            style = .light
        }
    }
    @IBAction func handleDarkMenuItem(_ sender: NSMenuItem) {
        if style == .dark {
            style = .all
        } else {
            style = .dark
        }
    }
    @IBAction func handleCustomMenuItem(_ sender: NSMenuItem) {
        if origin == .customized {
            origin = .all
        } else {
            origin = .customized
        }
    }
    @IBAction func handleStandaloneMenuItem(_ sender: NSMenuItem) {
        if origin == .standalone {
            origin = .all
        } else {
            origin = .standalone
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
        filterPopupButton?.contentTintColor = (style != .all || origin != .all) ? .controlAccentColor : nil
        themes = allThemes.filter({ theme in
            guard filter != "" || style != .all || origin != .all else {
                return true
            }
            if filter != "" {
                guard let _ = theme.desc.range(of: filter, options: String.CompareOptions.caseInsensitive) else {
                    return false
                }
            }
            
            switch origin {
            case .all:
                break
            case .standalone:
                if !theme.isStandalone {
                    return false
                }
            case .customized:
                if theme.isStandalone {
                    return false
                }
            }
            
            switch style {
            case .light:
                if !theme.isLight {
                    return false
                }
            case .dark:
                if !theme.isDark {
                    return false
                }
            default:
                break
            }
            
            return true
        })
    }
    
    override func viewDidLoad() {
        self.searchField.stringValue = filter
        self.lightMenuItem?.state = style == .light ? .on : .off
        self.darkMenuItem?.state = style == .dark ? .on : .off
        self.standaloneMenuItem?.state = origin == .standalone ? .on : .off
        self.customizedMenuItem?.state = origin == .customized ? .on : .off
        
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(_:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        
        refreshThemes()
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    @objc internal func interfaceModeChanged(_ notification: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.collectionView.reloadData()
        })
    }
    
    @IBAction func performFindPanelAction(_ sender: Any) {
        searchField.window?.makeFirstResponder(searchField)
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
            handler?(theme)
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
        
        guard let a = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThemeCollectionViewItem"), for: indexPath) as? ThemeCollectionViewItem else {
            return NSCollectionViewItem()
        }
        a.theme = themes[indexPath.item]
        return a
    }
}


