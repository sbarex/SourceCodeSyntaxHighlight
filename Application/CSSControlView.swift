//
//  CSSControlViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 16/11/2019.
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

class CSSControlViewController: NSViewController {
    enum Mode {
        case global
        case format
        case themeProperty
    }
    
    var mode: Mode = .global {
        didSet {
            afterModeChanged()
        }
    }
    
    var cssCode: String = "" {
        didSet {
            textView?.string = cssCode
        }
    }
    
    var isStandardPropertiesOverridden: Bool = false {
        didSet {
            overrideButton?.state = isStandardPropertiesOverridden ? .on : .off
        }
    }
    
    var isEditable = true {
        didSet {
            if isEditable != oldValue {
                updateIsEditable()
            }
        }
    }
    
    var handler: ((String, Bool, Bool)->Void)?
    
    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var warningMessage: NSTextField!
    @IBOutlet weak var overrideButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            NSHelpManager.shared.openHelpAnchor(mode == .global ? "SyntaxHighlight_CUSTOMCSS" : "SyntaxHighlight_CUSTOMCSS_THEME", inBook: locBookName)
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        handler?(textView.string, isStandardPropertiesOverridden, true)
        dismiss(sender)
    }
    
    @IBAction func doClose(_ sender: Any) {
        handler?(textView.string, isStandardPropertiesOverridden, false)
        dismiss(sender)
    }
    
    override func viewDidLoad() {
        afterModeChanged()
        
        textView?.string = cssCode
        
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isEditable = isEditable
        
        overrideButton.state = isStandardPropertiesOverridden ? .on : .off
        
        updateIsEditable()
    }
    
    internal func afterModeChanged() {
        switch mode {
        case .global, .format:
            infoLabel?.stringValue = "Custom CSS style sheet:"
        case .themeProperty:
            infoLabel?.stringValue = "Inline CSS style:"
        }
        warningMessage?.isHidden = mode != .format
        overrideButton?.isHidden = mode != .themeProperty
    }
    
    internal func updateIsEditable() {
        textView?.isEditable = isEditable
        cancelButton?.isHidden = !isEditable
        saveButton?.title = isEditable ? "OK" : "Close"
        overrideButton?.isEnabled = isEditable
    }
    
    @IBAction internal func handleOverrideButton(_ sender: NSButton) {
        isStandardPropertiesOverridden = sender.state == .on
    }
}
