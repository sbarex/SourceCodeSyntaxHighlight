//
//  UTIsListView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 12/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class UTIsListView: NSView, SettingsSplitViewElement {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    /// Search field for filter the UTI list.
    @IBOutlet weak var searchField: NSSearchField!
    
    @IBOutlet weak var filterPopupButton: NSPopUpButton!
    @IBOutlet weak var showCustomizedMenuItem: NSMenuItem!
    @IBOutlet weak var showInacessibileMenuItem: NSMenuItem!
    @IBOutlet weak var showUnsavedMenuItem: NSMenuItem!
    @IBOutlet weak var showUTIMenuItem: NSMenuItem!
    @IBOutlet weak var noResultsFoundWarning: NSTextField!
    
    var showUTI = false {
        didSet {
            self.outlineView.reloadData()
            showUTIMenuItem.state = showUTI ? .on : .off
        }
    }
    
    /// All supported UTIs.
    var allFileTypes: [UTI] = []
    
    /// Filtered supported UTIs.
    var fileTypes: [UTI] = [] {
        didSet {
            guard oldValue != fileTypes else {
                return
            }
            outlineView?.reloadData()
                if let currentUTI = self.currentUTI, let index = fileTypes.firstIndex(of: currentUTI) {
                outlineView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                outlineView?.scrollRowToVisible(index)
            }
            noResultsFoundWarning.isHidden = fileTypes.count > 0
        }
    }
    
    var currentUTI: UTI? {
        didSet {
            guard oldValue != currentUTI else {
                return
            }
            self.previewView?.selectExample(forUTI: currentUTI)
            self.settingsController?.selectUTI(currentUTI)
        }
    }
    
    /// Filter for the UTI description.
    var filter: String = "" {
        didSet {
            guard oldValue != filter else {
                return
            }
            
            filterUTIs()
        }
    }
    
    /// Show only UTI with custom settings.
    var filterOnlyChanged: Bool = false {
        didSet {
            guard oldValue != filterOnlyChanged else {
                return
            }
            showCustomizedMenuItem.state = filterOnlyChanged ? .on : .off
            filterUTIs()
        }
    }
    
    var filterInacessibile: Bool = true {
        didSet {
            guard oldValue != filterInacessibile else {
                return
            }
            showInacessibileMenuItem.state = filterInacessibile ? .on : .off
            filterUTIs()
        }
    }
    
    var filterDirty: Bool = false {
        didSet {
            guard oldValue != filterDirty else {
                return
            }
            showUnsavedMenuItem.state = filterDirty ? .on : .off
            filterUTIs()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .SettingsIsDirty, object: nil)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)

        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
        
        // Populate UTIs list.
        allFileTypes = ((NSApplication.shared.delegate as? AppDelegate)?.handledUTIs ?? []).filter({ uti in
            guard uti.isDynamic, let settings = SCSHWrapper.shared.settings else {
                return true
            }
            if let _ = settings.searchStandaloneUTI(for: uti) {
                return false
            } else {
                return true
            }
        })
        
        showCustomizedMenuItem.state = filterOnlyChanged ? .on : .off
        showInacessibileMenuItem.state = filterInacessibile ? .on : .off
        showUnsavedMenuItem.state = filterDirty ? .on : .off
        
        filterUTIs()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSettingsDirty(_:)), name: .SettingsIsDirty, object: nil)
    }
    
    @objc internal func onSettingsDirty(_ notification: Notification) {
        if let settings = notification.object as? SettingsFormat, let i = self.fileTypes.firstIndex(where: { $0.UTI == settings.uti }) {
            outlineView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: 0))
        }
    }
    
    func selectUTI(_ uti: UTI?) {
        if let uti = uti, let u = fileTypes.firstIndex(where: {$0.UTI == uti.UTI }) {
            if currentUTI != uti {
                outlineView.selectRowIndexes(IndexSet(integer: u), byExtendingSelection: false)
                outlineView.scrollRowToVisible(u)
            }
        } else {
            outlineView.deselectAll(self)
            currentUTI = nil
        }
    }
    
    /// Handle change on search field.
    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField == self.searchField else {
            return
        }
        
        filter = self.searchField.stringValue
    }
    
    /// Filter the visible UTIs based on search criteria.
    func filterUTIs() {
        filterPopupButton.contentTintColor = (filterOnlyChanged || filterInacessibile || filterDirty) ? .controlAccentColor : nil
        guard !filter.isEmpty || filterOnlyChanged || filterInacessibile || filterDirty else {
            fileTypes = self.allFileTypes
            return
        }
        
        let filter = self.filter.lowercased()
        let w = SCSHWrapper.shared
        
        fileTypes = self.allFileTypes.filter({ (uti) -> Bool in
            if filterInacessibile && uti.isSuppressed {
                return false
            }
            if filterDirty && !(SCSHWrapper.shared.settings?.utiSettings[uti.UTI]?.isDirty ?? false) {
                return false
            }
            if filterOnlyChanged && !(w.hasCustomizedSettings(forUTI: uti.UTI)) {
                return false
            }
            if !filter.isEmpty && !uti.fullDescription.lowercased().contains(filter) && !uti.UTI.lowercased().contains(filter) {
                return false;
            }
            return true
        })
    }
    
    // MARK: -
    
    @IBAction func handleShowOnlyCustomized(_ sender: NSMenuItem) {
        self.filterOnlyChanged = !self.filterOnlyChanged
    }
    @IBAction func handleInaccessible(_ sender: NSMenuItem) {
        self.filterInacessibile = !self.filterInacessibile
    }
    @IBAction func handleDirty(_ sender: NSMenuItem) {
        self.filterDirty = !self.filterDirty
    }
    /// Show UTIs or extensions.
    @IBAction func handleShowUTI(_ sender: NSMenuItem) {
        self.showUTI = !self.showUTI
    }
}

// MARK: - NSOutlineViewDataSource
extension UTIsListView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return self.fileTypes[index]
        } else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? self.fileTypes.count : 0
    }
    
    /*
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return self.fileTypes[index]
    }
    */
}

// MARK: NSOutlineViewDelegate
extension UTIsListView: NSOutlineViewDelegate {
    /*
    func outlineViewSelectionIsChanging(_ notification: Notification) {
        if currentUTI == nil {
            if settings != nil {
                // Save the appearance settings of the global settings.
                saveGlobalSettings()
            }
        } else {
            saveCurrentUtiSettings(currentUTI!.uti.UTI)
        }

    }
     */
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let index = self.outlineView.selectedRow
        guard index >= 0 else {
            return
        }
        
        if index >= 0 {
            currentUTI = self.fileTypes[index]
            
            // _ = selectUTI(self.fileTypes[index].uti.UTI)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "UTICell"), owner: nil) as! UTICellView
        if let uti = item as? UTI {
            view.imageView?.image = uti.image
            view.imageWidthConstraint.constant = view.imageView?.image == nil ? 0 : 24
        
            /*
            if let image = uti.image, let settings = SCSHWrapper.shared.utiSettings[uti.UTI], settings.isDirty, let img = image.image(withBrightness: -0.2, contrast: 1-0.3, saturation: 1) {
                view.imageView?.image = img
            } else {
                view.imageView?.image = uti.image
            }
            */
            
            view.textField?.stringValue = uti.description
            view.textField?.textColor = uti.isSuppressed ? .disabledControlTextColor : .labelColor
            let utiFormat = SCSHWrapper.shared.settings?.utiSettings[uti.UTI]
            view.changedLabel.isHidden = !(utiFormat?.isDirty ?? false)

            let extensions = uti.extensions.count > 0 ? "." + uti.extensions.joined(separator: ", .") : ""
            if showUTI {
                view.UTILabel?.stringValue = uti.UTI
            } else {
                view.UTILabel?.stringValue = extensions
            }
            view.UTILabel?.textColor = view.textField?.textColor ?? .labelColor
            view.UTILabel?.toolTip = showUTI ? extensions : uti.UTI
            
            if utiFormat?.isCustomized ?? false {
                view.textField?.font = UTICellView.customizedFont
            } else {
                view.textField?.font = UTICellView.standaloneFont
            }
        }
        return view
    }
}

class UTICellView: NSTableCellView {
    @IBOutlet weak var UTILabel: NSTextField?
    @IBOutlet weak var changedLabel: NSView!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    
    static var customizedFont: NSFont = {
        let f = NSFont.labelFont(ofSize: NSFont.systemFontSize)
        return NSFontManager.shared.convert(f, toHaveTrait: [.boldFontMask])
    }()
    
    static var standaloneFont: NSFont = {
        return NSFont.labelFont(ofSize: NSFont.systemFontSize)
    }()
}
