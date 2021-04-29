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
        static let darkTheme = "theme-dark"
        static let darkBackgroundColor = "theme-dark-color"
        
        static let theme = "theme"
        static let backgroundColor = "theme-color"
        static let themeLua = "theme-lua"
        
        static let lineNumbers = "line-numbers"
        static let lineNumbersOmittedWrap = "line-numbers-omitted-wrap"
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
        static let debug = "debug"
        
        static let customizedUTISettings = "uti-settings"
        
        static let connectedUTI = "uti"
        
        static let specialSettings = "specialSettings"

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
    dynamic var isLineNumbersOmittedForWrap: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isLineNumbersOmittedForWrap)
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
    dynamic var isWordWrappedSoftForOnleLineFiles: Bool {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isWordWrappedSoftForOnleLineFiles)
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
    /// If true enable js action on the quicklook preview but disable dblclick and click and drag on window.
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
    
    // MARK:
    internal var lockDirty = 0
    @objc dynamic var isDirty = false {
        didSet {
            if oldValue != isDirty && lockDirty == 0 {
                NotificationCenter.default.post(name: .SettingsIsDirty, object: self)
            }
        }
    }
    
    var isCustomized: Bool {
        get {
            return isFormatDefined || isLightThemeNameDefined || isDarkThemeNameDefined || isLineNumbersDefined || isWordWrapDefined || isLineLengthDefined || isTabSpacesDefined || isArgumentsDefined || isCSSDefined || isFormatDefined || isFontSizeDefined || isAllowInteractiveActionsDefined
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
        self.darkThemeName = "neon"
        isDarkThemeNameDefined = false
        self.darkBackgroundColor = "#333333"
        
        self.isLineNumbersVisible = false
        self.isLineNumbersDefined = false
        self.isLineNumbersOmittedForWrap = true
        self.isLineNumbersFillToZeroes = false
        
        self.isWordWrapped = false
        self.isWordWrappedHard = false
        self.isWordWrappedIndented = false
        self.isWordWrappedSoftForOnleLineFiles = true
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
        
        super.init()
        lockDirty += 1
        self.override(fromDictionary: settings)
        self.isDirty = false
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
        
        // Dark theme.
        if let theme = settings[SettingsBase.Key.darkTheme] as? String {
            self.darkThemeName = theme
            isDarkThemeNameDefined = true
        }
        // Dark background color.
        if let color = settings[SettingsBase.Key.darkBackgroundColor] as? String {
            self.darkBackgroundColor = color
        }
        
        // Show line numbers.
        if let ln = settings[SettingsBase.Key.lineNumbers] as? Bool {
            self.isLineNumbersVisible = ln
            self.isLineNumbersDefined = true
            self.isLineNumbersOmittedForWrap = settings[SettingsBase.Key.lineNumbersOmittedWrap] as? Bool ?? true
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
           self.isWordWrappedSoftForOnleLineFiles = v
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
        if let args = settings[SettingsBase.Key.extraArguments] as? String {
            self.arguments = args
            self.isArgumentsDefined = true
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
        }
        if isDarkThemeNameDefined {
            r[SettingsBase.Key.darkTheme] = darkThemeName
            r[SettingsBase.Key.darkBackgroundColor] = darkBackgroundColor
        }
        if isWordWrapDefined {
            r[SettingsBase.Key.wordWrap] = isWordWrapped ? (isWordWrappedIndented ? 2 : 1) : 0
            r[SettingsBase.Key.wordWrapHard] = isWordWrappedHard
            r[SettingsBase.Key.wordWrapOneLineFiles] = isWordWrappedSoftForOnleLineFiles
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
            r[SettingsBase.Key.lineNumbersOmittedWrap] = isLineNumbersOmittedForWrap
            r[SettingsBase.Key.lineNumbersFillToZeroes] = isLineNumbersFillToZeroes
        }
        
        if isAllowInteractiveActionsDefined {
            r[SettingsBase.Key.interactive] = allowInteractiveActions
        }
        
        return r
    }
    
    
    func getTheme() -> (name: String, color: String) {
        let isOSThemeLight = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        
        let theme: String
        let themeBackground: String
        if isOSThemeLight {
            theme = self.isLightThemeNameDefined ? self.lightThemeName : "edit-xcode"
            themeBackground = self.isLightThemeNameDefined ? self.lightBackgroundColor : "#ffffff"
        } else {
            theme = self.isDarkThemeNameDefined ? self.darkThemeName : "neon"
            themeBackground = self.isDarkThemeNameDefined ? self.darkBackgroundColor : "#000000"
        }
        
        return (name: theme, color: themeBackground)
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
    
    var isSpecialSettingsPopulated: Bool = false
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
            return super.isCustomized || (isPreprocessorDefined && !preprocessor.isEmpty) || (isAppendArgumentsDefined && !appendArguments.isEmpty) || (isSyntaxDefined || !syntax.isEmpty) || isLSPCustomized
        }
    }
      
    convenience init (uti: String, settings: [String: AnyHashable]) {
        var s = settings
        s[SettingsBase.Key.connectedUTI] = uti
        self.init(settings: s)
    }
    
    required internal init(settings: [String: AnyHashable]) {
        self.uti = settings[SettingsBase.Key.connectedUTI] as! String
        
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
        
        if let args = settings[SettingsBase.Key.appendedExtraArguments] as? String {
            self.appendArguments = args
            self.isAppendArgumentsDefined = !args.isEmpty
        }
        
        if let syntax = settings[SettingsBase.Key.syntax] as? String {
            self.syntax = syntax
            self.isSyntaxDefined = !syntax.isEmpty
        }
        
        if let preprocessor = settings[SettingsBase.Key.preprocessor] as? String {
            self.preprocessor = preprocessor
            self.isPreprocessorDefined = !preprocessor.isEmpty
        }
        
        overrideLSP(fromDictionary: dict)
        
        if let specials = settings[SettingsBase.Key.specialSettings] as? [String: String] {
            if let v = specials[SettingsBase.Key.preprocessor] {
                self.specialPreprocessor = v
            }
            if let v = specials[SettingsBase.Key.syntax] {
                self.specialSyntax = v
            }
            if let v = specials[SettingsBase.Key.appendedExtraArguments] {
                self.specialAppendArguments = v
            }
        }
    }
    
    override func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r = super.toDictionary(forSaving: forSaving)
        
        if isAppendArgumentsDefined, !appendArguments.isEmpty {
            r[SettingsBase.Key.appendedExtraArguments] = appendArguments
        }
        if isSyntaxDefined, !syntax.isEmpty {
            r[SettingsBase.Key.syntax] = syntax
        }
        if isPreprocessorDefined, !preprocessor.isEmpty {
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
            if let appendArguments = self.specialAppendArguments {
                special[SettingsBase.Key.appendedExtraArguments] = appendArguments
            }
            if !special.isEmpty {
                r[SettingsBase.Key.specialSettings] = special
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
    static let version: Float = 2.3
    
    /// Version of the settings.
    var version: Float = 0
    
    var isAllSpecialSettingsPopulated: Bool = false
    var isAllCSSPopulated: Bool = false
    
    dynamic var isDebug: Bool = false {
        didSet {
            requestRefreshOnChanged(oldValue: oldValue, newValue: isDebug)
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
        
        self.isDebug = false
        self.maxData = 0
        self.convertEOL = false
        
        self.utiSettings = [:]
        
        super.init(settings: settings)
        
        if let custom_formats = settings[SettingsBase.Key.customizedUTISettings] as? [String: [String: AnyHashable]] {
            for (uti, uti_settings) in custom_formats {
                self.utiSettings[uti] = SettingsFormat(uti: uti, settings: uti_settings)
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
        
        if let v = settings[SettingsBase.Key.debug] as? Bool {
            self.isDebug = v
        }
        if let v = settings[SettingsBase.Key.maxData] as? UInt64 {
            self.maxData = v
        }
        if let v = settings[SettingsBase.Key.convertEOL] as? Bool {
            self.convertEOL = v
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
    }
    
    /// Output the settings to a dictionary.
    override func toDictionary(forSaving: Bool = false) -> [String: AnyHashable] {
        var r = super.toDictionary(forSaving: forSaving)
        
        r[SettingsBase.Key.debug] = self.isDebug
        r[SettingsBase.Key.maxData] = self.maxData
        r[SettingsBase.Key.convertEOL] = self.convertEOL
        
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
            if self.isLineNumbersOmittedForWrap {
                extraHLFlags.append("--wrap-no-numbers")
            }
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
        
        return (theme: theme.name, backgroundColor: theme.color, arguments: extraHLFlags)
    }
}

// MARK: -
class SettingsRendering: Settings, SettingsFormatProtocol, SettingsLSP {
    /// Name of theme overriding the light/dark settings
    var themeName: String
    /// Background color overriding the light/dark settings
    var backgroundColor: String
    var themeLua: String
    
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
            return super.isCustomized || (isAppendArgumentsDefined && !appendArguments.isEmpty) || (isPreprocessorDefined && !preprocessor.isEmpty) || (isSyntaxDefined && !syntax.isEmpty) || isLSPCustomized
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
        self.themeLua = ""
        
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
        if let v = settings[SettingsBase.Key.themeLua] as? String {
            self.themeLua = v
        }
        
        if let args = settings[SettingsBase.Key.appendedExtraArguments] as? String {
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
        
        if isAppendArgumentsDefined, !appendArguments.isEmpty {
            r[SettingsBase.Key.appendedExtraArguments] = appendArguments
        }
        if isSyntaxDefined, !syntax.isEmpty {
            r[SettingsBase.Key.syntax] = syntax
        }
        if isPreprocessorDefined, !preprocessor.isEmpty {
            r[SettingsBase.Key.preprocessor] = preprocessor
        }
        
        lspToDictionary(dict: &r, forSaving: forSaving)
        
        return r
    }
    
    override func getTheme() -> (name: String, color: String) {
        if !themeName.isEmpty {
            return (name: self.themeName, color: self.backgroundColor)
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
