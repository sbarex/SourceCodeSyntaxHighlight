//
//  SettingsView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 07/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class SettingsView: NSView, SettingsSplitViewElement {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var gridView: NSGridView!
    
    @IBOutlet weak var appearanceCheckBox: NSButton!
    @IBOutlet weak var appearancePopupButton: NSPopUpButton!
    @IBOutlet weak var appearanceAlertButton: NSButton!
    
    @IBOutlet weak var themesCheckBox: NSButton!
    @IBOutlet weak var themeLightBox: NSBox!
    @IBOutlet weak var themeLightButton: NSButton!
    @IBOutlet weak var themeLightLabel: NSTextField!
    @IBOutlet weak var themeDarkBox: NSBox!
    @IBOutlet weak var themeDarkButton: NSButton!
    @IBOutlet weak var themeDarkLabel: NSTextField!
    
    @IBOutlet weak var fontCheckBox: NSButton!
    @IBOutlet weak var fontButton: NSButton!
    @IBOutlet weak var fontLabel: NSTextField!
    
    @IBOutlet weak var wordWrapCheckBox: NSButton!
    @IBOutlet weak var wordWrapPopupButton: NSPopUpButton!
    @IBOutlet weak var lineLengthLabel: NSTextField!
    @IBOutlet weak var lineLengthTextField: NSTextField!
    @IBOutlet weak var lineLengthStepper: NSStepper!
    @IBOutlet weak var lineNumbersCheckBox: NSButton!
    @IBOutlet weak var lineNumbersPopupButton: NSPopUpButton!
    
    @IBOutlet weak var spacesCheckBox: NSButton!
    @IBOutlet weak var spacesSliderView: SliderView!
    
    @IBOutlet weak var argumentsCheckBox: NSButton!
    @IBOutlet weak var argumentsTextField: NSTextField!
    @IBOutlet weak var arguments2CheckBox: NSButton!
    @IBOutlet weak var arguments2TextField: NSTextField!
    @IBOutlet weak var preprocessorCheckBox: NSButton!
    @IBOutlet weak var preprocessorTextField: NSTextField!
    @IBOutlet weak var preprocessorWarningImageView: NSImageView!
    @IBOutlet weak var syntaxCheckBox: NSButton!
    @IBOutlet weak var syntaxPopupButton: NSPopUpButton!
    
    @IBOutlet weak var customCSSCheckBox: NSButton!
    @IBOutlet weak var customCSSButton: NSButton!
    @IBOutlet weak var interactiveCheckBox: NSButton!
    @IBOutlet weak var interactiveSwitch: NSSwitch!
    
    @IBOutlet weak var dataLimitTextField: NSTextField!
    @IBOutlet weak var dataLimitPopupButton: NSPopUpButton!
    @IBOutlet weak var EOLSwitch: NSSwitch!
    @IBOutlet weak var debugSwitch: NSSwitch!
    
    @IBOutlet weak var lspButton: NSButton!
    
    @IBOutlet weak var advancedWarning: NSTextField!
    
    var settings: SettingsBase? {
        didSet {
            initSettings()
        }
    }
    
    var isAdvancedSettingsVisible: Bool = false {
        didSet {
            gridView.cell(for: interactiveSwitch)?.row?.isHidden = !isAdvancedSettingsVisible || settings?.format != .html
            gridView.cell(for: customCSSCheckBox)?.row?.isHidden = !isAdvancedSettingsVisible || settings?.format != .html
            
            gridView.cell(for: argumentsCheckBox)?.row?.isHidden = !isAdvancedSettingsVisible
            gridView.cell(for: debugSwitch)?.row?.isHidden = !isAdvancedSettingsVisible
            gridView.cell(for: EOLSwitch)?.row?.isHidden = !isAdvancedSettingsVisible
            
            if self.settings is SettingsFormat {
                gridView.cell(for: arguments2CheckBox)?.row?.isHidden = !isAdvancedSettingsVisible
                gridView.cell(for: preprocessorCheckBox)?.row?.isHidden = !isAdvancedSettingsVisible
                gridView.cell(for: syntaxCheckBox)?.row?.isHidden = !isAdvancedSettingsVisible
                gridView.cell(for: lspButton)?.row?.isHidden = !isAdvancedSettingsVisible
            } else {
                gridView.cell(for: arguments2CheckBox)?.row?.isHidden = true
                gridView.cell(for: preprocessorCheckBox)?.row?.isHidden = true
                gridView.cell(for: syntaxCheckBox)?.row?.isHidden = true
                gridView.cell(for: lspButton)?.row?.isHidden = true
            }
            
            gridView.cell(for: advancedWarning)?.row?.isHidden = isAdvancedSettingsVisible || !(settings?.hasAdvancedSettings ?? false)
        }
    }
    
    var availableSyntax: [String: HighlightWrapper.Language] = [:] {
        didSet {
            self.syntaxPopupButton.removeAllItems()
            self.syntaxPopupButton.addItem(withTitle: "Auto")
            if availableSyntax.count > 0 {
                self.syntaxPopupButton.menu?.addItem(NSMenuItem.separator())
                let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
                for desc in keys {
                    let m = NSMenuItem(title: desc, action: nil, keyEquivalent: "")
                    m.toolTip = desc
                    if let lang = availableSyntax[desc] {
                        m.toolTip! += " [." + lang.extensions.joined(separator: ", .") + "]"
                    }
                    self.syntaxPopupButton.menu?.addItem(m)
                }
            }
            self.syntaxPopupButton.isEnabled = self.syntaxCheckBox.state == .on
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
        
        for btn in [themeLightButton, themeDarkButton] {
            // Add round corners and border to the theme icons.
            btn?.wantsLayer = true
            btn?.layer?.cornerRadius = 6
            btn?.layer?.borderWidth = 1
            btn?.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        }
        
        self.availableSyntax = HighlightWrapper.shared.languages
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeRefresh(_:)), name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDeleted(_:)), name: .CustomThemeRemoved, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAdvancedSettingsChanged(_:)), name: .AdvancedSettings, object: nil)
        
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(_:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        
        themeLightBox.wantsLayer = true
        themeLightBox.layer?.cornerRadius = 4
        themeLightButton.wantsLayer = true
        themeLightButton.layer?.cornerRadius = 4
        themeLightButton.layer?.borderColor = NSColor.gray.cgColor
        
        themeDarkBox.wantsLayer = true
        themeDarkBox.layer?.cornerRadius = 4
        themeDarkButton.wantsLayer = true
        themeDarkButton.layer?.cornerRadius = 4
        themeDarkButton.layer?.borderColor = NSColor.gray.cgColor
        
        initSettings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .ThemeNeedRefresh, object: nil)
        NotificationCenter.default.removeObserver(self, name: .CustomThemeRemoved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AdvancedSettings, object: nil)
        
        DistributedNotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    @objc internal func interfaceModeChanged(_ sender: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.initTheme(name: self.settings?.lightThemeName ?? "", label: self.themeLightLabel, button: self.themeLightButton)
            self.initTheme(name: self.settings?.darkThemeName ?? "", label: self.themeDarkLabel, button: self.themeDarkButton)
        })
    }
    
    @objc internal func handleAdvancedSettingsChanged(_ notification: Notification) {
        initTheme(name: settings?.lightThemeName, label: self.themeLightLabel, button: self.themeLightButton)
        initTheme(name: settings?.darkThemeName, label: self.themeDarkLabel, button: self.themeDarkButton)
        updateAppearanceWarning()
    }
    
    @objc internal func handleThemeRefresh(_ notification: Notification) {
        if let settings = self.settings, let theme = notification.object as? SCSHTheme {
            let themeName = theme.nameForSettings
            if settings.lightThemeName == theme.nameForSettings {
                settings.lightThemeName = themeName
                settings.lightBackgroundColor = theme.backgroundColor
                initTheme(name: settings.lightThemeName, label: themeLightLabel, button: themeLightButton)
                self.updateAppearanceWarning()
            } else if settings.darkThemeName == theme.nameForSettings {
                settings.darkThemeName = themeName
                settings.darkBackgroundColor = theme.backgroundColor
                initTheme(name: settings.darkThemeName, label: themeDarkLabel, button: themeDarkButton)
                self.updateAppearanceWarning()
            }
        }
    }
    
    @objc internal func handleThemeDeleted(_ notification: Notification) {
        if let settings = self.settings, let theme = notification.object as? SCSHTheme {
            if settings.lightThemeName == theme.nameForSettings {
                settings.lightThemeName = "edit-xcode"
                initTheme(name: settings.lightThemeName, label: themeLightLabel, button: themeLightButton)
                self.updateAppearanceWarning()
            } else if settings.darkThemeName == theme.nameForSettings {
                settings.darkThemeName = "neon"
                initTheme(name: settings.darkThemeName, label: themeDarkLabel, button: themeDarkButton)
                self.updateAppearanceWarning()
            }
        }
    }
    
    internal func initTheme(name: String?, label: NSTextField, button: NSButton) {
        initTheme(name != nil ? HighlightWrapper.shared.getTheme(name: name!) : nil, label: label, button: button)
    }
    
    internal func initTheme(_ theme: SCSHTheme?, label: NSTextField, button: NSButton) {
        guard let theme = theme else {
            button.image = nil
            label.stringValue = "---"
            label.toolTip = nil
            return
        }
        
        label.attributedStringValue = theme.attributedDesc
        label.toolTip = theme.desc
        button.image = theme.getImage(size: button.bounds.size, fontSize: 8)
    }
    
    func hideItemsForCustomSettings() {
        gridView.cell(for: arguments2TextField)?.row?.isHidden = true
        gridView.cell(for: preprocessorTextField)?.row?.isHidden = true
        gridView.cell(for: syntaxPopupButton)?.row?.isHidden = true
        gridView.cell(for: lspButton)?.row?.isHidden = true
        
        gridView.cell(for: debugSwitch)?.row?.isHidden = !isAdvancedSettingsVisible
        gridView.cell(for: EOLSwitch)?.row?.isHidden = !isAdvancedSettingsVisible
        gridView.cell(for: dataLimitTextField)?.row?.isHidden = false
    }
    
    @discardableResult
    func initSettings() -> Bool {
        defer {
            onAppearanceChanged(appearancePopupButton!)
            updateWordWrapPopup()
            updateLineNumberPopup()
        }
        
        guard let settings = self.settings else {
            appearanceCheckBox.isEnabled = false
            appearancePopupButton.isEnabled = false
            
            themesCheckBox.isEnabled = false
            themeLightButton.isEnabled = false
            themeDarkButton.isEnabled = false
            
            fontCheckBox.isEnabled = false
            fontButton.isEnabled = false
            fontLabel.isEnabled = false
            fontLabel.stringValue = ""
            
            wordWrapCheckBox.isEnabled = false
            wordWrapPopupButton.isEnabled = false
            lineLengthTextField.isEnabled = false
            lineNumbersCheckBox.isEnabled = false
            lineNumbersPopupButton.isEnabled = false
            
            spacesCheckBox.isEnabled = false
            spacesSliderView.isEnabled = false
            
            argumentsCheckBox.isEnabled = false
            argumentsTextField.isEnabled = false
            arguments2CheckBox.isEnabled = false
            arguments2TextField.isEnabled = false
            preprocessorCheckBox.isEnabled = false
            preprocessorTextField.isEnabled = false
            syntaxCheckBox.isEnabled = false
            syntaxPopupButton.isEnabled = false
            
            dataLimitTextField.isEnabled = false
            dataLimitPopupButton.isEnabled = false
            
            customCSSCheckBox.isEnabled = false
            customCSSButton.isEnabled = false
            interactiveCheckBox.isEnabled = false
            interactiveSwitch.isEnabled = false
            
            debugSwitch.isEnabled = false
            EOLSwitch.isEnabled = false
            
            lspButton.isEnabled = false
            
            gridView.cell(for: advancedWarning)?.row?.isHidden = true
            
            return false
        }
        
        let isOptional = settings is SettingsFormat
        
        let updateCheckbox = { (button: NSButton, checked: Bool, controls: [NSControl]) in
            button.imagePosition = isOptional ? .imageLeft : .noImage
            button.isEnabled = true
            button.state = isOptional ? (checked ? .on : .off) : .on
            controls.forEach { $0.isEnabled = button.state == .on }
        }
        
        updateCheckbox(appearanceCheckBox, settings.isFormatDefined, [appearancePopupButton])
        appearancePopupButton.selectItem(at: settings.format != .html ? 0 : 1)
        
        updateCheckbox(themesCheckBox, settings.isLightThemeNameDefined || settings.isDarkThemeNameDefined, [themeLightButton, themeDarkButton])
        initTheme(name: settings.lightThemeName, label: themeLightLabel, button: themeLightButton)
        initTheme(name: settings.darkThemeName, label: themeDarkLabel, button: themeDarkButton)
        
        updateCheckbox(fontCheckBox, settings.isFontNameDefined || settings.isFontSizeDefined, [fontButton, fontLabel])
        refreshFontPanel(withFontFamily: settings.fontName, size: settings.fontSize)
        
        updateCheckbox(wordWrapCheckBox, settings.isWordWrapDefined, [wordWrapPopupButton, lineLengthTextField, lineLengthStepper])
        updateWordWrapPopup()
        
        lineLengthTextField.isEnabled = settings.isWordWrapDefined && settings.isWordWrapped && settings.isWordWrappedHard
        lineLengthTextField.integerValue = settings.lineLength
        lineLengthStepper.isEnabled = lineLengthTextField.isEnabled
        lineLengthStepper.integerValue = settings.lineLength
        lineLengthLabel.textColor = lineLengthTextField.isEnabled ? .labelColor : .disabledControlTextColor
        
        updateCheckbox(lineNumbersCheckBox, settings.isLineNumbersDefined, [lineNumbersPopupButton])
        updateLineNumberPopup()
        
        updateCheckbox(spacesCheckBox, settings.isTabSpacesDefined, [spacesSliderView])
        spacesSliderView.integerValue = settings.tabSpaces
        
        updateCheckbox(argumentsCheckBox, settings.isArgumentsDefined, [argumentsTextField])
        argumentsTextField.stringValue = settings.arguments
        if let s = settings as? SettingsFormat {
            updateCheckbox(arguments2CheckBox, s.isAppendArgumentsDefined, [arguments2TextField])
            arguments2TextField.stringValue = s.isAppendArgumentsDefined || s.specialAppendArguments == nil ? s.appendArguments : s.specialAppendArguments ?? ""
            gridView.cell(for: arguments2TextField)?.row?.isHidden = !self.isAdvancedSettingsVisible
            
            updateCheckbox(preprocessorCheckBox, s.isPreprocessorDefined, [preprocessorTextField])
            if s.isUsingLSP {
                preprocessorCheckBox.isEnabled = false
                preprocessorTextField.isEnabled = false
            }
            preprocessorTextField.stringValue = s.isPreprocessorDefined || s.specialPreprocessor == nil ? s.preprocessor : s.specialPreprocessor ?? ""
            preprocessorWarningImageView.isHidden = s.preprocessor.isEmpty || s.preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) != nil
            gridView.cell(for: preprocessorTextField)?.row?.isHidden = !self.isAdvancedSettingsVisible
            
            updateCheckbox(syntaxCheckBox, s.isSyntaxDefined, [syntaxPopupButton])
            let stx = s.isSyntaxDefined || s.specialSyntax == nil ? s.syntax : s.specialSyntax ?? ""
            let keys = Array(availableSyntax.keys.sorted(by: {$0.compare($1, options: .caseInsensitive) == .orderedAscending }))
            
            if let i = keys.firstIndex(where: { availableSyntax[$0]?.extensions.contains(stx) ?? false }) {
                syntaxPopupButton.selectItem(at: i + 2)
            } else {
                syntaxPopupButton.selectItem(at: 0)
            }
            
            gridView.cell(for: syntaxPopupButton)?.row?.isHidden = !self.isAdvancedSettingsVisible
            
            gridView.cell(for: lspButton)?.row?.isHidden = !self.isAdvancedSettingsVisible
            lspButton.isEnabled = true
            lspButton.image = s.LSPImage
        } else {
            gridView.cell(for: arguments2TextField)?.row?.isHidden = true
            gridView.cell(for: preprocessorTextField)?.row?.isHidden = true
            gridView.cell(for: syntaxPopupButton)?.row?.isHidden = true
            gridView.cell(for: lspButton)?.row?.isHidden = true
            preprocessorWarningImageView.isHidden = true
            lspButton.image = NSImage(named: NSImage.statusNoneName)
        }
        
        updateCheckbox(customCSSCheckBox, settings.isCSSDefined, [customCSSButton])
        customCSSButton.isEnabled = settings.isCSSDefined && settings.format == .html
        customCSSButton.image = NSImage(named: settings.css.isEmpty ? NSImage.statusNoneName : NSImage.statusAvailableName)
        updateCheckbox(interactiveCheckBox, settings.isAllowInteractiveActionsDefined, [interactiveSwitch])
        interactiveSwitch.state = settings.allowInteractiveActions ? .on : .off
        
        if let settings = settings as? Settings {
            debugSwitch.isEnabled = true
            debugSwitch.state = settings.isDebug ? .on : .off
            gridView.cell(for: debugSwitch)?.row?.isHidden = !self.isAdvancedSettingsVisible
            
            EOLSwitch.isEnabled = true
            EOLSwitch.state = settings.convertEOL ? .on : .off
            gridView.cell(for: EOLSwitch)?.row?.isHidden = !self.isAdvancedSettingsVisible
            
            dataLimitTextField.isEnabled = true
            dataLimitPopupButton.isEnabled = true
            
            let size = settings.maxData / 1024 // Convert Bytes to KB.
            if size % 1024 == 0 {
                dataLimitTextField.intValue = Int32(size / 1024)
                dataLimitPopupButton.selectItem(at: 1)
            } else {
                dataLimitTextField.intValue = Int32(size)
                dataLimitPopupButton.selectItem(at: 0)
            }
            gridView.cell(for: dataLimitTextField)?.row?.isHidden = false
        } else {
            gridView.cell(for: debugSwitch)?.row?.isHidden = true
            gridView.cell(for: EOLSwitch)?.row?.isHidden = true
            gridView.cell(for: dataLimitTextField)?.row?.isHidden = true
        }
        
        gridView.cell(for: advancedWarning)?.row?.isHidden = isAdvancedSettingsVisible || !settings.hasAdvancedSettings
        
        updateAppearanceWarning()
        
        return true
    }
    
    internal func updateAppearanceWarning() {
        guard let settings = self.settings, settings.format == .rtf  else {
            appearanceAlertButton.isHidden = true
            return
        }
        if (settings as? SettingsFormat)?.LSPRequireHTML ?? false {
            appearanceAlertButton.isHidden = false
        } else if settings.isFormatDefined, settings.isLightThemeNameDefined, let theme = HighlightWrapper.shared.getTheme(name: settings.lightThemeName), theme.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)) {
            appearanceAlertButton.isHidden = false
        } else if settings.isFormatDefined, settings.isDarkThemeNameDefined, let theme = HighlightWrapper.shared.getTheme(name: settings.darkThemeName), theme.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)) {
            appearanceAlertButton.isHidden = false
        } else {
            appearanceAlertButton.isHidden = true
        }
    }
    
    internal func updateLineNumberPopup() {
        guard let settings = self.settings else {
            lineNumbersPopupButton.isEnabled = false
            lineNumbersPopupButton.item(at: 0)?.title = ""
            return
        }
        
        lineNumbersPopupButton.isEnabled = settings.isLineNumbersDefined
        // off
        lineNumbersPopupButton.menu?.item(withTag: 0)?.state = settings.isLineNumbersVisible ? .off : .on
        
        // on
        lineNumbersPopupButton.menu?.item(withTag: 1)?.state = settings.isLineNumbersVisible ? .on : .off
        
        // omit
        lineNumbersPopupButton.menu?.item(withTag: 2)?.isEnabled = settings.isLineNumbersVisible && settings.isWordWrapped && settings.isWordWrappedHard
        lineNumbersPopupButton.menu?.item(withTag: 2)?.state = settings.isLineNumbersOmittedForWrap ? .on : .off
        
        // zeroes
        lineNumbersPopupButton.menu?.item(withTag: 3)?.isEnabled = settings.isLineNumbersVisible
        lineNumbersPopupButton.menu?.item(withTag: 3)?.state = settings.isLineNumbersFillToZeroes ? .on : .off
        
        lineNumbersPopupButton.item(at: 0)?.title = lineNumbersPopupButton.menu?.item(withTag: settings.isLineNumbersVisible ? 1 : 0)?.title ?? (settings.isLineNumbersVisible ? "on" : "off")
    }
    
    @IBAction func onAppearanceChanged(_ sender: Any) {
        gridView.cell(for: interactiveSwitch)?.row?.isHidden = !self.isAdvancedSettingsVisible || appearancePopupButton.indexOfSelectedItem == 0
        interactiveSwitch.isEnabled = appearancePopupButton.indexOfSelectedItem != 0
        
        gridView.cell(for: customCSSButton)?.row?.isHidden = !self.isAdvancedSettingsVisible || appearancePopupButton.indexOfSelectedItem == 0
        
        settings?.format = appearancePopupButton.indexOfSelectedItem == 0 ? .rtf : .html
        customCSSButton.isEnabled = appearancePopupButton.indexOfSelectedItem != 0
        if let settings = self.settings as? SettingsFormat {
            customCSSButton.isEnabled = customCSSButton.isEnabled && settings.isCSSDefined
        }
        updateAppearanceWarning()
    }
    
    internal func updateWordWrapPopup() {
        guard let settings = self.settings else {
            wordWrapPopupButton.isEnabled = false
            wordWrapPopupButton.item(at: 0)?.title = ""
            return
        }
        var mnu: NSMenuItem?
        
        wordWrapPopupButton.isEnabled = settings.isWordWrapDefined
        // off
        wordWrapPopupButton.menu?.item(withTag: 0)?.state = settings.isWordWrapped ? .off : .on
        
        // hard
        wordWrapPopupButton.menu?.item(withTag: 1)?.state = (settings.isWordWrapped && settings.isWordWrappedHard) ? .on : .off
        // soft
        wordWrapPopupButton.menu?.item(withTag: 3)?.state = (settings.isWordWrapped && !settings.isWordWrappedHard) ? .on : .off
        
        // indented
        mnu = wordWrapPopupButton.menu?.item(withTag: 2)
        mnu?.isEnabled = settings.isWordWrapped && settings.isWordWrappedHard
        mnu?.state = settings.isWordWrappedIndented ? .on : .off
        
        // Only one line file
        mnu = wordWrapPopupButton.menu?.item(withTag: 4)
        mnu?.isEnabled = !settings.isWordWrapped
        mnu?.state = settings.isWordWrappedSoftForOnleLineFiles ? .on : .off
        
        if settings.isWordWrapped {
            wordWrapPopupButton.item(at: 0)?.title = wordWrapPopupButton.menu?.item(withTag: settings.isWordWrappedHard ? 1 : 3)?.title ?? "on"
        } else if settings.isWordWrappedSoftForOnleLineFiles {
            wordWrapPopupButton.item(at: 0)?.title = "Enabled only for one line file"
        } else {
            wordWrapPopupButton.item(at: 0)?.title = wordWrapPopupButton.menu?.item(withTag: 0)?.title ?? "off"
        }
    }
    
    @IBAction func onWordWrapChanged(_ sender: NSPopUpButton) {
        self.settings?.lockRefresh()
        
        switch sender.selectedTag() {
        case 0: // off
            settings?.isWordWrapped = false
        case 1: // on, hard
            settings?.isWordWrapped = true
            settings?.isWordWrappedHard = true
        case 3: // on, soft
            settings?.isWordWrapped = true
            settings?.isWordWrappedHard = false
        case 2: // indented
            settings?.isWordWrappedIndented = !(settings?.isWordWrappedIndented ?? true)
        case 4: // one line file
            settings?.isWordWrappedSoftForOnleLineFiles = !(settings?.isWordWrappedSoftForOnleLineFiles ?? true)
        default:
            break
        }
        updateWordWrapPopup()
        
        lineLengthTextField.isEnabled = (settings?.isWordWrapDefined ?? false) && (settings?.isWordWrapped ?? false) && (settings?.isWordWrappedHard ?? false)
        lineLengthStepper.isEnabled = lineLengthTextField.isEnabled
        lineLengthLabel.textColor = lineLengthTextField.isEnabled ? .labelColor : .disabledControlTextColor
        
        updateLineNumberPopup()
        self.settings?.unlockRefresh()
    }
    @IBAction func onLineLengthChanged(_ sender: Any) {
        lineLengthStepper.integerValue = lineLengthTextField.integerValue
        settings?.lineLength = lineLengthTextField.integerValue
    }
    @IBAction func onLineLengthStepperChanged(_ sender: NSStepper) {
        lineLengthTextField.integerValue = sender.integerValue
        settings?.lineLength = lineLengthTextField.integerValue
    }
    
    @IBAction func onLineNumbersChanged(_ sender: NSPopUpButton) {
        switch sender.selectedTag() {
        case 0: // off
            settings?.isLineNumbersVisible = false
        case 1: // on
            settings?.isLineNumbersVisible = true
        case 2: // omit
            settings?.isLineNumbersOmittedForWrap = !(settings?.isLineNumbersOmittedForWrap ?? false)
        case 3: // zeroes
            settings?.isLineNumbersFillToZeroes = !(settings?.isLineNumbersFillToZeroes ?? true)
        default:
            break
        }
        updateLineNumberPopup()
    }
    
    @IBAction func onTabSpacesChanged(_ sender: Any) {
        settings?.tabSpaces = self.spacesSliderView.integerValue
    }
    
    @IBAction func onArgumentsChanged(_ sender: Any) {
        settings?.arguments = self.argumentsTextField.stringValue
    }
    @IBAction func onAppendArgumentsChanged(_ sender: Any) {
        if let settings = self.settings as? SettingsFormat {
            settings.appendArguments = self.arguments2TextField.stringValue
        }
    }
    @IBAction func onPreprocessorChanged(_ sender: Any) {
        if let settings = self.settings as? SettingsFormat {
            settings.preprocessor = self.preprocessorTextField.stringValue
            self.preprocessorWarningImageView.isHidden = settings.preprocessor.isEmpty || settings.preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) != nil
        }
    }
    @IBAction func onSyntaxChanged(_ sender: Any) {
        if let settings = self.settings as? SettingsFormat {
            if syntaxPopupButton.indexOfSelectedItem > 0 {
                let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
                let desc = String(keys[syntaxPopupButton.indexOfSelectedItem - 2])
                if let `extension` = availableSyntax[desc]?.extensions.first {
                    settings.syntax = `extension`
                }
            } else {
                settings.syntax = ""
            }
        }
    }
    
    @IBAction func handleCSSButton(_ sender: Any) {
        guard let vc = NSStoryboard(name: "Storyboard", bundle: nil).instantiateController(withIdentifier: "CustomStyleEditor") as? CSSControlViewController else {
            return
        }
        vc.mode = settings is SettingsFormat ? .format : .global
        vc.cssCode = settings?.css ?? ""
        vc.handler = { [weak self] (css, _, status) in
            if status {
                self?.settings?.css = css
                self?.customCSSButton.image = NSImage(named: css.isEmpty ? NSImage.statusNoneName : NSImage.statusAvailableName)
            }
        }
        self.window?.contentViewController?.presentAsSheet(vc)
    }
    
    @IBAction func handleLSPButton(_ sender: NSButton) {
        guard let settings = self.settings as? SettingsFormat, let vc = NSStoryboard(name: "Storyboard", bundle: nil).instantiateController(withIdentifier: "LSPViewController") as? LSPViewController else {
            return
        }
        vc.settings = settings
        vc.onDismiss = { [weak self] in 
            self?.lspButton.image = settings.LSPImage
            if settings.isUsingLSP {
                self?.preprocessorTextField.isEnabled = false
                self?.preprocessorCheckBox.isEnabled = false
            } else {
                self?.preprocessorTextField.isEnabled = settings.isPreprocessorDefined
                self?.preprocessorCheckBox.isEnabled = true
            }
            self?.updateAppearanceWarning()
        }
        self.window?.contentViewController?.present(vc, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY, behavior: .semitransient)
    }
    
    @IBAction func onInteractiveChanged(_ sender: Any) {
        settings?.allowInteractiveActions = self.interactiveSwitch.state == .on
    }
    
    @IBAction func onDataLimitChanged(_ sender: Any) {
        if let settings = self.settings as? Settings {
            var dataSize = self.dataLimitTextField.floatValue
            if self.dataLimitPopupButton.indexOfSelectedItem == 1 {
                dataSize *= 1024 // Convert MB to KB.
            }
            dataSize *= 1024 // Convert KB to Bytes.
            settings.maxData = UInt64(dataSize)
        }
    }
    
    @IBAction func onEOLChanged(_ sender: Any) {
        if let settings = self.settings as? Settings {
            settings.convertEOL = self.EOLSwitch.state == .on
        }
    }
    
    @IBAction func onDebugChanged(_ sender: Any) {
        if let settings = self.settings as? Settings {
            settings.isDebug = self.debugSwitch.state == .on
        }
    }
    
    /// Show panel to chose a new font.
    @IBAction func chooseFont(_ sender: NSButton) {
        let storyboard = NSStoryboard(name: "Storyboard", bundle: nil)
        if let vc = storyboard.instantiateController(withIdentifier: "FontSelector") as? FontSelectorViewController {
            vc.fontSize = self.settings?.fontSize ?? NSFont.systemFontSize
            vc.fontName = self.settings?.fontName ?? "-"
            vc.handler = {[weak self] (family, size, browse) in
                if browse {
                    self?.browseForFont()
                    return
                }
                
                self?.settings?.lockRefresh()
                
                self?.refreshFontPanel(withFontFamily: family, size: size)
                
                self?.settings?.fontName = family
                self?.settings?.fontSize = size
                self?.settings?.unlockRefresh()
            }
            self.window?.contentViewController?.present(vc, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: .maxY, behavior: .transient)
        } else {
            browseForFont()
        }
    }
    
    func browseForFont() {
        let fontPanel = NSFontPanel.shared
        fontPanel.worksWhenModal = true
        fontPanel.becomesKeyOnlyIfNeeded = true
        
        let fontFamily: String  = self.settings?.fontName ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular).fontName
        let fontSize = self.settings?.fontSize ?? NSFont.systemFontSize
        
        if fontFamily != "-", let font = NSFont(name: fontFamily, size: fontSize) {
            fontPanel.setPanelFont(font, isMultiple: false)
        }
        
        self.window?.makeFirstResponder(self)
        fontPanel.makeKeyAndOrderFront(self)
    }
    
    @IBAction func handleAppearanceCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isFormatDefined = sender.state == .on
        appearancePopupButton.isEnabled = sender.state == .on
    }
    
    @IBAction func handleLineNumbersCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isLineNumbersDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handleTabSpacesCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isTabSpacesDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handleArgumentsCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isArgumentsDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handleAppendArgumentsCheckbox(_ sender: NSButton) {
        guard let settings = self.settings as? SettingsFormat else { return }
        settings.isAppendArgumentsDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handlePreprocessorCheckbox(_ sender: NSButton) {
        guard let settings = self.settings as? SettingsFormat else { return }
        settings.isPreprocessorDefined = sender.state == .on
        self.preprocessorTextField.isEnabled = sender.state == .on && !settings.isUsingLSP
    }
    @IBAction func handleSyntaxCheckbox(_ sender: NSButton) {
        guard let settings = self.settings as? SettingsFormat else { return }
        settings.isSyntaxDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handleCustomCssCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isCSSDefined = sender.state == .on
        handleCheckbox(sender)
    }
    @IBAction func handleInteractiveCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        settings?.isAllowInteractiveActionsDefined = sender.state == .on
        handleCheckbox(sender)
    }
    
    @IBAction func handleThemeEditor(_ sender: NSMenuItem) {
        let theme: String?
        if sender.tag == 1 {
            theme = self.settings?.lightThemeName
        } else if sender.tag == 2 {
            theme = self.settings?.darkThemeName
        } else {
            theme = nil
        }
        if let name = theme {
            self.settingsController?.editTheme(name: name)
        }
    }
    
    internal func handleCheckbox(_ sender: NSButton) {
        guard settings is SettingsFormat, let control = gridView.cell(for: sender)?.row?.cell(at: 1).contentView as? NSControl else {
            return
        }
        control.isEnabled = sender.state == .on
    }
    
    @IBAction func handleThemesCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        self.settings?.lockRefresh()
        settings?.isLightThemeNameDefined = sender.state == .on
        settings?.isDarkThemeNameDefined = sender.state == .on
        self.settings?.unlockRefresh()
        
        themeLightButton.isEnabled = sender.state == .on
        themeDarkButton.isEnabled = sender.state == .on
    }
    @IBAction func handleWordWrapCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        self.settings?.lockRefresh()
        settings?.isWordWrapDefined = sender.state == .on
        settings?.isLineLengthDefined = sender.state == .on
        self.settings?.unlockRefresh()
        wordWrapPopupButton.isEnabled = sender.state == .on
        lineLengthTextField.isEnabled = sender.state == .on && (settings?.isWordWrapped ?? false) && (settings?.isWordWrappedHard ?? false)
        lineLengthStepper.isEnabled = lineLengthTextField.isEnabled
        lineLengthLabel.textColor = lineLengthTextField.isEnabled ? .labelColor : .disabledControlTextColor
    }
    @IBAction func handleFontCheckbox(_ sender: NSButton) {
        guard let _ = self.settings as? SettingsFormat else { return }
        self.settings?.lockRefresh()
        settings?.isFontSizeDefined = sender.state == .on
        settings?.isFontNameDefined = sender.state == .on
        self.settings?.unlockRefresh()
        fontButton.isEnabled = sender.state == .on
        fontLabel.isEnabled = sender.state == .on
    }
    
    @IBAction func handleThemeButton(_ sender: Any) {
        guard let button = sender as? NSButton, button==themeLightButton || button==themeDarkButton else {
            return
        }
        
        let storyboard = NSStoryboard(name: "Storyboard", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ThemeSelector") as? ThemeSelectorViewController else {
            return
        }
        if button == themeLightButton {
            vc.style = .light
            vc.handler = { [weak self] theme in
                if let self = self {
                    self.settings?.lockRefresh()
                    self.settings?.isLightThemeNameDefined = true
                    self.settings?.lightBackgroundColor = theme.backgroundColor
                    self.settings?.lightThemeName = theme.nameForSettings
                    self.settings?.unlockRefresh()
                    self.initTheme(theme, label: self.themeLightLabel, button: button)
                    self.updateAppearanceWarning()
                }
            }
        } else if button == themeDarkButton {
            vc.style = .dark
            vc.handler = { [weak self] theme in
                if let self = self {
                    self.settings?.lockRefresh()
                    self.settings?.isDarkThemeNameDefined = true
                    self.settings?.darkBackgroundColor = theme.backgroundColor
                    self.settings?.darkThemeName = theme.nameForSettings
                    self.settings?.unlockRefresh()
                    self.initTheme(theme, label: self.themeDarkLabel, button: button)
                    self.updateAppearanceWarning()
                }
            }
        }
        self.window?.contentViewController?.present(vc, asPopoverRelativeTo: button.bounds, of: button, preferredEdge: .maxY, behavior: .transient)
    }
    
    @IBAction func handleShowAdvanced(_ sender: Any) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.isAdvancedSettingsVisible = !appDelegate.isAdvancedSettingsVisible
        }
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFont font: NSFont) {
        let ff: String
        if font.fontName == NSFont.monospacedSystemFont(ofSize: 0, weight: .regular).fontName {
            ff = "System font"
        } else if let s = font.displayName {
            ff = s
        } else if let s = font.familyName {
            ff = s
        } else {
            ff = font.fontName
        }
        
        let fp = font.pointSize
        
        fontLabel.stringValue = String(format:"%@, %.1f pt", ff, fp)
        fontLabel.font = font
    }
    
    /// Refresh the preview font.
    func refreshFontPanel(withFontFamily font: String, size: CGFloat) {
        if font == "-" {
            self.refreshFontPanel(withFont: NSFont.monospacedSystemFont(ofSize: size, weight: .regular))
        } else if let f = NSFont(name: font, size: size) {
            self.refreshFontPanel(withFont: f)
        }
    }
    
    @IBAction func handleApperanceButton(_ sender: Any) {
        guard let settings = self.settings else {
            return
        }
        
        let lsp = (settings as? SettingsFormat)?.LSPRequireHTML ?? false
        let theme: Bool
        
        if settings.isFormatDefined, settings.isLightThemeNameDefined, HighlightWrapper.shared.getTheme(name: settings.lightThemeName)?.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)) ?? false {
            theme = false
        } else if settings.isFormatDefined, settings.isDarkThemeNameDefined, HighlightWrapper.shared.getTheme(name: settings.darkThemeName)?.isRequireHTMLEngine(ignoringLSTokens: !((NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false)) ?? false {
            theme = true
        } else {
            theme = false
        }
        
        let alert = NSAlert()
        if lsp && theme {
            alert.messageText = "For a best view some selected Color scheme or the Language Server options may require the HTML render engine."
        } else if theme {
            alert.messageText = "For a best view a selected Color scheme may require the HTML render engine."
        } else if lsp {
            alert.messageText = "For a best view some Language Server options may require the HTML render engine."
        } else {
            return
        }
        
        alert.addButton(withTitle: "Close").keyEquivalent = "\u{1b}"
        alert.runModal()
    }
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            NSHelpManager.shared.openHelpAnchor(self.settings is SettingsFormat ? "SyntaxHighlight_FORMAT_PREFERENCES" : "SyntaxHighlight_GLOBAL_PREFERENCES", inBook: locBookName)
        }
    }
}

// MARK: - NSFontChanging
extension SettingsView: NSFontChanging {
    /// Handle the selection of a font.
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let font = fontManager.convert(NSFont.systemFont(ofSize: 13.0))
        
        refreshFontPanel(withFont: font)
        
        self.settings?.lockRefresh()
        self.settings?.fontName = font.fontName
        self.settings?.fontSize = font.pointSize
        self.settings?.unlockRefresh()
        // self.refresh(self)
    }
    
    /// Customize font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask
    {
        return [.collection, .face, .size]
    }
}
