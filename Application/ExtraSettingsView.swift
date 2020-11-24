//
//  ExtraSettingsView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 27/04/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Service

protocol ExtraSettingsViewDelegate: class {
    func extraSettingsRequestRefreshPreview(extraSettingsView: ExtraSettingsView)
}

class ExtraSettingsView: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var extraCheckbox: NSButton!
    @IBOutlet weak var extraLabel: NSButton!
    @IBOutlet weak var extraTextField: NSTextField!
    
    @IBOutlet weak var appendArgumentsCheckbox: NSButton!
    @IBOutlet weak var appendArgumentsLabel: NSButton!
    @IBOutlet weak var appendArgumentsTextField: NSTextField!
       
    @IBOutlet weak var interactiveCheckbox: NSButton!
    @IBOutlet weak var interactiveLabel: NSButton!
    @IBOutlet weak var interactiveSwitch: NSSwitch!
    @IBOutlet weak var interactiveTip: NSTextField!
       
    @IBOutlet weak var preprocessorCheckbox: NSButton!
    @IBOutlet weak var preprocessorLabel: NSButton!
    @IBOutlet weak var preprocessorTextField: NSTextField!
    @IBOutlet weak var preprocessorWariningImageView: NSImageView!
       
    @IBOutlet weak var interpretsCheckbox: NSButton!
    @IBOutlet weak var interpretsLabel: NSButton!
    @IBOutlet weak var interpretsPopup: NSPopUpButton!
    
    @IBOutlet weak var customWarningLabel: NSTextField!
    
    weak var delegate: ExtraSettingsViewDelegate?
        
    var service: SCSHXPCServiceProtocol? {
        return (NSApplication.shared.delegate as? AppDelegate)?.service
    }
    
    fileprivate(set) var isGlobal: Bool = false {
        didSet {
            extraCheckbox.isHidden = isGlobal
            
            appendArgumentsCheckbox.isHidden = isGlobal
            appendArgumentsLabel.isHidden = isGlobal
            appendArgumentsTextField.isHidden = isGlobal
            
            interactiveCheckbox.isHidden = isGlobal
            
            preprocessorCheckbox.isHidden = isGlobal
            preprocessorTextField.isHidden = isGlobal
            preprocessorWariningImageView.isHidden = isGlobal || preprocessorCheckbox.state == .off
            preprocessorLabel.isHidden = isGlobal
            
            interpretsCheckbox.isHidden = isGlobal
            interpretsLabel.isHidden = isGlobal
            interpretsPopup.isHidden = isGlobal
            
            customWarningLabel.isHidden = isGlobal
        }
    }
    
    var renderMode: SCSHBaseSettings.Format = SCSHGlobalBaseSettings.preferredFormat {
        didSet {
            interactiveCheckbox.isEnabled = (isGlobal || interpretsCheckbox.state == .on) && renderMode == .html
            interactiveSwitch.isEnabled = interactiveCheckbox.isEnabled
            interactiveTip.isHidden = interactiveCheckbox.isEnabled
            interactiveLabel.isEnabled = renderMode == .html
        }
    }
    
    var availableSyntax: [String: [String: Any]] = [:] {
        didSet {
            self.interpretsPopup.removeAllItems()
            self.interpretsPopup.addItem(withTitle: "Auto")
            if availableSyntax.count > 0 {
                self.interpretsPopup.menu?.addItem(NSMenuItem.separator())
                let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
                for desc in keys {
                    let m = NSMenuItem(title: desc, action: nil, keyEquivalent: "")
                    m.toolTip = desc
                    if let extensions = availableSyntax[desc]!["extensions"] as? [String] {
                        m.toolTip! += " [" + extensions.joined(separator: ", ") + "]"
                    }
                    self.interpretsPopup.menu?.addItem(m)
                }
            }
            self.interpretsPopup.isEnabled = self.interpretsCheckbox.state == .on || self.isGlobal
        }
    }
    
    private var isPopulating = false
    
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

        service?.highlightAvailableSyntax(reply: { (result) in
            if let items = result as? [String: [String: Any]] {
                self.availableSyntax = items
            }
        })
    }
    
    @IBAction func handleExtraLabel(_ sender: NSButton) {
        setExtraState(self.extraCheckbox.state == .on ? .off : .on)
    }
    
    @IBAction func handleExtraCheckbox(_ sender: NSButton) {
        setExtraState(self.extraCheckbox.state)
    }
    
    func setExtraState(_ state: NSControl.StateValue) {
        self.extraCheckbox.state = state
       
        extraTextField.isEnabled = isGlobal || state == .on
        refresh(self)
    }
    
    @IBAction func handleAppendArgumentsLabel(_ sender: NSButton) {
        setAppendArgumentsState(self.appendArgumentsCheckbox.state == .on ? .off : .on)
    }
    
    @IBAction func handleAppendArgumentsCheckbox(_ sender: NSButton) {
        setAppendArgumentsState(self.appendArgumentsCheckbox.state)
    }
    
    func setAppendArgumentsState(_ state: NSControl.StateValue) {
        self.appendArgumentsCheckbox.state = state
       
        appendArgumentsTextField.isEnabled = !isGlobal && state == .on
        refresh(self)
    }
    
    @IBAction func handleInteractiveLabel(_ sender: NSButton) {
        if renderMode == .html {
            setInteractiveState(self.interactiveCheckbox.state == .on ? .off : .on)
        }
    }
    
    @IBAction func handleInteractiveCheckbox(_ sender: NSButton) {
        setInteractiveState(self.interactiveCheckbox.state)
    }
    
    func setInteractiveState(_ state: NSControl.StateValue) {
        self.interactiveCheckbox.state = state
       
        interactiveSwitch.isEnabled = renderMode == .html && (isGlobal || state == .on)
        interactiveTip.isHidden = renderMode == .html
        refresh(self)
    }
    
    @IBAction func handleProprocessorChange(_ sender: NSTextField) {
        preprocessorWariningImageView.isHidden = isGlobal || sender.stringValue.isEmpty || sender.stringValue.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) != nil
        self.refresh(sender)
    }
    
    @IBAction func handlePreprocessorLabel(_ sender: NSButton) {
        setPreprocessorState(self.preprocessorCheckbox.state == .on ? .off : .on)
    }
    
    @IBAction func handlePreprocessorCheckbox(_ sender: NSButton) {
        setPreprocessorState(self.preprocessorCheckbox.state)
    }
    
    func setPreprocessorState(_ state: NSControl.StateValue) {
        self.preprocessorCheckbox.state = state
       
        preprocessorTextField.isEnabled = !isGlobal && state == .on
        preprocessorWariningImageView.isHidden = isGlobal || state == .off || preprocessorTextField.stringValue.isEmpty || preprocessorTextField.stringValue.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) != nil
        refresh(self)
    }
    
    @IBAction func handleInterpretsLabel(_ sender: NSButton) {
        setInterpretsState(self.interpretsCheckbox.state == .on ? .off : .on)
    }
    
    @IBAction func handleInterpretsCheckbox(_ sender: NSButton) {
        setInterpretsState(self.interpretsCheckbox.state)
    }
    
    func setInterpretsState(_ state: NSControl.StateValue) {
        self.interpretsCheckbox.state = state
       
        interpretsPopup.isEnabled = !isGlobal && state == .on
        refresh(self)
    }
    
    @IBAction func refresh(_ sender: Any) {
        if !isPopulating {
            self.delegate?.extraSettingsRequestRefreshPreview(extraSettingsView: self)
        }
    }
    
    internal func setSyntax(_ syntax: String) {
        let keys = Array(availableSyntax.keys.sorted(by: {$0.compare($1, options: .caseInsensitive) == .orderedAscending }))
        
        if let i = keys.firstIndex(where: { (availableSyntax[$0]?["extensions"] as? [String])?.contains(syntax) ?? false }) {
            interpretsPopup.selectItem(at: i + 2)
        } else {
            interpretsPopup.selectItem(at: 0)
        }
    }
    
    func populateFromSettings(_ settings: SCSHBaseSettings) {
        isPopulating = true
        isGlobal = settings as? SCSHSettings != nil
        
        appendArgumentsTextField.stringValue = ""
        
        if let settings = settings as? SCSHSettings {
            self.renderMode = settings.format ?? .rtf
            interpretsPopup.selectItem(at: 0)
        } else if let settings = settings as? SCSHUTIBaseSettings {
            setAppendArgumentsState(settings.appendedExtra != nil ? .on : .off)
            appendArgumentsTextField.stringValue = settings.appendedExtra ?? ""
            
            if let syntax = settings.syntax {
                setSyntax(syntax)
            } else {
                setSyntax("")
            }
        } else {
            interpretsPopup.selectItem(at: 0)
        }
        
        setExtraState(settings.extra != nil && !settings.extra!.isEmpty ? .on : .off)
        extraTextField.stringValue = settings.extra ?? ""
        
        setInteractiveState(settings.allowInteractiveActions != nil ? .on : .off)
        interactiveSwitch.state = settings.allowInteractiveActions != nil ? (settings.allowInteractiveActions! ? .on : .off) : .off
        
        setPreprocessorState(settings.preprocessor != nil ? .on : .off)
        preprocessorTextField.stringValue = settings.preprocessor ?? ""
        preprocessorWariningImageView.isHidden = isGlobal || settings.preprocessor == nil || settings.preprocessor?.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) != nil
        
        setInterpretsState(settings.syntax != nil && !settings.syntax!.isEmpty ? .on : .off)
        
        if let settings = settings as? SCSHUTIBaseSettings {
            if settings.appendedExtra == nil, let extra = settings.specialSettings[SCSHBaseSettings.Key.extraArguments] {
                appendArgumentsTextField.stringValue = extra
            }
            if settings.preprocessor == nil, let preprocessor = settings.specialSettings[SCSHBaseSettings.Key.preprocessor] {
                preprocessorTextField.stringValue = preprocessor
            }
            if settings.syntax == nil, let syntax = settings.specialSettings[SCSHBaseSettings.Key.syntax] {
                setSyntax(syntax)
            }
        }
        isPopulating = false
    }
    
    func saveSettings(on destination_settings: SCSHBaseSettings) {
        mergeSettings(on: destination_settings)
        guard !isGlobal else {
            return
        }
        
        if let settings = destination_settings as? SCSHSettings {
            if preprocessorCheckbox.state == .off {
                settings.preprocessor = nil
            }
        }
        
        if extraCheckbox.state == .off {
            destination_settings.extra = nil
        }
        
        if preprocessorCheckbox.state == .off {
            destination_settings.preprocessor = nil
        }
        
        if interactiveCheckbox.state == .off {
            destination_settings.allowInteractiveActions = nil
        }
        
        if appendArgumentsCheckbox.state == .off, let destination_settings = destination_settings as? SCSHUTIBaseSettings {
            destination_settings.appendedExtra = nil
        }
    }
    
    func mergeSettings(on destination_settings: SCSHBaseSettings) {
        if let settings = destination_settings as? SCSHSettings {
            if isGlobal || preprocessorCheckbox.state == .on {
                let v = preprocessorTextField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
                settings.preprocessor = v.isEmpty ? nil : v
            }
        }
        
        if isGlobal || extraCheckbox.state == .on {
            destination_settings.extra = extraTextField.stringValue
        }
        if isGlobal || interactiveCheckbox.state == .on {
            destination_settings.allowInteractiveActions = interactiveSwitch.state == .on
        }
        if !isGlobal && preprocessorCheckbox.state == .on {
            destination_settings.preprocessor = preprocessorTextField.stringValue.isEmpty ? nil : preprocessorTextField.stringValue
        }
        if appendArgumentsCheckbox.state == .on, let destination_settings = destination_settings as? SCSHUTIBaseSettings {
            destination_settings.appendedExtra = appendArgumentsTextField.stringValue
        }
        
        if !isGlobal && interpretsCheckbox.state == .on && interpretsPopup.indexOfSelectedItem > 1 {
            let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
            let desc = String(keys[interpretsPopup.indexOfSelectedItem - 2])
            if let `extension` = availableSyntax[desc]?["extension"] as? String {
                destination_settings.syntax = `extension`
            }
        }
    }
}

