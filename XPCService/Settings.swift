//
//  Settings.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 05/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

protocol SettingsDelegate: AnyObject {
    func settingsIsChanged(_ settings: SettingsBase)
}

typealias ThemeBaseColor = (name: String, background: String, foreground: String)

// MARK: -
class SettingsBase: NSObject {
    /// Output format.
    enum Format: String {
        case html
        case rtf
    }
    
    public struct Key {
        static let format = "format"
        
        static let lightTheme = "theme-light"
        static let lightBackgroundColor = "theme-light-color"
        static let lightForegroundColor = "theme-light-fg-color"
        static let darkTheme = "theme-dark"
        static let darkBackgroundColor = "theme-dark-color"
        static let darkForegroundColor = "theme-dark-fg-color"
        
        static let theme = "theme"
        static let backgroundColor = "theme-color"
        static let foregroundColor = "theme-fg-color"
        static let themeLua = "theme-lua"
        
        static let lineNumbers = "line-numbers"
        static let lineNumbersFillToZeroes = "line-fill-zero"
        
        static let wordWrap = "word-wrap"
        static let wordWrapHard = "word-wrap-hard"
        static let wordWrapOneLineFiles = "word-wrap-one-line-file"
        static let lineLength = "line-length"
        
        static let tabSpaces = "tab-spaces"
        
        static let extraArguments = "extra"
        
        static let fontFamily = "font-family"
        static let fontSize = "font-size"
        
        static let customCSS = "css"
        
        static let interactive = "interactive"
        static let maxData = "max-data"
        static let convertEOL = "convert-EOL"
        
        static let version = "version"
        static let about = "about"
        static let debug = "debug"
        
        static let dumpPlain = "dump"
        
        static let vcs = "vcs"
        static let vcsDiff = "vcs-diff"
        static let vcs_add_light = "vcs_add_light"
        static let vcs_add_dark = "vcs_add_dark"
        static let vcs_edit_light = "vcs_edit_light"
        static let vcs_edit_dark = "vcs_edit_dark"
        static let vcs_del_light = "vcs_del_light"
        static let vcs_del_dark = "vcs_del_dark"
        static let git_path = "git_path"
        static let hg_path = "hg_path"
        static let svn_path = "svn_path"
        
        static let customizedUTISettings = "uti-settings"
        static let plainSettings = "plain-settings"
        static let specialSettingsGlobal = "global-special-settings"
        
        static let connectedUTI = "uti"
        
        static let specialSettingsFormat = "specialSettings"

        static let preprocessor = "preprocessor"
        static let syntax = "syntax"
        static let appendedExtraArguments = "uti-extra"
        
        static let lsp = "LSP"
        static let lspExecutable = "LSP-executable"
        static let lspDelay = "LSP-delay"
        static let lspSyntax = "LSP-syntax"
        static let lspHover = "LSP-hover"
        static let lspSemantic = "LSP-semantic"
        static let lspSyntaxError = "LSP-syntax-error"
        static let lspOptions = "LSP-options"
        
        static let qlWidth = "ql-window-width"
        static let qlHeight = "ql-window-height"
    }
    
    fileprivate var refreshLock = 0
    @objc dynamic fileprivate(set) var needRefresh: Bool = false
    
    weak var delegate: SettingsDelegate?
    
    func lockRefresh() {
        refreshLock += 1
    }
    func unlockRefresh() {
        refreshLock -= 1
        if refreshLock == 0 {
            setNeedRefresh()
        }
    }
    func setNeedRefresh() {
        if refreshLock == 0 {
            needRefresh = true
            delegate?.settingsIsChanged(self)
        }
    }
    
    dynamic var format: Format {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: format)
        }
    }
    dynamic var isFormatDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isFormatDefined)
        }
    }
    
    // MARK: Themes
    dynamic var isLightThemeNameDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLightThemeNameDefined)
        }
    }
    /// Name of theme for light visualization.
    dynamic var lightThemeName: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: lightThemeName)
        }
    }
    /// Background color for the rgb view in light theme.
    var lightBackgroundColor: String
    var lightForegroundColor: String
    
    /// Background color for the rgb view in dark theme.
    dynamic var isDarkThemeNameDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isDarkThemeNameDefined)
        }
    }
    /// Name of theme for dark visualization.
    dynamic var darkThemeName: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: darkThemeName)
        }
    }
    var darkBackgroundColor: String
    var darkForegroundColor: String
    
    // MARK: Line numbers.
    dynamic var isLineNumbersDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLineNumbersDefined)
        }
    }
    /// Show line numbers.
    dynamic var isLineNumbersVisible: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLineNumbersVisible)
        }
    }
    dynamic var isLineNumbersFillToZeroes: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLineNumbersFillToZeroes)
        }
    }
    
    // MARK: Word wrap
    dynamic var isWordWrapDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrapDefined)
        }
    }
    /// Word wrap mode.
    dynamic var isWordWrapped: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrapped)
        }
    }
    dynamic var isWordWrappedHard: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrappedHard)
        }
    }
    var isWordWrappedSoft: Bool {
        return !isWordWrappedHard
    }
    dynamic var isWordWrappedSoftForOneLineFiles: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrappedSoftForOneLineFiles)
        }
    }
    dynamic var isWordWrappedIndented: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrappedIndented)
        }
    }
    
    
    dynamic var isLineLengthDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLineLengthDefined)
        }
    }
    /// Line length for word wrap.
    dynamic var lineLength: Int {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: lineLength)
        }
    }
    
    // MARK: Tabs
    dynamic var isTabSpacesDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isTabSpacesDefined)
        }
    }
    
    /// Number of spaces use for a tab. Set to 0 to disable converting tab to spaces.
    dynamic var tabSpaces: Int {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: tabSpaces)
        }
    }
    
    // MARK: CSS
    
    dynamic var isCSSDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isCSSDefined)
        }
    }
    /// Custom style sheet.
    /// When the settings are stored the value is written to a file.
    /// When nil use the css stored on file, if exists.
    dynamic var css: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: css)
        }
    }
    
    // MARK: Font
    dynamic var isFontNameDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isFormatDefined)
        }
    }
    dynamic var fontName: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: fontName)
        }
    }
    
    dynamic var isFontSizeDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isFontSizeDefined)
        }
    }
    dynamic var fontSize: CGFloat {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: fontSize)
        }
    }
    
    // MARK: Interactive preview
    
    dynamic var isAllowInteractiveActionsDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isAllowInteractiveActionsDefined)
        }
    }
    /// If true enable js action on the Quick Look preview but disable dblclick and click and drag on window.
    dynamic var allowInteractiveActions: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: allowInteractiveActions)
        }
    }
    
    // MARK: Highlight arguments
    dynamic var isArgumentsDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isArgumentsDefined)
        }
    }
    /// Extra arguments for highlight.
    dynamic var arguments: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: arguments)
        }
    }
    
    dynamic var isVCSDefined: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isVCSDefined)
        }
    }
    dynamic var vcsAddLightColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsAddLightColor)
        }
    }
    dynamic var vcsAddDarkColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsAddDarkColor)
        }
    }
    dynamic var vcsEditLightColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsEditLightColor)
        }
    }
    dynamic var vcsEditDarkColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsEditDarkColor)
        }
    }
    dynamic var vcsDelLightColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsDelLightColor)
        }
    }
    dynamic var vcsDelDarkColor: String {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: vcsDelDarkColor)
        }
    }
    
    // MARK:
    internal var mustNotifyDirtyStatus = false
    internal var lockDirty = 0 {
        didSet {
            if oldValue != lockDirty && lockDirty == 0 && mustNotifyDirtyStatus {
                mustNotifyDirtyStatus = false
                NotificationCenter.default.post(name: .SettingsIsDirty, object: self)
            }
        }
    }
    @objc dynamic var isDirty = false {
        didSet {
            if oldValue != isDirty {
                if lockDirty == 0 {
                    mustNotifyDirtyStatus = false
                    NotificationCenter.default.post(name: .SettingsIsDirty, object: self)
                } else {
                    mustNotifyDirtyStatus = true
                }
            }
        }
    }
    
    var isCustomized: Bool {
        get {
            let state = isFormatDefined || isLightThemeNameDefined || isDarkThemeNameDefined || isLineNumbersDefined || isWordWrapDefined || isLineLengthDefined || isTabSpacesDefined || isArgumentsDefined || isCSSDefined || isFontSizeDefined || isVCSDefined
            
            guard !state else {
                return true
            }
            
            if #available(macOS 12, *) {
               return false
            } else {
                return isAllowInteractiveActionsDefined
            }
        }
    }
    
    @discardableResult
    internal func requestRefreshOnChanged<T: Equatable>(oldValue: T, newValue: T) ->Bool {
        guard oldValue != newValue else {
            return false
        }
        setNeedRefresh()
        isDirty = true
        return true
    }
    
    // MARK: - Initializers
    internal required init(settings: [String: AnyHashable]) {
        self.format = .rtf
        isFormatDefined = false
        self.lightThemeName = "edit-xcode"
        isLightThemeNameDefined = false
        self.lightBackgroundColor = "#ffffff"
        self.lightForegroundColor = "#000000"
        self.darkThemeName = "neon"
        isDarkThemeNameDefined = false
        self.darkBackgroundColor = "#303030"
        self.darkForegroundColor = "#f0f0f0"
        
        self.isLineNumbersVisible = false
        self.isLineNumbersDefined = false
        self.isLineNumbersFillToZeroes = false
        
        self.isWordWrapped = false
        self.isWordWrappedHard = false
        self.isWordWrappedIndented = false
        self.isWordWrappedSoftForOneLineFiles = true
        self.isWordWrapDefined = false
        
        self.lineLength = 80
        self.isLineLengthDefined = false
        
        self.tabSpaces = 4
        self.isTabSpacesDefined = false
        
        self.css = ""
        self.isCSSDefined = false
        
        self.fontName = "-" // Use the system font
        self.isFontNameDefined = false
        self.fontSize = NSFont.systemFontSize
        self.isFontSizeDefined = false
        
        self.allowInteractiveActions = false
        self.isAllowInteractiveActionsDefined = false
        
        self.arguments = ""
        self.isArgumentsDefined = false
        
        self.vcsAddLightColor = "#C9DEC1"
        self.vcsAddDarkColor = "#009924"
        self.vcsEditLightColor = "#C3D6E8"
        self.vcsEditDarkColor = "#1AABFF"
        self.vcsDelLightColor = "#edc5c5"
        self.vcsDelDarkColor = "#fd8888"
        self.isVCSDefined = false
        
        super.init()
        lockDirty += 1
        self.override(fromDictionary: settings)
        self.isDirty = false
        self.mustNotifyDirtyStatus = false
        lockDirty -= 1
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: AnyHashable]
    func override(fromDictionary dict: [String: AnyHashable]?) {
        guard let settings = dict else {
            return
        }
        
        if let format = Settings.Format(rawValue: settings[SettingsBase.Key.format] as? String ?? "") {
            self.format = format
            self.isFormatDefined = true
        }
        
        // Light theme.
        if let theme = settings[SettingsBase.Key.lightTheme] as? String {
            self.lightThemeName = theme
            isLightThemeNameDefined = true
        }
        // Light background color.
        if let color = settings[SettingsBase.Key.lightBackgroundColor] as? String {
            self.lightBackgroundColor = color
        }
        if let color = settings[SettingsBase.Key.lightForegroundColor] as? String {
            self.lightForegroundColor = color
        }
        
        // Dark theme.
        if let theme = settings[SettingsBase.Key.darkTheme] as? String {
            self.darkThemeName = theme
            isDarkThemeNameDefined = true
        }
        // Dark background color.
        if let color = settings[SettingsBase.Key.darkBackgroundColor] as? String {
            self.darkBackgroundColor = color
        }
        if let color = settings[SettingsBase.Key.darkForegroundColor] as? String {
            self.darkForegroundColor = color
        }
        
        // Show line numbers.
        if let ln = settings[SettingsBase.Key.lineNumbers] as? Bool {
            self.isLineNumbersVisible = ln
            self.isLineNumbersDefined = true
            self.isLineNumbersFillToZeroes = settings[SettingsBase.Key.lineNumbersFillToZeroes] as? Bool ?? false
        }
        
        if let wrap = settings[SettingsBase.Key.wordWrap] as? Int {
           self.isWordWrapped = wrap != 0
           self.isWordWrappedIndented = wrap > 1
           isWordWrapDefined = true
        }
        if let v = settings[SettingsBase.Key.wordWrapHard] as? Bool {
           self.isWordWrappedHard = v
        }
        if let v = settings[SettingsBase.Key.wordWrapOneLineFiles] as? Bool {
           self.isWordWrappedSoftForOneLineFiles = v
        }
        
        if let n = settings[SettingsBase.Key.lineLength] as? Int {
            self.lineLength = n
            self.isLineLengthDefined = true
        }
        
        // Convert tab to spaces.
        if let n = settings[SettingsBase.Key.tabSpaces] as? Int {
            self.tabSpaces = n
            self.isTabSpacesDefined = true
        }
        
        if let css = settings[SettingsBase.Key.customCSS] as? String {
            self.css = css
            self.isCSSDefined = !css.isEmpty
        }
        
        // Font name.
        if let font = settings[SettingsBase.Key.fontFamily] as? String {
            self.fontName = font.isEmpty ? "-" : font
            self.isFontNameDefined = true
        }
        // Font size.
        if let pt = settings[SettingsBase.Key.fontSize] as? CGFloat {
            self.fontSize = pt
            self.isFontSizeDefined = true
        }
        
        if let state = settings[SettingsBase.Key.interactive] as? Bool {
            self.allowInteractiveActions = state
            self.isAllowInteractiveActionsDefined = true
        }
        
        // Extra arguments for _highlight_.
        if let args = settings[SettingsBase.Key.extraArguments] as? String, !args.trimmingCharacters(in: .whitespaces).isEmpty {
            self.arguments = args
            self.isArgumentsDefined = true
        }
        
        if let color = settings[SettingsBase.Key.vcs_add_light] as? String {
            self.vcsAddLightColor = color
            self.isVCSDefined = true
        }
        if let color = settings[SettingsBase.Key.vcs_add_dark] as? String {
            self.vcsAddDarkColor = color
            self.isVCSDefined = true
        }
        if let color = settings[SettingsBase.Key.vcs_edit_light] as? String {
            self.vcsEditLightColor = color
            self.isVCSDefined = true
        }
        if let color = settings[SettingsBase.Key.vcs_edit_dark] as? String {
            self.vcsEditDarkColor = color
            self.isVCSDefined = true
        }
        if let color = settings[SettingsBase.Key.vcs_del_light] as? String {
            self.vcsDelLightColor = color
            self.isVCSDefined = true
        }
        if let color = settings[SettingsBase.Key.vcs_del_dark] as? String {
            self.vcsDelDarkColor = color
            self.isVCSDefined = true
        }
    }
    
    // MARK:
    func isEqual(to object: SettingsBase) -> Bool {
        let a = self.toDictionary()
        let b = self.toDictionary()
        return a == b
    }
    
    func duplicate() -> Self {
        return type(of: self).init(settings: self.toDictionary())
    }
    
    // MARK: -
    /// Output the settings to a dictionary.
    /// Only customized options are exported.
    func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r: [String: AnyHashable] = [:]
        
        if isFormatDefined {
            r[SettingsBase.Key.format] = format == .html ? "html" : "rtf"
        }
        if isLightThemeNameDefined {
            r[SettingsBase.Key.lightTheme] = lightThemeName
            r[SettingsBase.Key.lightBackgroundColor] = lightBackgroundColor
            r[SettingsBase.Key.lightForegroundColor] = lightForegroundColor
        }
        if isDarkThemeNameDefined {
            r[SettingsBase.Key.darkTheme] = darkThemeName
            r[SettingsBase.Key.darkBackgroundColor] = darkBackgroundColor
            r[SettingsBase.Key.darkForegroundColor] = darkForegroundColor
        }
        if isWordWrapDefined {
            r[SettingsBase.Key.wordWrap] = isWordWrapped ? (isWordWrappedIndented ? 2 : 1) : 0
            r[SettingsBase.Key.wordWrapHard] = isWordWrappedHard
            r[SettingsBase.Key.wordWrapOneLineFiles] = isWordWrappedSoftForOneLineFiles
        }
        if isLineLengthDefined {
            r[SettingsBase.Key.lineLength] = lineLength
        }
        if isTabSpacesDefined {
            r[SettingsBase.Key.tabSpaces] = tabSpaces
        }
        
        if isArgumentsDefined {
            r[SettingsBase.Key.extraArguments] = arguments
        }
        
        if isVCSDefined {
            r[SettingsBase.Key.vcs_add_light] = vcsAddLightColor
            r[SettingsBase.Key.vcs_add_dark] = vcsAddDarkColor
            r[SettingsBase.Key.vcs_edit_light] = vcsEditLightColor
            r[SettingsBase.Key.vcs_edit_dark] = vcsEditDarkColor
            r[SettingsBase.Key.vcs_del_light] = vcsDelLightColor
            r[SettingsBase.Key.vcs_del_dark] = vcsDelDarkColor
        }
        
        if isFontNameDefined {
            r[SettingsBase.Key.fontFamily] = fontName
        }
        if isFontSizeDefined {
            r[SettingsBase.Key.fontSize] = fontSize
        }
        
        if isCSSDefined {
            r[SettingsBase.Key.customCSS] = css
        }
        
        if isLineNumbersDefined {
            r[SettingsBase.Key.lineNumbers] = isLineNumbersVisible
            r[SettingsBase.Key.lineNumbersFillToZeroes] = isLineNumbersFillToZeroes
        }
        
        if isAllowInteractiveActionsDefined {
            r[SettingsBase.Key.interactive] = allowInteractiveActions
        }
        
        return r
    }
    
    func isOSThemeLight() -> Bool {
        /*if #available(macOS 11.0, *) {
            // Fixme: nell'estensione non sempre restituisce il valore aggiornato.
            return NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) ?? .aqua == .aqua
        } else {
            return (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        }*/
        return (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
    }
    
    func getTheme() -> ThemeBaseColor {
        let isOSThemeLight = self.isOSThemeLight()
        
        let theme: String
        let themeBackground: String
        let themeForeground: String
        if isOSThemeLight {
            theme = self.isLightThemeNameDefined ? self.lightThemeName : "edit-xcode"
            themeBackground = self.isLightThemeNameDefined ? self.lightBackgroundColor : "#ffffff"
            themeForeground = self.isLightThemeNameDefined ? self.lightForegroundColor : "#000000"
        } else {
            theme = self.isDarkThemeNameDefined ? self.darkThemeName : "neon"
            themeBackground = self.isDarkThemeNameDefined ? self.darkBackgroundColor : "#303030"
            themeForeground = self.isDarkThemeNameDefined ? self.darkForegroundColor : "#f0f0f0"
        }
        
        return (name: theme, background: themeBackground, foreground: themeForeground)
    }
}

protocol SettingsLSP: SettingsBase {
    var useLSP: Bool { get set }
    var lspExecutable: String { get set }
    var lspSyntax: String { get set }
    var lspDelay: Int { get set }
    var lspHover: Bool { get set }
    var lspSemantic: Bool { get set }
    var lspSyntaxError: Bool { get set }
    var lspOptions: [String] { get set }
    
    var isUsingLSP: Bool { get }
    var isLSPCustomized: Bool { get }
}

extension SettingsLSP {
    var isUsingLSP: Bool {
        return useLSP && !lspExecutable.isEmpty
    }
    var isLSPCustomized: Bool {
        return useLSP && (!lspExecutable.isEmpty || !lspSyntax.isEmpty || lspDelay>0 || lspHover || lspSemantic || lspSyntaxError || !lspOptions.isEmpty)
    }
    
    func overrideLSP(fromDictionary dict: [String: AnyHashable]?) {
        guard let settings = dict else {
            return
        }
        if let v = settings[SettingsBase.Key.lsp] as? Bool {
            self.useLSP = v
        }
        if let v = settings[SettingsBase.Key.lspExecutable] as? String {
            self.lspExecutable = v
        }
        if let v = settings[SettingsBase.Key.lspDelay] as? Int {
            self.lspDelay = v
        }
        if let v = settings[SettingsBase.Key.lspSyntax] as? String {
            self.lspSyntax = v
        }
        if let v = settings[SettingsBase.Key.lspHover] as? Bool {
            self.lspHover = v
        }
        if let v = settings[SettingsBase.Key.lspSemantic] as? Bool {
            self.lspSemantic = v
        }
        if let v = settings[SettingsBase.Key.lspSyntaxError] as? Bool {
            self.lspSyntaxError = v
        }
        if let v = settings[SettingsBase.Key.lspOptions] as? [String] {
            self.lspOptions = v
        }
    }
    
    func lspToDictionary(dict: inout [String: AnyHashable], forSaving: Bool) {
        if !forSaving || self.useLSP {
            dict[SettingsBase.Key.lsp] = self.useLSP
        }
        if !forSaving || !self.lspExecutable.isEmpty {
            dict[SettingsBase.Key.lspExecutable] = self.lspExecutable
        }
        if !forSaving || self.lspDelay > 0 {
            dict[SettingsBase.Key.lspDelay] = self.lspDelay
        }
        if !forSaving || !self.lspSyntax.isEmpty {
            dict[SettingsBase.Key.lspSyntax] = self.lspSyntax
        }
        if !forSaving || self.lspHover {
            dict[SettingsBase.Key.lspHover] = self.lspHover
        }
        if !forSaving || self.lspSemantic {
            dict[SettingsBase.Key.lspSemantic] = self.lspSemantic
        }
        if !forSaving || self.lspSyntaxError {
            dict[SettingsBase.Key.lspSyntaxError] = self.lspSyntaxError
        }
        if !forSaving || !self.lspOptions.isEmpty {
            dict[SettingsBase.Key.lspOptions] = self.lspOptions
        }
    }
}

protocol SettingsFormatProtocol: SettingsBase {
    dynamic var isAppendArgumentsDefined: Bool { get set }
    dynamic var appendArguments: String { get set }
    
    dynamic var isPreprocessorDefined: Bool { get set }
    dynamic var preprocessor: String { get set }
    
    dynamic var isSyntaxDefined: Bool { get set }
    dynamic var syntax: String { get set }
}

// MARK: -
class SettingsFormat: SettingsBase, SettingsFormatProtocol, SettingsLSP {
    var uti: String
    
    var isCSSPopulated: Bool = false
    
    dynamic var isAppendArgumentsDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isAppendArgumentsDefined)
        }
    }
    dynamic var appendArguments: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: appendArguments)
        }
    }
    
    dynamic var isPreprocessorDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isPreprocessorDefined)
        }
    }
    dynamic var preprocessor: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: preprocessor)
        }
    }
    
    dynamic var isSyntaxDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isSyntaxDefined)
        }
    }
    dynamic var syntax: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: syntax)
        }
    }
    
    var specialSyntax: String?
    var specialPreprocessor: String?
    var specialAppendArguments: String?
    
    var useLSP: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: useLSP)
        }
    }
    var lspExecutable: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspExecutable)
        }
    }
    var lspSyntax: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSyntax)
        }
    }
    var lspDelay: Int {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspDelay)
        }
    }
    var lspHover: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspHover)
        }
    }
    var lspSemantic: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSemantic)
        }
    }
    var lspSyntaxError: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSyntaxError)
        }
    }
    var lspOptions: [String] {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspOptions)
        }
    }
    
    override var isCustomized: Bool {
        get {
            return super.isCustomized || isPreprocessorDefined || isAppendArgumentsDefined || isSyntaxDefined || isLSPCustomized
        }
    }
      
    convenience init (uti: String, settings: [String: AnyHashable]) {
        var s = settings
        s[SettingsBase.Key.connectedUTI] = uti
        self.init(settings: s)
    }
    
    required internal init(settings: [String: AnyHashable]) {
        self.uti = (settings[SettingsBase.Key.connectedUTI] as? String) ?? ""
        
        self.appendArguments = ""
        self.isAppendArgumentsDefined = false
        self.syntax = ""
        self.isSyntaxDefined = false
        self.preprocessor = ""
        self.isPreprocessorDefined = false
        self.specialPreprocessor = nil
        self.specialSyntax = nil
        self.specialAppendArguments = nil
        
        self.useLSP = false
        self.lspExecutable = ""
        self.lspSyntax = ""
        self.lspDelay = 0
        self.lspHover = false
        self.lspSemantic = false
        self.lspSyntaxError = false
        self.lspOptions = []
        
        super.init(settings: settings)
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: AnyHashable]
    override func override(fromDictionary dict: [String: AnyHashable]?) {
        guard let settings = dict else {
            return
        }
        
        super.override(fromDictionary: dict)
        
        if let args = settings[SettingsBase.Key.appendedExtraArguments] as? String, !args.trimmingCharacters(in: .whitespaces).isEmpty {
            self.appendArguments = args
            self.isAppendArgumentsDefined = true
        }
        
        if let syntax = settings[SettingsBase.Key.syntax] as? String {
            self.syntax = syntax
            self.isSyntaxDefined = true
        }
        
        if let preprocessor = settings[SettingsBase.Key.preprocessor] as? String {
            self.preprocessor = preprocessor
            self.isPreprocessorDefined = true
        }
        
        overrideLSP(fromDictionary: dict)
        
        if let specials = settings[SettingsBase.Key.specialSettingsFormat] as? [String: String] {
            if let v = specials[SettingsBase.Key.preprocessor] {
                self.specialPreprocessor = v
            }
            if let v = specials[SettingsBase.Key.syntax] {
                self.specialSyntax = v
            }
            if let v = specials[SettingsBase.Key.appendedExtraArguments], !v.trimmingCharacters(in: .whitespaces).isEmpty {
                self.specialAppendArguments = v
            }
        }
    }
    
    override func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r = super.toDictionary(forSaving: forSaving)
        
        if isAppendArgumentsDefined {
            r[SettingsBase.Key.appendedExtraArguments] = appendArguments
        }
        if isSyntaxDefined {
            r[SettingsBase.Key.syntax] = syntax
        }
        if isPreprocessorDefined {
            r[SettingsBase.Key.preprocessor] = preprocessor
        }
        
        lspToDictionary(dict: &r, forSaving: forSaving)
        
        if !forSaving {
            var special: [String: AnyHashable] = [:]
            if let preprocessor = self.specialPreprocessor {
                special[SettingsBase.Key.preprocessor] = preprocessor
            }
            if let syntax = self.specialSyntax {
                special[SettingsBase.Key.syntax] = syntax
            }
            if let appendArguments = self.specialAppendArguments, !appendArguments.trimmingCharacters(in: .whitespaces).isEmpty {
                special[SettingsBase.Key.appendedExtraArguments] = appendArguments
            }
            if !special.isEmpty {
                r[SettingsBase.Key.specialSettingsFormat] = special
            }
        }
        
        r[SettingsBase.Key.connectedUTI] = self.uti
        
        return r
    }
    
    override func duplicate() -> Self {
        return type(of: self).init(settings: self.toDictionary())
    }
}

// MARK: -
class Settings: SettingsBase {
    /// Current settings version handled by the applications.
    static let version: Float = 2.4
    
    static let plainUTIs = ["public.unix-executable", "public.data", "public.content", "public.item"]
    
    /// Version of the settings.
    var version: Float = 0
    
    var isAllSpecialSettingsPopulated: Bool = false
    var isAllCSSPopulated: Bool = false
    
    var specialSettings:  [String: [String: [String: String]]] = [:]
    
    internal var plainSettings: [PlainSettings] = []
    
    var app_version: String {
        var title: String = "<a href='https://github.com/sbarex/SourceCodeSyntaxHighlight'>";
        if let info = Bundle.main.infoDictionary {
            title += (info["CFBundleExecutable"] as? String ?? "Syntax Highlight") + "</a>"
            if let version = info["CFBundleShortVersionString"] as? String,
                let build = info["CFBundleVersion"] as? String {
                title += ", version \(version) (\(build))"
            }
            if let copy = info["NSHumanReadableCopyright"] as? String {
                title += ".<br />\n\(copy.trimmingCharacters(in: CharacterSet(charactersIn: ". ")) + " with <span style='font-style: normal'>❤️</span>")"
            }
        } else {
            title += "Syntax Highlight</a>"
        }
        title += ".<br/>\nIf you like this app, <a href='https://www.buymeacoffee.com/sbarex'><strong>buy me a coffee</strong></a>!"
        return title
    }
    
    dynamic var isAboutVisible: Bool = true {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isAboutVisible)
        }
    }
    
    dynamic var isDebug: Bool = false {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isDebug)
        }
    }
    
    dynamic var isDumpPlainData: Bool = true {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isDumpPlainData)
        }
    }
    
    dynamic var isVCS: Bool = false {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isVCS)
        }
    }
    
    dynamic var gitPath: String = "/usr/bin/git" {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: gitPath)
        }
    }
    dynamic var hgPath: String = "/usr/bin/hg" {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: hgPath)
        }
    }
    dynamic var svnPath: String = "/usr/bin/svn" {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: svnPath)
        }
    }
    
    dynamic var maxData: UInt64 = 0 {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: maxData)
        }
    }
    dynamic var convertEOL: Bool = false {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: convertEOL)
        }
    }
    
    
    dynamic var qlWindowWidth: Int? {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: qlWindowWidth)
        }
    }
    dynamic var qlWindowHeight: Int? {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: qlWindowHeight)
        }
    }
    var qlWindowSize: CGSize {
        if let w = self.qlWindowWidth, w > 0, let h = self.qlWindowHeight, h > 0 {
            return CGSize(width: w, height: h)
        } else {
            return .zero
        }
    }
    
    /// Customized settings for UTIs.
    fileprivate(set) var utiSettings: [String: SettingsFormat] = [:]

    override var isDirty: Bool {
        get {
            if super.isDirty {
                return true
            }
            for (_, settings) in utiSettings {
                if settings.isDirty {
                    return true
                }
            }
            return false
        }
        set {
            super.isDirty = newValue
        }
    }
    
    required internal init(settings: [String: AnyHashable]) {
        self.version = settings[SettingsBase.Key.version] as? Float ?? Settings.version
        
        self.isAboutVisible = true
        self.isDebug = false
        
        self.isVCS = false
        self.gitPath = "/usr/bin/git"
        self.hgPath = "/usr/bin/hg"
        self.svnPath = "/usr/bin/svn"
        
        self.maxData = 0
        self.convertEOL = false
        
        self.utiSettings = [:]
        
        super.init(settings: settings)
        
        if let custom_formats = settings[SettingsBase.Key.customizedUTISettings] as? [String: [String: AnyHashable]] {
            for (uti, uti_settings) in custom_formats {
                self.utiSettings[uti] = SettingsFormat(uti: uti, settings: uti_settings)
            }
        }
        
        if let v = settings[SettingsBase.Key.qlWidth] as? Int, v > 0 {
            self.qlWindowWidth = v
        }
        if let v = settings[SettingsBase.Key.qlHeight] as? Int, v > 0 {
            self.qlWindowHeight = v
        }
        
        self.plainSettings = []
        if let plain = settings[SettingsBase.Key.plainSettings] as? [[String: AnyHashable]] {
            for s in plain {
                if let p = PlainSettings(settings: s) {
                    self.plainSettings.append(p)
                }
            }
        }
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: AnyHashable]
    override func override(fromDictionary dict: [String: AnyHashable]?) {
        guard let settings = dict else {
            return
        }
        
        super.override(fromDictionary: dict)
        
        if let v = settings[SettingsBase.Key.about] as? Bool {
            self.isAboutVisible = v
        }
        if let v = settings[SettingsBase.Key.debug] as? Bool {
            self.isDebug = v
        }
        if let v = settings[SettingsBase.Key.dumpPlain] as? Bool {
            self.isDumpPlainData = v
        }
        if let v = settings[SettingsBase.Key.git_path] as? String {
            self.gitPath = v
        }
        if let v = settings[SettingsBase.Key.hg_path] as? String {
            self.hgPath = v
        }
        if let v = settings[SettingsBase.Key.svn_path] as? String {
            self.svnPath = v
        }
        
        if let v = settings[SettingsBase.Key.vcs] as? Bool {
            self.isVCS = v
        }
        
        if let v = settings[SettingsBase.Key.maxData] as? UInt64 {
            self.maxData = v
        }
        if let v = settings[SettingsBase.Key.convertEOL] as? Bool {
            self.convertEOL = v
        }
        
        if let v = settings[SettingsBase.Key.qlWidth] as? Int, v > 0 {
            self.qlWindowWidth = v
        }
        if let v = settings[SettingsBase.Key.qlHeight] as? Int, v > 0 {
            self.qlWindowHeight = v
        }
        
        if let v = settings[SettingsBase.Key.specialSettingsGlobal] as? [String: [String: [String: String]]] {
            self.specialSettings = v
        }
        
        self.isFormatDefined = true
        self.isLightThemeNameDefined = true
        self.isDarkThemeNameDefined = true
        self.isFontNameDefined = true
        self.isFontSizeDefined = true
        self.isWordWrapDefined = true
        self.isLineLengthDefined = true
        self.isLineNumbersDefined = true
        self.isTabSpacesDefined = true
        self.isArgumentsDefined = true
        self.isCSSDefined = true
        self.isVCSDefined = true
        
        if let plain_settings = settings[SettingsBase.Key.plainSettings] as? [[String: AnyHashable]] {
            var plainSettings: [PlainSettings] = []
            for p_settings in plain_settings {
                if let s = PlainSettings(settings: p_settings) {
                    plainSettings.append(s)
                }
            }
            if !self.isDirty && self.plainSettings != plainSettings {
                self.isDirty = true
            }
            self.plainSettings = plainSettings
        }
    }
    
    /// Output the settings to a dictionary.
    override func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r = super.toDictionary(forSaving: forSaving)
        r[SettingsBase.Key.about] = self.isAboutVisible
        
        r[SettingsBase.Key.debug] = self.isDebug
        
        r[SettingsBase.Key.dumpPlain] = self.isDumpPlainData
        
        r[SettingsBase.Key.vcs] = self.isVCS
        r[SettingsBase.Key.git_path] = self.gitPath
        r[SettingsBase.Key.hg_path] = self.hgPath
        r[SettingsBase.Key.svn_path] = self.svnPath
        
        r[SettingsBase.Key.maxData] = self.maxData
        r[SettingsBase.Key.convertEOL] = self.convertEOL
        
        r[SettingsBase.Key.qlWidth] = self.qlWindowWidth ?? 0
        r[SettingsBase.Key.qlHeight] = self.qlWindowHeight ?? 0
        
        var customized: [String: [String: AnyHashable]] = [:]
        for (uti, settingsFormat) in self.utiSettings {
            guard !forSaving || settingsFormat.isCustomized else {
                continue
            }
            let f = settingsFormat.toDictionary(forSaving: forSaving)
            if !f.isEmpty {
                customized[uti] = f
            }
        }
        r[SettingsBase.Key.customizedUTISettings] = customized
        
        var plain: [[String: AnyHashable]] = []
        for s in self.plainSettings {
            let f = s.toDictionary(forSaving: forSaving)
            if !f.isEmpty {
                plain.append(f)
            }
        }
        r[SettingsBase.Key.plainSettings] = plain
        
        r[SettingsBase.Key.specialSettingsGlobal] = self.specialSettings
        
        return r
    }
    
    func customize(withSettings settings: SettingsBase) -> Self {
        var d = self.toDictionary()
        d.merge(settings.toDictionary()) { (_, new) in new }
        return Self(settings: d)
    }
    
    // MARK: - UTI Settings
    func hasSettings(forUTI uti: String) -> Bool {
        return self.utiSettings[uti] != nil
    }
    
    func hasCustomizedSettings(forUTI uti: String) -> Bool {
        return self.utiSettings[uti]?.isCustomized ?? false
    }
    
    func createSettings(forUTI uti: String, settings: [String: AnyHashable]? = nil) -> SettingsFormat {
        var v: [String: AnyHashable] = settings ?? [:]
        v[SettingsBase.Key.connectedUTI] = uti
        let s = SettingsFormat(settings: v)
        self.utiSettings[uti] = s
        return s
    }
    
    func settings(forUTI uti: String) -> Settings {
        let utiSettings = self.utiSettings[uti] ?? SettingsFormat(settings: [:])
        return self.customize(withSettings: utiSettings)
    }
    
    func settings(forUTI uti: String) -> SettingsRendering {
        let settings = SettingsRendering(settings: self.toDictionary())
        let utiSettings = self.utiSettings[uti] ?? SettingsFormat(settings: [:])
        return settings.customize(withSettings: utiSettings)
    }
    
    static let appBundle: Bundle = {
        var url = Bundle.main.bundleURL
        if Bundle.main.bundlePath.hasSuffix(".xpc") || Bundle.main.bundlePath.hasSuffix(".appex") {
            // This is an xpc/appex extension.
            while url.pathExtension != "app" {
                let u = url.path
                url.deleteLastPathComponent()
                if u == url.path {
                    return Bundle.main
                }
            }
        }
        url.appendPathComponent("Contents")
        
        if let appBundle = Bundle(url: url) {
            return appBundle
        } else {
            return Bundle.main
        }
    }()
    
    func searchStandaloneUTI(for uti: UTI) -> String? {
        guard uti.isDynamic else {
            return uti.UTI
        }
        
        let bundle = Self.appBundle
        if let info = bundle.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: info) as? [String: AnyObject] {
            
            let search1: (String, [[String: AnyObject]]) -> String? = { identifier, utis in
                for u in utis {
                    if let id = u["UTTypeIdentifier"] as? String, !id.hasPrefix("dyn."),
                       let conform = u["UTTypeConformsTo"] as? [String], conform.contains(identifier) {
                        return id
                    }
                }
                return nil
            }
            
            let search2: ([String], [[String: AnyObject]]) -> String? = { extensions, utis in
                for u in utis {
                    if let id = u["UTTypeIdentifier"] as? String, !id.hasPrefix("dyn."),
                       let type = u["UTTypeTagSpecification"] as? [String: AnyObject], let ext = type["public.filename-extension"] as? [String] {
                        for file_ext in extensions {
                            if ext.contains(file_ext) {
                                return id
                            }
                        }
                    }
                }
                return nil
            }
            
            if let utis = dict["UTExportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search1(uti.UTI, utis) {
                    return id
                }
            }
            if let utis = dict["UTImportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search1(uti.UTI, utis) {
                    return id
                }
            }
            
            if let utis = dict["UTExportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search2(uti.extensions, utis) {
                    return id
                }
            }
            if let utis = dict["UTImportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search2(uti.extensions, utis) {
                    return id
                }
            }
        }
        
        return nil
    }
        
    func searchUTI(for url: URL) -> String? {
        guard let uti = UTI(URL: url) else {
            return nil
        }
        guard !Settings.plainUTIs.contains(uti.UTI) else {
            return nil
        }
        
        guard uti.isDynamic else {
            return uti.UTI
        }
        
        let bundle = Self.appBundle
        if let info = bundle.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: info) as? [String: AnyObject] {
            
            let search1: (String, [[String: AnyObject]]) -> String? = { identifier, utis in
                for u in utis {
                    if let id = u["UTTypeIdentifier"] as? String, !id.hasPrefix("dyn."),
                       let conform = u["UTTypeConformsTo"] as? [String], conform.contains(identifier) {
                        return id
                    }
                }
                return nil
            }
            
            let search2: (String, [[String: AnyObject]]) -> String? = { file_ext, utis in
                for u in utis {
                    if let id = u["UTTypeIdentifier"] as? String, !id.hasPrefix("dyn."),
                       let type = u["UTTypeTagSpecification"] as? [String: AnyObject], let ext = type["public.filename-extension"] as? [String] {
                        if ext.contains(file_ext) {
                            return id
                        }
                    }
                }
                return nil
            }
            
            if let utis = dict["UTExportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search1(uti.UTI, utis) {
                    return id
                }
            }
            if let utis = dict["UTImportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search1(uti.UTI, utis) {
                    return id
                }
            }
            
            if let utis = dict["UTExportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search2(url.pathExtension, utis) {
                    return id
                }
            }
            if let utis = dict["UTImportedTypeDeclarations"] as? [[String: AnyObject]] {
                if let id = search2(url.pathExtension, utis) {
                    return id
                }
            }
        }
        
        return nil
    }
    
    func searchSettings(for url: URL) -> SettingsFormat? {
        if let uti = searchUTI(for: url) {
            return self.utiSettings[uti]
        } else {
            return nil
        }
    }
    
    func searchPlainSettings(for url: URL, mimeType: String?) -> PlainSettings? {
        let name = url.lastPathComponent
        for s in self.plainSettings {
            if s.test(filename: name, mimeType: mimeType) {
                return s
            }
        }
        return nil
    }
    
    func getPlainSettings() -> [PlainSettings] {
        return self.plainSettings
    }
    func insertPlainSettings(settings: PlainSettings, at: Int = -1) {
        if at < 0 {
            self.plainSettings.append(settings)
        } else {
            self.plainSettings.insert(settings, at: at)
        }
        self.isDirty = true
    }
    func removeAllPlainSettings() {
        if self.plainSettings.count > 0 {
            self.plainSettings = []
            self.isDirty = true
        }
    }
    @discardableResult
    func removePlainSettings(at: Int) -> PlainSettings {
        let s = self.plainSettings.remove(at: at)
        self.isDirty = true
        return s
    }
    
    @discardableResult
    func replacePlainSettings(_ settings: PlainSettings, at: Int) -> PlainSettings {
        let p = self.plainSettings.remove(at: at)
        self.plainSettings.insert(settings, at: at)
        self.isDirty = true
        return p
    }
    
    @discardableResult
    func setSpecialSettings(url: URL, in format_settings: SettingsFormat) -> Bool
    {
        guard self.isAllSpecialSettingsPopulated else {
            return false
        }
        var found = false
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            if let props = self.specialSettings["UTIs"]?[uti] {
                if let v = props["syntax"] {
                    format_settings.specialSyntax = v
                }
                if let v = props["prepropcessor"] {
                    format_settings.specialPreprocessor = v
                }
                if let v = props["extra"] {
                    format_settings.specialAppendArguments = v
                }
                found = true
            }
        }
        let ext = url.pathExtension.lowercased()
        if let props = self.specialSettings["extensions"]?[ext] {
            if let v = props["syntax"] {
                format_settings.specialSyntax = v
            }
            if let v = props["prepropcessor"] {
                format_settings.specialPreprocessor = v
            }
            if let v = props["extra"] {
                format_settings.specialAppendArguments = v
            }
            found = true
        }
        return found
    }
    
    // MARK: - Highlight
    
    func getHighlightArguments() throws -> (theme: String, backgroundColor: String, arguments: [String]) {
        // Extra arguments for _highlight_ spliced in single arguments.
        // Warning: all white spaces that are not arguments separators must be quote protected.
        let extra = self.isArgumentsDefined && !self.arguments.isEmpty ? self.arguments : ""
        var extraHLFlags: [String] = extra.isEmpty ? [] : try extra.shell_parse_argv()
        
        /// Output format.
        let format = self.format
        
        // Show line numbers.
        if self.isLineLengthDefined && self.isLineNumbersVisible {
            extraHLFlags.append("--line-numbers")
            extraHLFlags.append("--wrap-no-numbers")
            if self.isLineNumbersFillToZeroes {
                extraHLFlags.append("--zeroes")
            }
        }
        
        // Word wrap and line length.
        if self.isWordWrapDefined && self.isWordWrapped, self.isWordWrappedHard {
            extraHLFlags.append(self.isWordWrappedIndented ? "--wrap" : "--wrap-simple")
            if self.isLineLengthDefined && self.lineLength > 0 {
                extraHLFlags.append("--line-length=\(self.lineLength)")
            }
        }
        
        // Convert tab to spaces.
        if self.isTabSpacesDefined && self.tabSpaces > 0 {
            extraHLFlags.append("--replace-tabs=\(self.tabSpaces)")
        }
        
        // Font family.
        if self.isFontNameDefined {
            if self.fontName.isEmpty || self.fontName == "-" {
                if format == .html {
                    extraHLFlags.append("--font=ui-monospace")
                } else {
                    let f = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                    extraHLFlags.append("--font=\(f.familyName ?? f.fontName)")
                }
            } else {
                extraHLFlags.append("--font=\(self.fontName)")
            }
        }
        
        // Font size.
        if self.isFontSizeDefined, self.fontSize > 0 {
            extraHLFlags.append(String(format: "--font-size=%.2f", self.fontSize * (format == .html ? 0.75 : 1)))
        }
        
        // Output format.
        extraHLFlags.append("--out-format=\(format.rawValue)")
        if format == .rtf {
            extraHLFlags.append("--page-color")
            extraHLFlags.append("--char-styles")
        }
        
        if isDebug {
            extraHLFlags.append("-v")
            extraHLFlags.append("-v") // more verbose.
        }
        let theme = self.getTheme()
        
        return (theme: theme.name, backgroundColor: theme.background, arguments: extraHLFlags)
    }
}

// MARK: -
class SettingsRendering: Settings, SettingsFormatProtocol, SettingsLSP {
    /// Name of theme overriding the light/dark settings
    var themeName: String
    /// Background color overriding the light/dark settings
    var backgroundColor: String
    var foregroundColor: String
    var themeLua: String
    var isLight: Bool?
    var vcsDiff: [String]
    
    // @available(macOS 12.0, *)
    lazy var isImage: Bool = false
    // @available(macOS 12.0, *)
    lazy var isPDF: Bool = false
    // @available(macOS 12.0, *)
    lazy var isMovie: Bool = false
    // @available(macOS 12.0, *)
    lazy var isAudio: Bool = false

    var isRenderingSupported: Bool = true
    
    var isOneLineFileDetected = false
    var logFile: URL?
    var isError: Bool = false
    
    override func isOSThemeLight() -> Bool {
        return self.isLight ?? super.isOSThemeLight()
    }
    
    dynamic var isAppendArgumentsDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isAppendArgumentsDefined)
        }
    }
    dynamic var appendArguments: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: appendArguments)
        }
    }
    
    dynamic var isPreprocessorDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isPreprocessorDefined)
        }
    }
    dynamic var preprocessor: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: preprocessor)
        }
    }
    
    dynamic var isSyntaxDefined: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: isSyntaxDefined)
        }
    }
    dynamic var syntax: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: syntax)
        }
    }
    
    var useLSP: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: useLSP)
        }
    }
    var lspExecutable: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspExecutable)
        }
    }
    var lspSyntax: String {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSyntax)
        }
    }
    var lspDelay: Int {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspDelay)
        }
    }
    var lspHover: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspHover)
        }
    }
    var lspSemantic: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSemantic)
        }
    }
    var lspSyntaxError: Bool {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspSyntaxError)
        }
    }
    var lspOptions: [String] {
        didSet {
            self.requestRefreshOnChanged(oldValue: oldValue, newValue: lspOptions)
        }
    }
    
    override var isCustomized: Bool {
        get {
            return super.isCustomized || isAppendArgumentsDefined || isPreprocessorDefined || isSyntaxDefined || isLSPCustomized
        }
    }
    
    convenience init(globalSettings: Settings, format: SettingsFormat?) {
        var d = globalSettings.toDictionary()
        if let f = format {
            d.merge(f.toDictionary()) { (_, new) in new }
        }
        self.init(settings: d)
        
        if !self.isPreprocessorDefined, let preprocessor = format?.specialPreprocessor {
            self.preprocessor = preprocessor
            self.isPreprocessorDefined = true
        }
        if !self.isAppendArgumentsDefined, let args = format?.specialAppendArguments {
            self.appendArguments = args
            self.isAppendArgumentsDefined = true
        }
        if !self.isSyntaxDefined, let syntax = format?.specialSyntax {
            self.syntax = syntax
            self.isSyntaxDefined = true
        }
    }
    
    required init(settings: [String : AnyHashable]) {
        self.themeName = ""
        self.backgroundColor = ""
        self.foregroundColor = ""
        self.themeLua = ""
        self.vcsDiff = []
        
        self.appendArguments = ""
        self.isAppendArgumentsDefined = false
        self.syntax = ""
        self.isSyntaxDefined = false
        self.preprocessor = ""
        self.isPreprocessorDefined = false
        
        self.useLSP = false
        self.lspExecutable = ""
        self.lspSyntax = ""
        self.lspDelay = 0
        self.lspHover = false
        self.lspSemantic = false
        self.lspSyntaxError = false
        self.lspOptions = []
        
        self.isOneLineFileDetected = false
        self.logFile = nil
        self.isError = false
        
        super.init(settings: settings)
    }
    
    override func override(fromDictionary dict: [String: AnyHashable]?) {
        guard let settings = dict else {
            return
        }
        super.override(fromDictionary: settings)
        
        if let v = settings[SettingsBase.Key.theme] as? String {
            self.themeName = v
        }
        if let v = settings[SettingsBase.Key.backgroundColor] as? String {
            self.backgroundColor = v
        }
        if let v = settings[SettingsBase.Key.foregroundColor] as? String {
            self.foregroundColor = v
        }
        if let v = settings[SettingsBase.Key.themeLua] as? String {
            self.themeLua = v
        }
        if let v = settings[SettingsBase.Key.vcsDiff] as? [String] {
            self.vcsDiff = v
        }
        
        self.isLight = settings["isLight"] as? Bool
        
        if #available(macOS 12.0, *) {
            if let v = settings["isImage"] as? Bool {
                self.isImage = v
            }
            if let v = settings["isPDF"] as? Bool {
                self.isPDF = v
            }
            if let v = settings["isMovie"] as? Bool {
                self.isMovie = v
            }
            if let v = settings["isAudio"] as? Bool {
                self.isAudio = v
            }
        }
        if let v = settings["isRenderingSupported"] as? Bool {
            self.isRenderingSupported = v
        }
        if let v = settings["isOneLineFileDetected"] as? Bool {
            self.isOneLineFileDetected = v
        }
        if let v = settings["logFile"] as? URL {
            self.logFile = v
        } else if let v = settings["logFile"] as? String {
            self.logFile = v.isEmpty ? nil : URL(fileURLWithPath: v)
        }
        if let v = settings["isError"] as? Bool {
            self.isError = v
        }
        
        if let args = settings[SettingsBase.Key.appendedExtraArguments] as? String, !args.trimmingCharacters(in: .whitespaces).isEmpty {
            self.appendArguments = args
            self.isAppendArgumentsDefined = true
        }
        
        if let syntax = settings[SettingsBase.Key.syntax] as? String {
            self.syntax = syntax
            self.isSyntaxDefined = true
        }
        
        if let preprocessor = settings[SettingsBase.Key.preprocessor] as? String {
            self.preprocessor = preprocessor
            self.isPreprocessorDefined = true
        }
        
        overrideLSP(fromDictionary: dict)
    }
    
    override func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r = super.toDictionary(forSaving: forSaving)
        
        r[SettingsBase.Key.theme] = themeName
        r[SettingsBase.Key.themeLua] = themeLua
        r[SettingsBase.Key.backgroundColor] = backgroundColor
        r[SettingsBase.Key.foregroundColor] = foregroundColor
        r[SettingsBase.Key.vcsDiff] = vcsDiff
        r["isLight"] = isLight
        
        if #available(macOS 12.0, *) {
            r["isImage"] = self.isImage
            r["isPDF"] = self.isPDF
            r["isMovie"] = self.isMovie
            r["isAudio"] = self.isAudio
        }
        r["isRenderingSupported"] = self.isRenderingSupported
        r["isOneLineFileDetected"] = self.isOneLineFileDetected
        r["logFile"] = self.logFile?.path
        r["isError"] = self.isError
        
        if isAppendArgumentsDefined {
            r[SettingsBase.Key.appendedExtraArguments] = appendArguments
        }
        if isSyntaxDefined {
            r[SettingsBase.Key.syntax] = syntax
        }
        if isPreprocessorDefined {
            r[SettingsBase.Key.preprocessor] = preprocessor
        }
        
        lspToDictionary(dict: &r, forSaving: forSaving)
        
        return r
    }
    
    override func getTheme() -> ThemeBaseColor {
        if !themeName.isEmpty {
            return (name: self.themeName, background: self.backgroundColor, foreground: self.foregroundColor)
        }
        return super.getTheme()
    }
    
    override func getHighlightArguments() throws -> (theme: String, backgroundColor: String, arguments: [String]) {
        var r = try super.getHighlightArguments()
        if isUsingLSP {
            r.arguments.append("--ls-exec=\(self.lspExecutable)")
            if self.lspDelay > 0 {
                r.arguments.append("--ls-delay=\(self.lspDelay)")
            }
            if !self.lspSyntax.isEmpty {
                r.arguments.append("--ls-syntax=\(self.lspSyntax)")
            }
            if self.lspHover {
                r.arguments.append("--ls-hover")
            }
            if self.lspSemantic {
                r.arguments.append("--ls-semantic")
            }
            if self.lspSyntaxError {
                r.arguments.append("--ls-syntax-error")
            }
            if !self.lspOptions.isEmpty {
                var o: [String] = []
                for opt in self.lspOptions {
                    guard !opt.isEmpty else { continue }
                    o.append("--ls-option=\(opt)")
                }
                r.arguments.append(o.joined(separator: "•"))
            }
        }
        return r
    }
}
