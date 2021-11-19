//
//  SettingsSplitViewController.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 05/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import AVFoundation

protocol SettingsSplitElement: NSViewController {
    var settingsController: SettingsSplitViewController? { get }
    
    var previewView: PreviewView? { get }
    var mainViewController: MainViewController? { get }
    var themeEditView: ThemeEditorView? { get }
}

extension SettingsSplitElement {
    var settingsController: SettingsSplitViewController? {
        return self.view.window?.windowController?.contentViewController as? SettingsSplitViewController
    }
    
    var previewView: PreviewView? {
        return (settingsController?.previewItem.viewController as? PreviewViewController)?.previewView
    }
    
    var mainViewController: MainViewController? {
        return settingsController?.mainItem.viewController as? MainViewController
    }
    
    var themeEditView: ThemeEditorView? {
        return mainViewController?.themeView
    }
}

protocol SettingsSplitViewElement: NSView {
    var settingsController: SettingsSplitViewController? { get }
    var previewView: PreviewView? { get }
    var mainViewController: MainViewController? { get }
    var themeEditView: ThemeEditorView? { get }
}

extension SettingsSplitViewElement {
    var settingsController: SettingsSplitViewController? {
        return self.window?.windowController?.contentViewController as? SettingsSplitViewController
    }
    
    var previewView: PreviewView? {
        return (settingsController?.previewItem.viewController as? PreviewViewController)?.previewView
    }
    
    var mainViewController: MainViewController? {
        return settingsController?.mainItem.viewController as? MainViewController
    }
    
    var themeEditView: ThemeEditorView? {
        return mainViewController?.themeView
    }
}

class SettingsSplitWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    override func windowDidLoad() {
        self.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "GeneralButton")
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return false
    }
}

class SettingsSplitViewController: NSSplitViewController {
    enum Mode {
        case global
        case custom
        case theme
        case plain
    }
    
    @IBOutlet weak var listItem: NSSplitViewItem!
    @IBOutlet weak var mainItem: NSSplitViewItem!
    @IBOutlet weak var previewItem: NSSplitViewItem!
    
    @IBAction func performClose(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    var mode: Mode = .global {
        didSet {
            if let mainController = mainItem.viewController as? MainViewController {
                mainController.mode = mode
            }
            listItem.isCollapsed = mode == .global || mode == .plain
            // previewItem.isCollapsed = mode == .plain // FIXME: cambia il colore della barra del titolo!
            
            if let listController = listItem.viewController as? ListViewController {
                switch mode {
                case .global:
                    listController.mode = .format
                    self.view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "GeneralButton")
                case .custom:
                    listController.mode = .format
                    self.view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "FormatsButton")
                case .theme:
                    listController.mode = .theme
                    self.view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "ColorsButton")
                case .plain:
                    listController.mode = .plain
                    self.view.window?.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "PlainButton")
                    (previewItem?.viewController as? PreviewViewController)?.previewView.settings = nil
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .SettingsAvailable, object: nil)
        NotificationCenter.default.removeObserver(self, name: .SettingsIsDirty, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: .CustomThemeAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .ThemeIsDirty, object: nil)
    }
    
    @IBAction func showGlobalSettings(_ sender: Any) {
        self.mode = .global
    }
    
    @IBAction func showCustomSettings(_ sender: Any) {
        self.mode = .custom
    }
    
    @IBAction func showColorsEditor(_ sender: Any) {
        self.mode = .theme
    }
    
    @IBAction func showPlainEditor(_ sender: Any) {
        self.mode = .plain
    }
    
    @IBAction func refreshPreview(_ sender: Any) {
        (previewItem?.viewController as? PreviewViewController)?.previewView.refreshPreview()
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Are you sure to revert to the original saved settings?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes") // .keyEquivalent = "\r"
        alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
        alert.beginSheetModal(for: self.view.window!) { result in
            guard result == .alertFirstButtonReturn else {
                return
            }
            
            HighlightWrapper.shared.reloadThemes()
            SCSHWrapper.shared.reloadSettings { (wrapper, success) in
                guard success else {
                    let alert = NSAlert()
                    alert.messageText = "Unable to reset the settings."
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "Done")
                    alert.runModal()
                    return
                }
                
                if let listController = self.listItem.viewController as? ListViewController {
                    listController.themesListView.allThemes = HighlightWrapper.shared.themes
                    listController.UTIsListView.outlineView.reloadData()
                }
                
                if let mainController = self.mainItem.viewController as? MainViewController {
                    mainController.globalSettings = wrapper.settings
                    mainController.customSettings = nil
                    if let name = mainController.themeView.theme?.nameForSettings, let theme = HighlightWrapper.shared.getTheme(name: name) {
                        mainController.themeView.theme = theme
                    } else {
                        mainController.themeView.theme = nil
                    }
                    mainController.plainSettingsView.initSettings()
                }
                
                self.view.window?.isDocumentEdited = SCSHWrapper.shared.isDirty
            }
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.closable)
        
        do {
            try HighlightWrapper.shared.saveThemes()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to save some themes."
            alert.informativeText = "Settings are not saved (\(error.localizedDescription))."
            alert.addButton(withTitle: "Close")
            alert.alertStyle = .critical
            alert.runModal()
            
            self.view.window?.styleMask.insert(NSWindow.StyleMask.closable)
            return
        }
        
        SCSHWrapper.shared.saveSettings { (state) in
            DispatchQueue.main.async {
                //self.saveButton.isEnabled = true
                //self.cancelButton.isEnabled = true
                self.view.window?.styleMask.insert(NSWindow.StyleMask.closable)
                
                self.view.window?.isDocumentEdited = !state
            }
            
            guard state else {
                let alert = NSAlert()
                alert.messageText = "Unable to save the settings."
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .critical
                alert.runModal()
                return
            }
            if SCSHWrapper.shared.settings?.isDebug ?? false {
                let alert = NSAlert()
                alert.messageText = "Settings saved."
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .informational
                alert.runModal()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mode = .global
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDirty(_:)), name: .CustomThemeAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDirty(_:)), name: .ThemeIsDirty, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDirty(_:)), name: .SettingsIsDirty, object: nil)
        
        if !SCSHWrapper.shared.isSettingsLoaded {
            NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsAvailable(_:)), name: NSNotification.Name.SettingsAvailable, object: nil)
        } else {
            initSettings()
        }
    }
    
    @objc internal func handleSettingsAvailable(_ notification: Notification) {
        initSettings()
    }
    
    @objc internal func handleDirty(_ notification: Notification) {
        guard let settings = notification.object as? SettingsBase, !(settings is SettingsRendering) else {
            return
        }
        if settings is Settings && SCSHWrapper.shared.settings != settings {
            return
        }
        if let s = settings as? SettingsFormat, SCSHWrapper.shared.settings?.utiSettings[s.uti] != s {
            return
        }
        self.view.window?.isDocumentEdited = true
    }
    
    func editTheme(name: String) {
        guard let theme = HighlightWrapper.shared.getTheme(name: name) else {
            return
        }
        if let listController = self.listItem.viewController as? ListViewController {
            listController.themesListView.theme = theme
        }
        self.mode = .theme
    }
    
    func selectUTI(_ uti: UTI?) {
        if let _ = uti, self.mode != .custom {
            self.mode = .custom
        }
        (mainItem.viewController as? MainViewController)?.uti = uti
        (listItem.viewController as? ListViewController)?.UTIsListView.selectUTI(uti)
    }
    
    internal func initSettings() {
        (self.previewItem?.viewController as? PreviewViewController)?.previewView.settings = SCSHWrapper.shared.settings
        NotificationCenter.default.removeObserver(self, name: .SettingsAvailable, object: nil)
    }
    
    @IBAction func performFindPanelAction(_ sender: Any) {
        switch mode {
        case .global, .plain:
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
            return
        case .custom:
            if let listController = self.listItem.viewController as? ListViewController {
                self.view.window?.makeFirstResponder(listController.UTIsListView.searchField)
            }
        case .theme:
            if let listController = self.listItem.viewController as? ListViewController {
                self.view.window?.makeFirstResponder(listController.themesListView.searchField)
            }
        }
    }
    
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
}

class SettingsTabViewController: NSTabViewController {
    
}


class MainViewController: NSViewController, SettingsDelegate, SettingsSplitElement {
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var globalSettingsView: SettingsView!
    
    @IBOutlet weak var customSettingsView: SettingsView!
    @IBOutlet weak var plainSettingsView: PlainSettingsView!
    
    @IBOutlet weak var UTIIconView: NSImageView!
    @IBOutlet weak var UTIImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var UTIDescriptionLabel: NSTextField!
    @IBOutlet weak var UTINameButton: NSButton!
    @IBOutlet weak var UTIExtensionsLabel: NSTextField!
    @IBOutlet weak var UTIWarningButton: NSButton!
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var themeView: ThemeEditorView!
    
    var mode: SettingsSplitViewController.Mode = .global {
        didSet {
            switch mode {
            case .global:
                tabView.selectTabViewItem(at: 0)
                previewView?.settings = globalSettingsView.settings
                self.resignFirstResponder()
                globalSettingsView.appearancePopupButton.becomeFirstResponder()
                
            case .custom:
                tabView.selectTabViewItem(at: 1)
                
                self.resignFirstResponder()
                customSettingsView.appearancePopupButton.becomeFirstResponder()
                initUTI()
                
            case .theme:
                tabView.selectTabViewItem(at: 2)
                themeView.requestPreviewRefresh()
                self.resignFirstResponder()
            
            case .plain:
                tabView.selectTabViewItem(at: 3)
                self.resignFirstResponder()
            }
        }
    }
    
    var globalSettings: SettingsBase? {
        didSet {
            oldValue?.delegate = nil
            globalSettings?.delegate = self
            /*
            if let o = oldValue {
                o.removeObserver(self, forKeyPath: "needRefresh")
            }
            if let s = globalSettings {
                s.addObserver(self, forKeyPath: "needRefresh", options: NSKeyValueObservingOptions.new, context: nil)
            }
            */
            self.globalSettingsView.settings = globalSettings
        }
    }
    
    var uti: UTI? {
        didSet {
            initUTI()
        }
    }
    
    var customSettings: SettingsFormat? {
        didSet {
            oldValue?.delegate = nil
            
            messageLabel.isHidden = customSettings != nil
            self.customSettingsView.isHidden = customSettings == nil
            self.customSettingsView.settings = customSettings
            
            customSettings?.delegate = self
            previewView?.settings = customSettings
        }
    }
    
    override func viewDidLoad() {
        initUTI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handledAdvancedSettings(_:)), name: .AdvancedSettings, object: nil)
        
        if !SCSHWrapper.shared.isSettingsLoaded || !initSettings() {
            NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsAvailable(_:)), name: NSNotification.Name.SettingsAvailable, object: nil)
        }
        
        let advancedSettings = (NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible ?? false
        globalSettingsView.isAdvancedSettingsVisible = advancedSettings
        customSettingsView.isAdvancedSettingsVisible = advancedSettings
        themeView.isAdvancedSettingsVisible = advancedSettings
        
        customSettingsView.hideItemsForCustomSettings()
        
        self.resignFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .SettingsAvailable, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AdvancedSettings, object: nil)
        
        // globalSettings?.removeObserver(self, forKeyPath: "needRefresh")
        // customSettings?.removeObserver(self, forKeyPath: "needRefresh")
    }
    
    @objc internal func handleSettingsAvailable(_ notitication: Notification) {
        if initSettings() {
            NotificationCenter.default.removeObserver(self, name: .SettingsAvailable, object: nil)
        }
    }
    
    func settingsIsChanged(_ settings: SettingsBase) {
        if settings == self.globalSettings || settings == self.customSettings {
            previewView?.settings = settings
        }
    }
    
    @discardableResult
    func initSettings() -> Bool {
        // (NSApplication.shared.delegate as? AppDelegate)?.isAdvancedSettingsVisible = SCSHWrapper.shared.isAdvancedSettingsUsed()
        
        self.globalSettings = SCSHWrapper.shared.settings
        
        guard let _ = self.globalSettings else {
            return false
        }
        
        initUTI()
        
        if mode == .custom, let uti = self.uti {
            self.customSettings = SCSHWrapper.shared.settings?.utiSettings[uti.UTI] ?? SCSHWrapper.shared.createSettings(forUTI: uti.UTI)
        }
        
        return true
    }
    
    func initUTI() {
        if let uti = self.uti {
            messageLabel.isHidden = true
            uti.fetchIcon(async: false)
            UTIIconView.image = uti.image
            UTIImageWidthConstraint.constant = UTIIconView.image == nil ? 0 : 32
            UTIIconView.isHidden = false
            UTIDescriptionLabel.stringValue = uti.description
            UTIDescriptionLabel.isHidden = false
            UTINameButton.title = uti.UTI
            UTINameButton.isHidden = false
            UTIExtensionsLabel.stringValue = "." + uti.extensions.joined(separator: ", .")
            UTIExtensionsLabel.isHidden = false
            UTIWarningButton.isHidden = uti.isValid && !uti.isSuppressed
            
            if !SCSHWrapper.shared.isSettingsLoaded {
                NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsAvailable(_:)), name: NSNotification.Name.SettingsAvailable, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .SettingsAvailable, object: nil)
                var s = SCSHWrapper.shared.settings?.utiSettings[uti.UTI]
                if s == nil {
                    s = SCSHWrapper.shared.createSettings(forUTI: uti.UTI)
                }
                self.customSettings = s
            }
        } else {
            self.customSettings = nil
            UTIWarningButton.isHidden = true
            UTIIconView.isHidden = true
            UTIDescriptionLabel.isHidden = true
            UTINameButton.isHidden = true
            UTIExtensionsLabel.isHidden = true
        }
    }
    
    @objc func handledAdvancedSettings(_ notification: Notification) {
        if let state = notification.object as? Bool {
            globalSettingsView.isAdvancedSettingsVisible = state
            customSettingsView.isAdvancedSettingsVisible = state
            themeView.isAdvancedSettingsVisible = state
            
            previewView?.refreshPreview()
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "WarningUTI", let vc = segue.destinationController as? WarningUTIViewController, let fileTypes = (NSApplication.shared.delegate as? AppDelegate)?.handledUTIs {
            vc.data = fileTypes.first(where: { $0.UTI == self.uti?.UTI })?.getSuppressedExtensions(handledUti: fileTypes.map( { $0.UTI } )) ?? []
        } else if segue.identifier == "UTIInfo", let vc = segue.destinationController as? UTIInfoViewController, let fileTypes = (NSApplication.shared.delegate as? AppDelegate)?.handledUTIs {
            guard let format = fileTypes.first(where: { $0.UTI == self.uti?.UTI }) else {
                return
            }
            
            vc.uti = format
        }
    }
}


class ListViewController: NSViewController {
    enum Mode {
        case format
        case theme
        case plain
    }
    @IBOutlet weak var UTIsListView: UTIsListView!
    @IBOutlet weak var themesListView: ThemesListView!
    
    var mode: Mode = .format {
        didSet {
            guard oldValue != mode else {
                return
            }
            UTIsListView.isHidden = mode == .theme || mode == .plain
            themesListView.isHidden = mode == .format || mode == .plain
        }
    }
}
