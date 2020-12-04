//
//  GlobalSettingsView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 05/05/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Service

protocol GlobalSettingsViewDelegate: class {
    func globalSettings(globalSettingsView: GlobalSettingsView, showHighlightInfoForPath path: String?)
    func globalSettings(_ globalSettingsView: GlobalSettingsView, outputModeChangedTo format: SCSHBaseSettings.Format)
    func globalSettings(_ globalSettingsView: GlobalSettingsView, highlightPathChangedTo path: String?)
}

typealias HighlightPath = (path: String, ver: String, embedded: Bool)

class GlobalSettingsView: NSView {
    @IBOutlet weak var contentView: NSView!
    
    /// Popup of highlight path.
    @IBOutlet weak var highlightPathPopup: NSPopUpButton!
    /// Control for the output mode (html|rtf).
    @IBOutlet weak var formatModeControl: NSSegmentedControl!
            
    /// Input field for file size limit.
    @IBOutlet weak var dataSize: NSTextField!
    /// Popup field for unit of the file size limit.
    @IBOutlet weak var dataSizeUM: NSPopUpButton!
    
    @IBOutlet weak var debugButton: NSSwitch!
    
    weak var delegate: GlobalSettingsViewDelegate?
    
    var isPopulating = false
    var isDirty = false
    internal var currentSettings: [String: AnyHashable] = [:] {
        didSet {
            isDirty = false
        }
    }
    
    var highlightProgramPath: String?
    
    var highlightPaths: [HighlightPath] = []
    
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
    }
    
    /// Handle highlight theme change.
    @IBAction func handleHighLightPathChange(_ sender: NSPopUpButton) {
        var changed = false
        
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            // Browse for a custom path.
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.resolvesAliases = false
            openPanel.showsHiddenFiles = true
            
            if let s = self.highlightProgramPath, s != "-" {
                let url = URL(fileURLWithPath: s, isDirectory: false)
                openPanel.directoryURL = url.deletingLastPathComponent()
            }
            
            openPanel.beginSheetModal(for: self.contentView.window!) { (result) -> Void in
                if result == .OK, let url = openPanel.url {
                    self.highlightPaths.append((path: url.path, ver: "", embedded: false))
                    
                    let m = NSMenuItem(title: url.path, action: nil, keyEquivalent: "")
                    m.tag = self.highlightPaths.count-1
                    self.highlightPathPopup.menu?.insertItem(m, at: sender.numberOfItems-1)
                    sender.select(m)
                    
                    self.highlightProgramPath = url.path
                    changed = true
                } else {
                    // Restore previous selected path.
                    if let i = self.highlightPaths.firstIndex(where: { $0.path == self.highlightProgramPath }), let m = sender.menu?.item(withTag: i) {
                        sender.select(m)
                    } else {
                        sender.selectItem(at: 0)
                    }
                }
            }
        } else {
            if let i = sender.selectedItem?.tag, i >= 0, i < self.highlightPaths.count {
                self.highlightProgramPath = self.highlightPaths[i].path
                changed = true
            }
        }
        
        guard changed else {
            return
        }
        
        delegate?.globalSettings(self, highlightPathChangedTo: self.highlightProgramPath)
    }
    
    /// Shows the about highlight window,
    @IBAction func handleInfoButton(_ sender: Any) {
        delegate?.globalSettings(globalSettingsView: self, showHighlightInfoForPath: self.highlightProgramPath)
    }
    
    /// Handle format output change.
    @IBAction func handleFormatChange(_ sender: NSSegmentedControl) {
        delegate?.globalSettings(self, outputModeChangedTo: sender.indexOfSelectedItem != 0 ? .rtf : .html)
    }
    
    func populateFromSettings(_ settings: SCSHSettings) {
        isPopulating = true
        
        self.highlightProgramPath = settings.highlightProgramPath
        
        // Fill highlight popup menu.
        self.highlightPathPopup.removeAllItems()
        
        for (i, path) in self.highlightPaths.enumerated() {
            let m = NSMenuItem(title: "\(path.embedded ? "Internal" : path.path)\(path.ver != "" ? " (ver. \(path.ver))" : "")", action: nil, keyEquivalent: "")
            m.tag = i
            self.highlightPathPopup.menu?.addItem(m)
            if self.highlightProgramPath == path.path {
                self.highlightPathPopup.select(m)
            }
            if path.embedded && self.highlightPaths.count > 1 {
                let sep = NSMenuItem.separator()
                sep.tag = -2
                self.highlightPathPopup.menu?.addItem(sep)
            }
        }
        let sep = NSMenuItem.separator()
        sep.tag = -2
        self.highlightPathPopup.menu?.addItem(sep)
        
        let m = NSMenuItem(title: "Other…", action: nil, keyEquivalent: "")
        m.tag = -1
        self.highlightPathPopup.menu?.addItem(m)
        self.highlightPathPopup.isEnabled = true
        
        // HTML/RTF format
        self.formatModeControl.setSelected(true, forSegment: settings.format == .rtf ? 1 : 0)
        self.formatModeControl.isEnabled = true
        
        // Filesize limit.
        if var size = settings.maxData {
            size /= 1024 // Convert Bytes to KB.
            if size % 1024 == 0 {
                dataSize.intValue = Int32(size / 1024)
                dataSizeUM.selectItem(at: 1)
            } else {
                dataSize.intValue = Int32(size)
                dataSizeUM.selectItem(at: 0)
            }
        } else {
            dataSize.intValue = 0
            dataSizeUM.selectItem(at: 0)
        }
        
        // Debug.
        debugButton.state = settings.debug ? .on : .off
        debugButton.isEnabled = true
        
        isPopulating = false
        
        currentSettings = self.settingsToDictionary(settings)
    }
    
    internal func settingsToDictionary(_ settings: SCSHSettings) -> [String: AnyHashable] {
        return [
            SCSHBaseSettings.Key.highlightPath: settings.highlightProgramPath,
            SCSHBaseSettings.Key.format: settings.format?.rawValue,
            SCSHBaseSettings.Key.debug: settings.debug
        ]
    }
    
    func exportSettings(on new_settings: SCSHSettings) {
        new_settings.highlightProgramPath = self.highlightProgramPath ?? "-"
        new_settings.format = formatModeControl.selectedSegment == 0 ? .html : .rtf
        if self.dataSize.floatValue > 0 {
            var dataSize = self.dataSize.floatValue
            if self.dataSizeUM.indexOfSelectedItem == 1 {
                dataSize *= 1024 // Convert MB to KB.
            }
            dataSize *= 1024 // Convert KB to Bytes.
           
            new_settings.maxData = UInt64(dataSize)
        } else {
            new_settings.maxData = 0
        }
               
        new_settings.debug = self.debugButton.state == .on
        self.isDirty = self.currentSettings != self.settingsToDictionary(new_settings)
     }
}
