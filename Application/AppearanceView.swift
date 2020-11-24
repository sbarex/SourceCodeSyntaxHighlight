//
//  AppearanceView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 25/04/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Service


protocol AppearanceViewDelegate: class {
    func appearance(appearanceView: AppearanceView, requestBrowserForTheme theme: SCSHTheme?, mode: ThemeStyleFilterEnum, fromView: NSView, onComplete: @escaping (_ theme: SCSHTheme?)->Void)
    
    func appearanceRequestRefreshPreview(appearanceView: AppearanceView)
    
    func appearance(appearanceView: AppearanceView, requestCustomStyle style: String, showingUTIWarning: Bool, onComplete: @escaping (_ style: String)->Void)
}

class AppearanceView: NSView {
    @IBOutlet weak var contentView: NSView!
        
    @IBOutlet weak var themeCheckbox: NSButton!
    @IBOutlet weak var themeLabel: NSButton!
    @IBOutlet weak var themeLightIcon: NSButton!
    @IBOutlet weak var themeLightLabel: NSTextField!
    @IBOutlet weak var themeDarkIcon: NSButton!
    @IBOutlet weak var themeDarkLabel: NSTextField!
    
    @IBOutlet weak var styleCheckbox: NSButton!
    @IBOutlet weak var styleLabel: NSButton!
    @IBOutlet weak var styleButton: NSButton!
    @IBOutlet weak var styleImage: NSImageView!
    @IBOutlet weak var styleTip: NSTextField!
    
    @IBOutlet weak var fontCheckbox: NSButton!
    @IBOutlet weak var fontLabel: NSButton!
    @IBOutlet weak var fontChooseButton: NSButton!
    @IBOutlet weak var fontPreviewTextField: NSTextField!
    
    @IBOutlet weak var wrapCheckbox: NSButton!
    @IBOutlet weak var wrapLabel: NSButton!
    @IBOutlet weak var wrapPopup: NSPopUpButton!
    @IBOutlet weak var wrapLengthTextField: NSTextField!
    @IBOutlet weak var wrapLengthLabel: NSTextField!
    
    @IBOutlet weak var lineNumberCheckbox: NSButton!
    @IBOutlet weak var lineNumberLabel: NSButton!
    @IBOutlet weak var lineNumbersPopup: NSPopUpButton!
    
    @IBOutlet weak var tabCheckbox: NSButton!
    @IBOutlet weak var tabLabel: NSButton!
    @IBOutlet weak var tabSlider: NSSlider!
    @IBOutlet weak var customWarningLabel: NSTextField!
    
    weak var delegate: AppearanceViewDelegate?
    
    var customCSSStyle: String? = nil {
        didSet {
            styleImage.image = NSImage(named: customCSSStyle != nil && !customCSSStyle!.isEmpty ? NSImage.statusAvailableName : NSImage.statusNoneName)
            setStyleState(customCSSStyle != nil && !customCSSStyle!.isEmpty ? .on : .off)
        }
    }
    var lightTheme: SCSHTheme? {
        didSet {
            refreshTheme(lightTheme, button: themeLightIcon, label: themeLightLabel)
        }
    }
    var darkTheme: SCSHTheme? {
           didSet {
               refreshTheme(darkTheme, button: themeDarkIcon, label: themeDarkLabel)
           }
       }
    
    var renderMode: SCSHBaseSettings.Format = SCSHGlobalBaseSettings.preferredFormat {
        didSet {
            styleCheckbox.isEnabled = renderMode == .html
            styleLabel.isEnabled = renderMode == .html
            styleButton.isEnabled = renderMode == .html
            styleTip.isHidden = renderMode == .html
        }
    }
    
    var themes: [SCSHTheme] = [] {
        didSet {
            if themes.count == 0 {
                if themeLightIcon.isEnabled {
                    themeLightIcon.isEnabled = false
                }
                if themeDarkIcon.isEnabled {
                    themeDarkIcon.isEnabled = false
                }
            }
        }
    }
    
    var fontFamily: String? {
        return fontPreviewTextField.font?.fontName
    }
    var fontSize: CGFloat? {
        return self.fontPreviewTextField.font?.pointSize
    }
    
    private var isPopulating = false
    
    fileprivate(set) var isGlobal: Bool = false {
        didSet {
            themeCheckbox.isHidden = isGlobal
            styleCheckbox.isHidden = isGlobal
            fontCheckbox.isHidden = isGlobal
            wrapCheckbox.isHidden = isGlobal
            lineNumberCheckbox.isHidden = isGlobal
            tabCheckbox.isHidden = isGlobal
            
            customWarningLabel.isHidden = isGlobal
        }
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
        
        themeCheckbox.isHidden = true
        styleCheckbox.isHidden = true
        fontCheckbox.isHidden = true
        wrapCheckbox.isHidden = true
        lineNumberCheckbox.isHidden = true
        tabCheckbox.isHidden = true
        
        for btn in [themeLightIcon, themeDarkIcon] {
            // Add round corners and border to the theme icons.
            btn?.wantsLayer = true
            btn?.layer?.cornerRadius = 8
            btn?.layer?.borderWidth = 1
            btn?.layer?.borderColor = NSColor.gridColor.cgColor
        }
    }
    
    func populateFromSettings(_ settings: SCSHBaseSettings) {
        isPopulating = true
        isGlobal = settings as? SCSHSettings != nil
        
        lightTheme = getTheme(name: settings.lightTheme)
        darkTheme = getTheme(name: settings.darkTheme)
        setThemeState(lightTheme != nil ? .on : .off)
        
        customCSSStyle = settings.css
        
        setFontState(settings.fontFamily != nil ? .on : .off)
        refreshFontPanel(withFontFamily: settings.fontFamily ?? "Menlo", size: settings.fontSize ?? 12, isGlobal: isGlobal)
        
        setWrapState(settings.wordWrap != nil ? .on : .off)
        switch settings.wordWrap ?? .off {
        case .off:
            wrapPopup.selectItem(at: 0)
            
            wrapLengthTextField.isHidden = true
            wrapLengthLabel.isHidden = true
            
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = false
        case .simple:
            wrapPopup.selectItem(at: 1)
            
            wrapLengthTextField.isHidden = false
            wrapLengthLabel.isHidden = false
            
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
        case .standard:
            wrapPopup.selectItem(at: 2)
            
            wrapLengthTextField.isHidden = false
            wrapLengthLabel.isHidden = false
            
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
        }
        wrapLengthTextField.integerValue = settings.lineLength ?? 80
        wrapLengthTextField.isEnabled = isGlobal || wrapCheckbox.state == .on
        
        setLineNumberState(settings.lineNumbers != nil ? .on : .off)
        switch settings.lineNumbers ?? .hidden {
        case .hidden:
            lineNumbersPopup.selectItem(at: 0)
        case .visible(let omittingWrapLines):
            lineNumbersPopup.selectItem(at: omittingWrapLines ? 2 : 1)
        }
        
        setTabState(settings.tabSpaces != nil ? .on : .off)
        tabSlider.integerValue = settings.tabSpaces ?? 4
        isPopulating = false
    }
    
    func saveSettings(on new_settings: SCSHBaseSettings) {
        mergeSettings(on: new_settings)
        guard !isGlobal else {
            return
        }
        
        if themeCheckbox.state == .off {
            new_settings.lightTheme = nil
            new_settings.lightBackgroundColor = nil
            new_settings.darkTheme = nil
            new_settings.darkBackgroundColor = nil
        }
        
        if styleCheckbox.state == .off {
            new_settings.css = nil
        }
        
        if fontCheckbox.state == .off {
            new_settings.fontFamily = nil
            new_settings.fontSize = nil
        }
        
        if wrapCheckbox.state == .off {
            new_settings.wordWrap = nil
            new_settings.lineLength = nil
        }
        
        if lineNumberCheckbox.state == .off {
            new_settings.lineNumbers = nil
        }
        
        if tabCheckbox.state == .off {
            new_settings.tabSpaces = nil
        }
    }
    
    func mergeSettings(on new_settings: SCSHBaseSettings) {
        if isGlobal || themeCheckbox.state == .on {
            if let theme = lightTheme {
                new_settings.lightTheme = (theme.isStandalone ? "" : "!") + theme.name
                new_settings.lightBackgroundColor = theme.backgroundColor
            }
            if let theme = darkTheme {
                new_settings.darkTheme = (theme.isStandalone ? "" : "!") + theme.name
                new_settings.darkBackgroundColor = theme.backgroundColor
            }
        }
        
        if isGlobal || styleCheckbox.state == .on {
            new_settings.css = customCSSStyle?.isEmpty ?? true ? nil : customCSSStyle
        }
        
        if isGlobal || fontCheckbox.state == .on {
            new_settings.fontFamily = self.fontFamily ?? "Menlo"
            new_settings.fontSize = self.fontSize ?? 12
        }
        
        if isGlobal || wrapCheckbox.state == .on {
            switch wrapPopup.indexOfSelectedItem {
            case 0:
                new_settings.wordWrap = .off
                new_settings.lineLength = nil
            case 1:
                new_settings.wordWrap = .simple
                new_settings.lineLength = wrapLengthTextField.integerValue
            case 2:
                new_settings.wordWrap = .standard
                new_settings.lineLength = wrapLengthTextField.integerValue
            default:
                new_settings.wordWrap = nil
                new_settings.lineLength = nil
            }
        }
        
        if isGlobal || lineNumberCheckbox.state == .on {
            switch lineNumbersPopup.indexOfSelectedItem {
            case 0:
                new_settings.lineNumbers = .hidden
            case 1:
                new_settings.lineNumbers = .visible(omittingWrapLines: false)
            case 2:
                if let ww = new_settings.wordWrap {
                    new_settings.lineNumbers = .visible(omittingWrapLines: ww != .off)
                } else {
                    new_settings.lineNumbers = .visible(omittingWrapLines: false)
                }
            default:
                new_settings.lineNumbers = nil
            }
        }
        
        if isGlobal || tabCheckbox.state == .on {
            new_settings.tabSpaces = tabSlider.integerValue
        }
    }
   
    
    // MARK: - style
    
    @IBAction func handleStyleLabel(_ sender: NSButton) {
        setStyleState(sender.state)
    }
    @IBAction func handleStyleCheckbox(_ sender: NSButton) {
        setStyleState(sender.state)
    }
    func setStyleState(_ state: NSControl.StateValue) {
        self.styleCheckbox.state = state
        
        styleButton.isEnabled = (isGlobal || state == .on) && renderMode == .html
        styleTip.isHidden = styleButton.isEnabled
        
        refresh(self)
    }
    
    @IBAction func customizeStyle(_ sender: NSButton) {
        self.delegate?.appearance(appearanceView: self, requestCustomStyle: customCSSStyle ?? "", showingUTIWarning: !isGlobal, onComplete: { (style) in
            self.customCSSStyle = style.isEmpty ? nil : style
            self.refresh(self)
            
            self.styleImage.image = NSImage(named: !style.isEmpty ? NSImage.statusAvailableName : NSImage.statusNoneName)
        })
    }
    
    // MARK: - font
    @IBAction func handleFontLabel(_ sender: NSButton) {
       setFontState(self.fontCheckbox.state == .on ? .off : .on)
    }
    @IBAction func handleFontCheckbox(_ sender: NSButton) {
        setFontState(sender.state)
    }
    
    func setFontState(_ state: NSControl.StateValue) {
        self.fontCheckbox.state = state
        
        fontPreviewTextField.isEnabled = isGlobal || state == .on
        fontChooseButton.isEnabled = isGlobal || state == .on
        
        refresh(self)
    }
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: NSButton) {
        let fontPanel = NSFontPanel.shared
        fontPanel.worksWhenModal = true
        fontPanel.becomesKeyOnlyIfNeeded = true
        
        let fontFamily: String  = self.fontFamily ?? "Menlo"
        let fontSize: Float = Float(self.fontSize ?? 12)
        
        if let font = NSFont(name: fontFamily, size: CGFloat(fontSize)) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        
        self.window?.makeFirstResponder(self)
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFont font: NSFont, isGlobal: Bool) {
        let ff: String
        if let family = font.familyName {
            ff = family
        } else {
            ff = font.fontName
        }
        
        let fp = font.pointSize
        
        fontPreviewTextField.stringValue = String(format:"%@ %.1f pt", ff, fp)
        fontPreviewTextField.font = font
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFontFamily font: String, size: CGFloat, isGlobal: Bool) {
        if let f = NSFont(name: font, size: size) {
            self.refreshFontPanel(withFont: f, isGlobal: isGlobal)
        }
    }
    
    // MARK: - wrap
    
    @IBAction func handleWrapLabel(_ sender: NSButton) {
        self.wrapCheckbox.state = self.wrapCheckbox.state == .on ? .off : .on
    }
    
    @IBAction func handleWrapCheckbox(_ sender: NSButton) {
        setWrapState(sender.state)
    }
    func setWrapState(_ state: NSControl.StateValue) {
        self.wrapCheckbox.state = state
        
        wrapPopup.isEnabled = isGlobal || state == .on
        
        refresh(self)
    }
    
    @IBAction func handleWrapChange(_ sender: NSPopUpButton) {
        wrapLengthTextField.isHidden = sender.indexOfSelectedItem == 0
        wrapLengthLabel.isHidden = sender.indexOfSelectedItem == 0
        
        if sender.indexOfSelectedItem == 0 {
            if lineNumbersPopup.indexOfSelectedItem == 2 {
                lineNumbersPopup.selectItem(at: 1)
            }
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = false
        } else {
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
        }
        refresh(sender)
    }
    
    // MARK: - line number
    @IBAction func handleLineNumberLabel(_ sender: NSButton) {
        self.setLineNumberState(self.lineNumberCheckbox.state == .on ? .off : .on)
    }
    @IBAction func handleLineNumberCheckbox(_ sender: NSButton) {
        setLineNumberState(sender.state)
    }
    func setLineNumberState(_ state: NSControl.StateValue) {
        self.lineNumberCheckbox.state = state
        
        lineNumbersPopup.isEnabled = isGlobal || state == .on
        refresh(self)
    }
    
    // MARK: - tabs
    @IBAction func handleTabLabel(_ sender: NSButton) {
        setTabState(self.tabCheckbox.state == .on ? .off : .on)
    }
    @IBAction func handleTabCheckbox(_ sender: NSButton) {
        setTabState(sender.state)
    }
    func setTabState(_ state: NSControl.StateValue) {
        self.tabCheckbox.state = state
        tabSlider.isEnabled = isGlobal || state == .on
        refresh(self)
    }
    
    @IBAction func refresh(_ sender: Any) {
        if !isPopulating {
            self.delegate?.appearanceRequestRefreshPreview(appearanceView: self)
        }
    }
    
    // MARK: - theme
    @IBAction func handleThemeLabel(_ sender: NSButton) {
        setThemeState(self.themeCheckbox.state == .on ? .off : .on)
    }
   
    @IBAction func handleThemeCheckbox(_ sender: NSButton) {
        setThemeState(sender.state)
    }
   
    func setThemeState(_ state: NSControl.StateValue) {
        self.themeCheckbox.state = state
       
        if !isGlobal {
            themeLightIcon.isEnabled = themes.count > 0 && state == .on
            themeDarkIcon.isEnabled = themes.count > 0 && state == .on
        } else {
            themeLightIcon.isEnabled = themes.count > 0
            themeDarkIcon.isEnabled = themes.count > 0
        }
        refresh(self)
    }
    
    @IBAction func showThemeSelector(_ sender: NSButton) {
        let theme = sender == themeLightIcon ? lightTheme : darkTheme
        self.delegate?.appearance(appearanceView: self, requestBrowserForTheme: theme, mode: sender == themeLightIcon ? .light : .dark, fromView: sender, onComplete: { (theme) in
            guard let theme = theme else {
                return
            }
            if sender == self.themeLightIcon {
                self.lightTheme = theme
            } else {
                self.darkTheme = theme
            }
            self.refresh(self)
        })
       
    }
    
    func refreshTheme(_ theme: String?, button: NSButton, label: NSTextField) {
        refreshTheme(getTheme(name: theme), button: button, label: label)
    }
    
    func refreshTheme(_ theme: SCSHTheme?, button: NSButton, label: NSTextField) {
       if let t = theme {
           button.image = t.getImage(size: button.bounds.size, font: NSFont(name: "Menlo", size: 4) ?? NSFont.systemFont(ofSize: 4))
           let text = NSMutableAttributedString()
           if !t.desc.isEmpty {
               text.append(NSAttributedString(string: "\(t.desc)\n", attributes: [.font: NSFont.labelFont(ofSize: NSFont.systemFontSize)]))
           }
           text.append(NSAttributedString(string: "\(t.name)", attributes: [.font: NSFont.labelFont(ofSize: NSFont.smallSystemFontSize)]))
           
           label.attributedStringValue = text
       } else {
           button.image = nil
           label.stringValue = "-"
       }
    }
    
    
    // MARK: - theme
    /// Get a theme by name.
    /// - parameters:
    ///   - name: Name of the theme. If has ! prefix search for a customized theme, otherwise for a standalone theme.
    func getTheme(name: String?) -> SCSHTheme? {
        guard name != nil else {
            return nil
        }
        if name!.hasPrefix("!") {
            var n = name!
            n.remove(at: n.startIndex)
            return themes.first(where: { !$0.isStandalone && $0.name == n })
        } else {
            return themes.first(where: { $0.isStandalone && $0.name == name! })
        }
    }
    
    // MARK: - word wrap
    
    /// Handle word wrap change.
    @IBAction func handleWordWrapChange(_ sender: NSPopUpButton) {
        wrapLengthTextField.isHidden = sender.indexOfSelectedItem == 0
        wrapLengthLabel.isHidden = sender.indexOfSelectedItem == 0
        
        if sender.indexOfSelectedItem == 0 {
            if lineNumbersPopup.indexOfSelectedItem == 2 {
                lineNumbersPopup.selectItem(at: 1)
            }
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = false
        } else {
            lineNumbersPopup.menu?.item(at: 2)?.isEnabled = true
        }
        refresh(sender)
    }
}

// MARK: - NSFontChanging
extension AppearanceView: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        
        refreshFontPanel(withFont: font, isGlobal: isGlobal)
        
        self.refresh(self)
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}
