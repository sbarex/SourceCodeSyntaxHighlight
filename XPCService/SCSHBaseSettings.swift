//
//  SCSHCommonSettings.swift
//  Syntax Highlight
//
//  Created by Sbarex on 26/11/2019.
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

import Foundation


class SCSHBaseSettings {
    /// Outout format.
    enum Format: String {
        case html
        case rtf
    }

    /// Line numbers visibility.
    enum LineNumbers {
        case hidden
        case visible(omittingWrapLines: Bool)
    }

    /// Word wrap mode.
    enum WordWrap: Int {
        case off
        case simple
        case standard
    }
    
    public struct Key {
        static let lightTheme = "theme-light"
        static let lightBackgroundColor = "theme-light-color"
        static let darkTheme = "theme-dark"
        static let darkBackgroundColor = "theme-dark-color"
        
        static let theme = "theme"
        static let backgroundColor = "theme-color"
        
        static let lineNumbers = "line-numbers"
        static let lineNumbersOmittedWrap = "line-numbers-omitted-wrap"
        
        static let wordWrap = "word-wrap"
        static let lineLength = "line-length"
        
        static let tabSpaces = "tab-spaces"
        
        static let highlightPath = "highlight"

        static let format = "format"
        
        static let extraArguments = "extra"
        static let appendedExtraArguments = "uti-extra"
        
        static let fontFamily = "font-family"
        static let fontSize = "font-size"
        
        static let debug = "debug"
        
        static let renderForExtension = "appex"
        
        static let customizedUTISettings = "uti-settings"
        
        static let connectedUTI = "uti"

        static let customCSS = "css"
        static let preprocessor = "preprocessor"
        
        static let interactive = "interactive"
        static let version = "version"
        
    }
    
    /// Current settings version handled by the applications.
    static let version: Float = 2.1
    
    // MARK: - Properties
    
    /// Version of the settings.
    var version: Float = 0
    
    /// Name of theme for light visualization.
    var lightTheme: String?
    /// Background color for the rgb view in light theme.
    var lightBackgroundColor: String?
    
    /// Name of theme for dark visualization.
    var darkTheme: String?
    /// Background color for the rgb view in dark theme.
    var darkBackgroundColor: String?
    
    /// Show line numbers.
    var lineNumbers: LineNumbers?
    /// Word wrap mode.
    var wordWrap: WordWrap?
    /// Line length for word wrap.
    var lineLength: Int?
    
    /// Number of spaces use for a tab. Set to 0 to disable converting tab to spaces.
    var tabSpaces: Int?
    
    /// Extra arguments for highlight.
    var extra: String?
    
    var fontFamily: String?
    var fontSize: CGFloat?
    
    /// Custom style sheet.
    /// When the settings are stored the value is written to a file.
    /// When nil use the css stored on file, if exists.
    var css: String?
    
    var preprocessor: String?
    
    /// If true enable js action on the quicklook preview but disable dblclick and click and drag on window.
    var allowInteractiveActions: Bool?
    
    /// Return if exists customized settings.
    /// Global settings are always customized.
    var isCustomized: Bool {
        if !(lightTheme?.isEmpty ?? true) || !(darkTheme?.isEmpty ?? true) || lineNumbers != nil || fontFamily != nil || wordWrap != nil || lineLength != nil || tabSpaces != nil || !(extra?.isEmpty ?? true) || preprocessor != nil || allowInteractiveActions != nil || !(css?.isEmpty ?? true) {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Initialisers
    
    init(settings: [String: Any]) {
        version = settings[Key.version] as? Float ?? 1
        
        lightTheme = settings[Key.lightTheme] as? String
        lightBackgroundColor = settings[Key.lightBackgroundColor] as? String
        
        darkTheme = settings[Key.darkTheme] as? String
        darkBackgroundColor = settings[Key.darkBackgroundColor] as? String
        
        if let ln = settings[Key.lineNumbers] as? Bool {
            lineNumbers = ln ? .visible(omittingWrapLines: settings[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        } else {
            lineNumbers = nil
        }
        
        wordWrap = WordWrap(rawValue: settings[Key.wordWrap] as? Int ?? -1)
        lineLength = settings[Key.lineLength] as? Int
        
        tabSpaces = settings[Key.tabSpaces] as? Int
        
        extra = settings[Key.extraArguments] as? String
        
        fontFamily = settings[Key.fontFamily] as? String
        fontSize = settings[Key.fontSize] as? CGFloat
        
        css = settings[Key.customCSS] as? String
        
        preprocessor = settings[Key.preprocessor] as? String
        
        allowInteractiveActions = settings[Key.interactive] as? Bool
    }
    
    /// Create a global settings.
    convenience init() {
        self.init(settings: [:])
    }
    
    /// Initialize the setting based on the preferences provided.
    convenience init(settings: SCSHBaseSettings) {
        self.init(settings: settings.toDictionary())
    }
    
    // MARK: - Methods
    
    /// Output the settings to a dictionary.
    /// Only customized options are exported.
    func toDictionary() -> [String: Any] {
        guard self.isCustomized else {
            return [:]
        }
        
        var r: [String: Any] = [:]
        
        if let lightTheme = self.lightTheme {
            r[Key.lightTheme] = lightTheme
            r[Key.lightBackgroundColor] = lightBackgroundColor ?? "ffffff"
        }
        if let darkTheme = self.darkTheme {
            r[Key.darkTheme] = darkTheme
            r[Key.darkBackgroundColor] = darkBackgroundColor ?? "000000"
        }
        if let wordWrap = self.wordWrap {
            r[Key.wordWrap] = wordWrap.rawValue
        }
        if let lineLength = self.lineLength {
            r[Key.lineLength] = lineLength
        }
        if let tabSpaces = self.tabSpaces {
            r[Key.tabSpaces] = tabSpaces
        }
        if let extra = self.extra {
            r[Key.extraArguments] = extra
        }
        if let fontFamily = self.fontFamily {
            r[Key.fontFamily] = fontFamily
        }
        if let fontSize = self.fontSize {
            r[Key.fontSize] = fontSize
        }
        
        if let css = self.css {
            r[Key.customCSS] = css
        }
        
        if let preprocessor = self.preprocessor, !preprocessor.isEmpty {
            r[Key.preprocessor] = preprocessor
        }
        
        if let lineNumbers = self.lineNumbers {
            switch lineNumbers {
            case .hidden:
                r[Key.lineNumbers] = false
            case .visible(let omittingWrapLines):
                r[Key.lineNumbers] = true
                r[Key.lineNumbersOmittedWrap] = omittingWrapLines
            }
        }
        
        if let allowInteractiveActions = self.allowInteractiveActions {
            r[Key.interactive] = allowInteractiveActions
        }
        
        return r
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    func override(fromDictionary dict: [String: Any]?) {
        guard let data = dict else {
            return
        }
        
        // Light theme.
        if let v = data[Key.lightTheme] as? String {
            self.lightTheme = v
        }
        // Light background color.
        if let v = data[Key.lightBackgroundColor] as? String {
            self.lightBackgroundColor = v
        }
        
        // Dark theme.
        if let v = data[Key.darkTheme] as? String {
            self.darkTheme = v
        }
        // Dark background color.
        if let v = data[Key.darkBackgroundColor] as? String {
            self.darkBackgroundColor = v
        }
        
        // Font family.
        if let v = data[Key.fontFamily] as? String {
            self.fontFamily = v
        }
        // Font size.
        if let v = data[Key.fontSize] as? CGFloat {
            self.fontSize = v
        }
        
        // Show line numbers.
        if let v = data[Key.lineNumbers] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: data[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        }
        
        if let v = data[Key.wordWrap] as? Int {
            self.wordWrap = WordWrap(rawValue: v) ?? .off
        }
        if let v = data[Key.lineLength] as? Int {
            self.lineLength = v
        }
        
        // Convert tab to spaces.
        if let v = data[Key.tabSpaces] as? Int {
            self.tabSpaces = v
        }
        
        // Extra arguments for _highlight_.
        if let v = data[Key.extraArguments] as? String {
            self.extra = v
        }
        
        if let v = data[Key.customCSS] as? String {
            self.css = v
        }
        
        if let v = data[Key.preprocessor] as? String {
            self.preprocessor = v
        }
    
        if let v = data[Key.interactive] as? Bool {
            self.allowInteractiveActions = v
        }
    }
    
    func override(fromSettings settings: SCSHBaseSettings) {
        override(fromDictionary: settings.toDictionary())
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    func overriding(fromDictionary override: [String: Any]?) -> SCSHBaseSettings {
        preconditionFailure("This method must be overridden")
    }
}

// MARK: - Global settings

class SCSHGlobalBaseSettings: SCSHBaseSettings {
    // MARK: - Properties
    /// Name of theme overriding the light/dark settings
    var theme: String?
    /// Background color overriding the light/dark settings
    var backgroundColor: String?
    
    /// Path of highlight executable.
    /// Empty or "-" for use the embedded version.
    var highlightProgramPath: String = "-"
    /// Output format.
    var format: Format?
    
    /// Debug mode.
    var debug = false
    
    /// Indicate if the output is for the quicklook extension.
    var renderForExtension = true
    
    /// Customized settings for UTIs.
    var customizedSettings: [String: SCSHUTIBaseSettings] = [:]
    
    /// Return if exists customized settings.
    override var isCustomized: Bool {
        // Global settings are always customized.
        return true
    }
    
    // MARK: - Initialisers
    override required init(settings: [String: Any]) {
        self.highlightProgramPath = settings[Key.highlightPath] as? String ?? ""
        if self.highlightProgramPath == "" {
            // Use embedded highlight.
            self.highlightProgramPath = "-"
        }
        
        self.format = Format(rawValue: settings[Key.format] as? String ?? "")
        
        customizedSettings = [:]
        if let custom_formats = settings[Key.customizedUTISettings] as? [String: [String: Any]] {
            for (uti, uti_settings) in custom_formats {
                let s = type(of: self).createSettings(forUTI: uti, settings: uti_settings)
                customizedSettings[uti] = s
            }
        }
        
        debug = settings[Key.debug] as? Bool ?? false
        
        theme = settings[Key.theme] as? String
        backgroundColor = settings[Key.backgroundColor] as? String
        
        super.init(settings: settings)
        
        // Fill with defaults value
        if lightTheme == nil {
            lightTheme = "edit-xcode"
        }
        if darkTheme == nil {
            darkTheme = "edit-xcode"
        }
        if lineNumbers == nil {
            lineNumbers = .visible(omittingWrapLines: true)
        }
        if wordWrap == nil {
            wordWrap = .off
        }
        if lineLength == nil {
            lineLength = 80
        }
        if tabSpaces == nil {
            tabSpaces = 4
        }

        if format == nil {
            format = .html
        }
        
        if extra == nil {
            extra = ""
        }
        
        if fontFamily == nil {
            fontFamily = "Menlo"
        }
        if fontSize == nil {
            fontSize = 12
        }
        
        if allowInteractiveActions == nil {
            allowInteractiveActions = false
        }
    }
    
    /// Initialize the setting based on the preferences provided.
    convenience init(settings: SCSHGlobalBaseSettings) {
        self.init(settings: settings.toDictionary())
    }
    
    /// Create a global settings.
    convenience init() {
        self.init(settings: [:])
    }
    
    /// Initialize from a preferences loaded from the domain defaults.
    convenience init(defaultsDomain domain: String) {
        let defaults = UserDefaults.standard
        // Remember that macOS store the precerences inside a cache. If you manual edit the preferences file you need to reset this cache:
        // $ killall -u $USER cfprefsd
        let defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        self.init(settings: defaultsDomain)
    }
    
    // MARK: - Methods
    
    /// Output the settings to a dictionary.
    /// Only customized options are exported.
    override func toDictionary() -> [String: Any] {
        var r: [String: Any] = super.toDictionary()
        
        r[Key.highlightPath] = self.highlightProgramPath
        if let format = self.format {
            r[Key.format] = format.rawValue
        }
        
        r[Key.renderForExtension] = self.renderForExtension
        
        var customized_formats: [String: [String: Any]] = [:]
        for (uti, settings) in self.customizedSettings {
            let d = settings.toDictionary()
            if d.count > 0 {
                customized_formats[uti] = d
            }
        }
        r[Key.customizedUTISettings] = customized_formats
        
        if let theme = self.theme {
            r[Key.theme] = theme
        }
        if let color = self.backgroundColor {
            r[Key.backgroundColor] = color
        }
        
        r[Key.debug] = self.debug
        r[Key.version] = SCSHBaseSettings.version
        
        return r
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    override func override(fromDictionary dict: [String: Any]?) {
        guard let data = dict else {
            return
        }
        
        if let v = data[Key.highlightPath] as? String {
            self.highlightProgramPath = v
        }
        
        // Forcing a theme.
        if let _ = data.keys.first(where: { $0 == Key.theme }) {
            self.theme = data[Key.theme] as? String
        }
        // Forcing a background color.
        if let _ = data.keys.first(where: { $0 == Key.backgroundColor }) {
            self.backgroundColor = data[Key.backgroundColor] as? String
        }
        
        // Output format.
        if let v = data[Key.format] as? String, let f = Format(rawValue: v) {
            self.format = f
        }
        if let customized_formats = data[Key.customizedUTISettings] as? [String: [String: Any]] {
            self.customizedSettings = [:]
            for (uti, dict) in customized_formats {
                let uti_settings = type(of: self).createSettings(forUTI: uti, settings: dict)
                self.customizedSettings[uti] = uti_settings
            }
        }
        // Debug
        if let debug = data[Key.debug] as? Bool {
            self.debug = debug
        }
        
        if let v = data[Key.renderForExtension] as? Bool {
            self.renderForExtension = v
        }
        
        super.override(fromDictionary: dict)
    }
    
    func override(fromSettings settings: SCSHGlobalBaseSettings) {
        override(fromDictionary: settings.toDictionary())
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    override func overriding(fromDictionary override: [String: Any]?) -> SCSHGlobalBaseSettings {
        let settings_type = type(of: self)
        let final_settings = settings_type.init(settings: self.toDictionary())
        if let o = override {
            final_settings.override(fromDictionary: o)
        }
        return final_settings
    }
    
    
    // MARK: - UTIs
    
    class func createSettings(forUTI uti: String, settings: [String: Any]) -> SCSHUTIBaseSettings {
        return SCSHUTIBaseSettings.init(UTI: uti, settings: settings)
    }
    
    /// Get customized settings for a UTI.
    /// If not exists it will be created.
    /// Return a settings with set only the customized values, global settings are ignored.
    func getCustomizedSettings(forUTI uti: String) -> SCSHUTIBaseSettings? {
        if let s = self.customizedSettings[uti] {
            return s
        } else {
            let s = type(of: self).createSettings(forUTI: uti, settings: [:])
            self.customizedSettings[uti] = s
            return s
        }
    }
    
    // Register a new customized UTI settings.
    func setCustomizedSettingsForUTI(_ settings: SCSHUTIBaseSettings) {
        self.customizedSettings[settings.uti] = settings
    }
    
    func removeCustomizedSettings(forUTI uti: String) -> SCSHUTIBaseSettings? {
        return self.customizedSettings.removeValue(forKey: uti)
    }
    
    /// Returns if a customized settings exists for the specified UTI.
    func hasCustomizedSettings(forUTI uti: String) -> Bool {
        if let s = self.customizedSettings[uti] {
            return s.isCustomized
        } else {
            return false
        }
    }

    /// Clear all customized settings for UTIs.
    func clearAllCustomizedSettings() {
        self.customizedSettings = [:]
    }
    
    /// Get the effective settings for a UTI.
    /// The returned settings is based on global values, overriden with the customized settings specific for the requested UTI.
    func getGlobalSettings(forUTI uti: String) -> SCSHGlobalBaseSettings {
        let settings_type = type(of: self)
        let settings = settings_type.init(settings: self.toDictionary())
        
        if let utiSettings = self.customizedSettings[uti] {
            settings.override(fromSettings: utiSettings)
            
            if let extra = utiSettings.appendedExtra, !extra.isEmpty {
                settings.extra = (settings.extra != nil ? settings.extra! + " " : "") + extra
            }
        }
        
        return settings
    }
    
    // MARK: Colorize
    
    func getHighlightArguments() throws -> (theme: String, backgroundColor: String, arguments: [String]) {
        // Extra arguments for _highlight_ spliced in single arguments.
        // Warning: all white spaces that are not arguments separators must be quote protected.
        let extra = self.extra?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        var extraHLFlags: [String] = extra.isEmpty ? [] : try extra.shell_parse_argv()
        
        let defaults = UserDefaults.standard
        
        /// Output format.
        let format = self.format ?? .html
        let isOSThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        
        let theme = isOSThemeLight ? lightTheme ?? "edit-xcode" : darkTheme ?? "neon"
        let themeBackground = isOSThemeLight ? lightBackgroundColor ?? "#ffffff" : darkBackgroundColor ?? "#000000"
        
        // Show line numbers.
        if let lineNumbers = self.lineNumbers {
            switch lineNumbers {
            case .hidden:
                break
            case .visible(let omittingWrapLines):
                extraHLFlags.append("--line-numbers")
                if omittingWrapLines {
                    extraHLFlags.append("--wrap-no-numbers")
                }
            }
        }
        
        // Word wrap and line length.
        if let wordWrap = self.wordWrap, wordWrap != .off {
            if let lineLength = self.lineLength {
                extraHLFlags.append("--line-length=\(lineLength)")
            }
            extraHLFlags.append(wordWrap == .simple ? "-V" : "-W")
        }
        
        // Convert tab to spaces.
        if let space = tabSpaces, space > 0 {
            extraHLFlags.append("--replace-tabs=\(space)")
        }
        
        // Font family.
        if let font = fontFamily, !font.isEmpty {
            extraHLFlags.append("--font=\(font)")
        }
        
        // Font size.
        if let fontSize = fontSize, fontSize > 0 {
            extraHLFlags.append(String(format: "--font-size=%.2f", fontSize * (format == .html ? 0.75 : 1)))
        }
        
        // Output format.
        extraHLFlags.append("--out-format=\(format.rawValue)")
        if format == .rtf {
            extraHLFlags.append("--page-color")
            extraHLFlags.append("--char-styles")
        }
        
        return (theme: theme, backgroundColor: themeBackground, arguments: extraHLFlags)
    }
}

// MARK: - UTIs settings

class SCSHUTIBaseSettings: SCSHBaseSettings {
    // MARK: - Properties
    /// UTI associated to this settings. Is empty for globals settings.
    let uti: String
    
    /// Extra arguments added to the global arguments relative to the associated UTI.
    var appendedExtra: String?
    
    override var isCustomized: Bool {
        return !(appendedExtra?.isEmpty ?? true) || super.isCustomized
    }
    
    // MARK: - Initialisers
    
    required init(UTI uti: String, settings: [String: Any]) {
        self.uti = uti
        
        super.init(settings: settings)
    }
    
    /// Create a settings specific to an UTI.
    convenience init(UTI uti: String) {
        self.init(UTI: uti, settings: [:])
    }
    
    /// Initialize the setting based on the preferences provided.
    convenience init(settings: SCSHUTIBaseSettings) {
        self.init(UTI: settings.uti, settings: settings.toDictionary())
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    override func overriding(fromDictionary override: [String: Any]?) -> SCSHUTIBaseSettings {
        let settings_type = type(of: self)
        let final_settings = settings_type.init(UTI: self.uti, settings: self.toDictionary())
        if let o = override {
            final_settings.override(fromDictionary: o)
        }
        return final_settings
    }
    
    override func toDictionary() -> [String : Any] {
        var r = super.toDictionary()
        if let utiExtra = appendedExtra {
            r[Key.appendedExtraArguments] = utiExtra
        }
        
        return r
    }
    
    override func override(fromDictionary dict: [String : Any]?) {
        super.override(fromDictionary: dict)
        if let v = dict?[Key.appendedExtraArguments] as? String {
            self.appendedExtra = v
        }
    }
}
