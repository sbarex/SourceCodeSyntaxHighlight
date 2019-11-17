//
//  SCSHSettings.swift
//  SCSHXPCService
//
//  Created by sbarex on 18/10/2019.
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

enum SCSHFormat: String {
    case html
    case rtf
}

enum SCSHLineNumbers {
    case hidden
    case visible(omittingWrapLines: Bool)
}

enum SCSHWordWrap: Int {
    case off
    case simple
    case standard
}

struct SCSHSettings {
    public struct Key {
        static let lightTheme = "theme-light"
        static let darkTheme = "theme-dark"
        static let theme = "theme"
        static let lightThemeIsBase16 = "theme-light-is16"
        static let darkThemeIsBase16 = "theme-dark-is16"
        static let themeIsBase16 = "theme-is16"
        
        static let rtfLightBackgroundColor = "rtf-background-color-light"
        static let rtfDarkBackgroundColor = "rtf-background-color-dark"
        static let rtfBackgroundColor = "rtf-background-color"
        
        static let lineNumbers = "line-numbers"
        static let lineNumbersOmittedWrap = "line-numbers-omitted-wrap"
        
        static let wordWrap = "word-wrap"
        static let lineLength = "line-length"
        
        static let tabSpaces = "tab-spaces"
        
        static let highlightPath = "highlight"
    
        static let format = "format"
        
        static let extraArguments = "extra"
        static let utiExtraArguments = "uti-extra"
        
        static let fontFamily = "font-family"
        static let fontSize = "font-size"
        
        static let debug = "debug"
        
        static let embedCustomStyle = "embed-style"
        
        static let customizedUTISettings = "uti-settings"
        
        static let connectedUTI = "uti"
        
        static let customCSS = "css"
        static let preprocessor = "preprocessor"
    }
    
    /// Path of highlight executable.
    var highlightProgramPath: String = "-"
    
    /// UTI associated to this settings. Is empty for globals settings.
    let uti: String
    
    /// Return if the settings are globals for all file format or specific to a single UTI.
    var isGlobal: Bool {
        return uti.isEmpty
    }
    
    /// Return if exists customized settings.
    /// Global settings are always customized.
    var isCustomized: Bool {
        if isGlobal {
            // Le impostazioni globali sono per definizione personalizzate.
            return true
        } else {
            if utiExtra != nil && utiExtra != "" {
                // Per l'uti collegato sono stati specificati dei parametri extra.
                return true
            } else if (lightTheme != nil && lightTheme != "") || (darkTheme != nil && darkTheme != "") || lineNumbers != nil || fontFamily != nil || wordWrap != nil || lineLength != nil || tabSpaces != nil || extra != nil || preprocessor != nil {
                return true
            } else if let css = self.css {
                return isGlobal ? !css.isEmpty : true
            } else {
                return false
            }
        }
    }
    
    /// Name of theme for light visualization.
    var lightTheme: String?
    /// Light theme is Base16.
    var lightThemeIsBase16: Bool?
    /// Name of theme for dark visualization.
    var darkTheme: String?
    /// Dark theme is Base16.
    var darkThemeIsBase16: Bool?
    
    /// Background color for the rgb view in light theme.
    var rtfLightBackgroundColor: String?
    /// Background color for the rgb view in dark theme.
    var rtfDarkBackgroundColor: String?
    
    /// Name of theme overriding the light/dark settings
    var theme: String?
    /// Theme is Base16.
    var themeIsBase16: Bool?
    /// Background color overriding the light/dark settings
    var rtfBackgroundColor: String?
    
    /// Show line number.
    var lineNumbers: SCSHLineNumbers?
    var wordWrap: SCSHWordWrap?
    var lineLength: Int?
    
    /// Number of spaces use for a tab. Set to 0 to disable converting tab to spaces.
    var tabSpaces: Int?
    
    /// Extra arguments for highlight.
    var extra: String?
    /// Extra arguments added to the common arguments relative to the associated UTI.
    var utiExtra: String?
    
    /// Output format.
    var format: SCSHFormat?
    
    var fontFamily: String?
    var fontSize: Float?
    
    var debug = false
    
    /// Embed custom style in the output.
    var embedCustomStyle = true
    
    /// Domain for storing defaults.
    let domain: String
    
    var css: String?
    var preprocessor: String?
    var customizedSettings: [String: SCSHSettings] = [:]
    
    /// Create a global settings.
    init() {
        self.init(UTI: "")
    }
    
    /// Create a settings specific to an UTI.
    init(UTI: String) {
        self.domain = ""
        self.uti = UTI
    }
    
    /// Dictionary base initialization.
    init(dictionary: [String: Any]) {
        if let uti = dictionary[Key.connectedUTI] as? String {
            self.uti = uti
        } else {
            self.uti = ""
        }
        self.domain = ""
        self.override(fromDictionary: dictionary)
    }
    
    /// Initialize the setting based on the preferences provided.
    init(settings: SCSHSettings) {
        self.init(dictionary: settings.toDictionary())
    }
    
    /// Initialize from a preferences loaded from the domain defaults.
    init(domain: String) {
        self.domain = domain
        self.uti = ""
        
        let defaults = UserDefaults.standard
        let defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        
        self.highlightProgramPath = defaultsDomain[Key.highlightPath] as? String ?? "-"
        if self.highlightProgramPath == "" {
            // Use embedded highlight.
            self.highlightProgramPath = "-"
        }
        
        self.lightTheme = defaultsDomain[Key.lightTheme] as? String ?? "edit-xcode"
        self.lightThemeIsBase16 = defaultsDomain[Key.lightThemeIsBase16] as? Bool ?? false
        self.rtfLightBackgroundColor = defaultsDomain[Key.rtfLightBackgroundColor] as? String
        
        self.darkTheme = defaultsDomain[Key.darkTheme] as? String ?? "edit-xcode"
        self.darkThemeIsBase16 = defaultsDomain[Key.darkThemeIsBase16] as? Bool ?? false
        self.rtfDarkBackgroundColor = defaultsDomain[Key.rtfDarkBackgroundColor] as? String
        
        if let ln = defaultsDomain[Key.lineNumbers] as? Bool {
            self.lineNumbers = ln ? .visible(omittingWrapLines: defaultsDomain[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        } else {
            self.lineNumbers = .visible(omittingWrapLines: true)
        }
        self.wordWrap = SCSHWordWrap(rawValue: defaultsDomain[Key.wordWrap] as? Int ?? 0) ?? .off
        self.lineLength = defaultsDomain[Key.lineLength] as? Int ?? 80
        
        self.tabSpaces = defaultsDomain[Key.tabSpaces] as? Int ?? 4
        
        self.format = SCSHFormat(rawValue: defaultsDomain[Key.format] as? String ?? "") ?? .html
        self.extra = defaultsDomain[Key.extraArguments] as? String ?? ""
        
        self.fontFamily = defaultsDomain[Key.fontFamily] as? String ?? "Menlo"
        self.fontSize = defaultsDomain[Key.fontSize] as? Float ?? 10
        
        self.css = defaultsDomain[Key.customCSS] as? String
        
        if let custom_formats = defaultsDomain[Key.customizedUTISettings] as? [String: [String: Any]] {
            for (uti, settings) in custom_formats {
                var s = SCSHSettings(UTI: uti)
                s.override(fromDictionary: settings)
                self.customizedSettings[uti] = s
            }
        }
        
        self.debug = defaultsDomain[Key.debug] as? Bool ?? false
    }
    
    /// Save the settings to the defaults preferences.
    mutating func synchronize(domain: String? = nil) -> Bool {
        let d = domain ?? self.domain
        guard d != "", isGlobal else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: d) ?? [:]
        
        defaultsDomain[Key.highlightPath] = highlightProgramPath
        if let format = self.format {
            defaultsDomain[Key.format] = format.rawValue
        } else {
            defaultsDomain.removeValue(forKey: Key.format)
        }
        
        var n = 0
        var customized_formats: [String: [String: Any]] = [:]
        for (uti, settings) in self.customizedSettings {
            let d = settings.toDictionary()
            if d.count > 0 {
                customized_formats[uti] = d
                n += 1
            }
        }
        if n > 0 {
            defaultsDomain[Key.customizedUTISettings] = customized_formats
        } else {
            defaultsDomain.removeValue(forKey: Key.customizedUTISettings)
        }
        
        if let lightTheme = self.lightTheme, lightTheme != "" {
            defaultsDomain[Key.lightTheme] = lightTheme
        } else {
            defaultsDomain.removeValue(forKey: Key.lightTheme)
        }
        if let lightThemeIsBase16 = self.lightThemeIsBase16 {
            defaultsDomain[Key.lightThemeIsBase16] = lightThemeIsBase16
        } else {
            defaultsDomain.removeValue(forKey: Key.lightThemeIsBase16)
        }
        defaultsDomain[Key.rtfLightBackgroundColor] = rtfLightBackgroundColor
        if let darkTheme = self.darkTheme, darkTheme != "" {
            defaultsDomain[Key.darkTheme] = darkTheme
        } else {
            defaultsDomain.removeValue(forKey: Key.darkTheme)
        }
        if let darkThemeIsBase16 = self.darkThemeIsBase16 {
            defaultsDomain[Key.darkThemeIsBase16] = darkThemeIsBase16
        } else {
            defaultsDomain.removeValue(forKey: Key.darkThemeIsBase16)
        }
        defaultsDomain[Key.rtfDarkBackgroundColor] = rtfDarkBackgroundColor
        
        if let lineNumbers = self.lineNumbers {
            switch lineNumbers {
            case .hidden:
                defaultsDomain[Key.lineNumbers] = false
            case .visible(let omittingWrapLines):
                defaultsDomain[Key.lineNumbers] = true
                defaultsDomain[Key.lineNumbersOmittedWrap] = omittingWrapLines
            }
        } else {
            defaultsDomain.removeValue(forKey: Key.lineNumbers)
            defaultsDomain.removeValue(forKey: Key.lineNumbersOmittedWrap)
        }
        
        if let wordWrap = self.wordWrap {
            defaultsDomain[Key.wordWrap] = wordWrap.rawValue
        } else {
            defaultsDomain.removeValue(forKey: Key.wordWrap)
        }
        if let lineLength = self.lineLength {
            defaultsDomain[Key.lineLength] = lineLength
        } else {
            defaultsDomain.removeValue(forKey: Key.lineLength)
        }
        
        if let tabSpaces = self.tabSpaces {
            defaultsDomain[Key.tabSpaces] = tabSpaces
        } else {
            defaultsDomain.removeValue(forKey: Key.tabSpaces)
        }
        
        if let extra = self.extra {
            defaultsDomain[Key.extraArguments] = extra
        } else {
            defaultsDomain.removeValue(forKey: Key.extraArguments)
        }
        
        if let fontFamily = self.fontFamily {
            defaultsDomain[Key.fontFamily] = fontFamily
        } else {
            defaultsDomain.removeValue(forKey: Key.fontFamily)
        }
        if let fontSize = self.fontSize {
            defaultsDomain[Key.fontSize] = fontSize
        } else {
            defaultsDomain.removeValue(forKey: Key.fontSize)
        }
        
        if let css = self.css {
            defaultsDomain[Key.customCSS] = css
        } else {
            defaultsDomain.removeValue(forKey: Key.customCSS)
        }
        
        if let preprocessor = self.preprocessor, !preprocessor.isEmpty {
            defaultsDomain[Key.preprocessor] = preprocessor
        } else {
            defaultsDomain.removeValue(forKey: Key.preprocessor)
        }
        
        defaultsDomain[Key.debug] = self.debug
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: d)
        return userDefaults.synchronize()
    }
    
    /// Output the settings to a dictionary.
    func toDictionary() -> [String: Any] {
        guard self.isCustomized else {
            return [:]
        }
        
        var r: [String: Any] = [:]
        
        if isGlobal {
            r[Key.highlightPath] = self.highlightProgramPath
            if let format = self.format {
                r[Key.format] = format.rawValue
            }
            
            r[Key.embedCustomStyle] = self.embedCustomStyle
            
            var customized_formats: [String: [String: Any]] = [:]
            for (uti, settings) in self.customizedSettings {
                let d = settings.toDictionary()
                if d.count > 0 {
                    customized_formats[uti] = d
                }
            }
            r[Key.customizedUTISettings] = customized_formats
            
            r[Key.debug] = self.debug
        } else {
            if let utiExtra = self.utiExtra {
                r[Key.utiExtraArguments] = utiExtra
            }
        }
        if let lightTheme = self.lightTheme {
            r[Key.lightTheme] = lightTheme
            r[Key.rtfLightBackgroundColor] = rtfLightBackgroundColor ?? "ffffff"
        }
        if let lightThemeIsBase16 = self.lightThemeIsBase16 {
            r[Key.lightThemeIsBase16] = lightThemeIsBase16
        }
        if let darkTheme = self.darkTheme {
            r[Key.darkTheme] = darkTheme
            r[Key.rtfDarkBackgroundColor] = rtfDarkBackgroundColor ?? "000000"
        }
        if let darkThemeIsBase16 = self.darkThemeIsBase16 {
            r[Key.darkThemeIsBase16] = darkThemeIsBase16
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
        
        if let theme = self.theme {
            r[Key.theme] = theme
        }
        if let themeIsBase16 = self.themeIsBase16 {
            r[Key.themeIsBase16] = themeIsBase16
        }
        if let color = self.rtfBackgroundColor {
            r[Key.rtfBackgroundColor] = color
        }
        
        return r
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    mutating func override(fromDictionary dict: [String: Any]?) {
        guard let data = dict else {
            return
        }
        if isGlobal {
            if let v = data[Key.highlightPath] as? String {
                self.highlightProgramPath = v
            }
            // Output format.
            if let v = data[Key.format] as? String, let f = SCSHFormat(rawValue: v) {
                self.format = f
            }
            if let customized_formats = data[Key.customizedUTISettings] as? [String: [String: Any]] {
                self.customizedSettings = [:]
                for (uti, dict) in customized_formats {
                    var uti_settings = self.customizedSettings[uti] ?? SCSHSettings(UTI: uti)
                    uti_settings.override(fromDictionary: dict)
                    self.customizedSettings[uti] = uti_settings
                }
            }
            // Debug
            if let debug = data[Key.debug] as? Bool {
                self.debug = debug
            }
        } else {
            if let v = data[Key.utiExtraArguments] as? String {
                self.utiExtra = v
            }
        }
        
        // Light theme.
        if let v = data[Key.lightTheme] as? String {
            self.lightTheme = v
        }
        if let v = data[Key.lightThemeIsBase16] as? Bool {
            self.lightThemeIsBase16 = v
        }
        // Light background color.
        if let v = data[Key.rtfLightBackgroundColor] as? String {
            self.rtfLightBackgroundColor = v
        }
        
        // Dark theme.
        if let v = data[Key.darkTheme] as? String {
            self.darkTheme = v
        }
        if let v = data[Key.darkThemeIsBase16] as? Bool {
            self.darkThemeIsBase16 = v
        }
        // Dark background color.
        if let v = data[Key.rtfDarkBackgroundColor] as? String {
            self.rtfDarkBackgroundColor = v
        }
        
        // Forcing a theme.
        if let _ = data.keys.first(where: { $0 == Key.theme }) {
            self.theme = data[Key.theme] as? String
        }
        if let _ = data.keys.first(where: { $0 == Key.themeIsBase16 }) {
            self.themeIsBase16 = data[Key.themeIsBase16] as? Bool
        }
        // Forcing a background color.
        if let _ = data.keys.first(where: { $0 == Key.rtfBackgroundColor }) {
            self.rtfBackgroundColor = data[Key.rtfBackgroundColor] as? String
        }
        
        // Show line numbers.
        if let v = data[Key.lineNumbers] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: data[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        }
        
        if let v = data[Key.wordWrap] as? Int {
            self.wordWrap = SCSHWordWrap(rawValue: v) ?? .off
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
        
        // Font family.
        if let v = data[Key.fontFamily] as? String {
            self.fontFamily = v
        }
        // Font size.
        if let v = data[Key.fontSize] as? Float {
            self.fontSize = v
        }
        if let v = data[Key.customCSS] as? String {
            self.css = v
        }
        
        if let v = data[Key.preprocessor] as? String {
            self.preprocessor = v
        }
        
        if let v = data[Key.embedCustomStyle] as? Bool {
            self.embedCustomStyle = v
        }
    }
    
    mutating func override(fromSettings settings: SCSHSettings) {
        override(fromDictionary: settings.toDictionary())
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    func overriding(fromDictionary override: [String: Any]?) -> Self {
        var final_settings = SCSHSettings(settings: self)
        if let o = override {
            final_settings.override(fromDictionary: o)
        }
        return final_settings
    }
    
    func getGlobalSettingsForUti(_ uti: String) -> SCSHSettings? {
        guard isGlobal else {
            return nil
        }
        
        var settings = SCSHSettings(settings: self)
        if let s = self.customizedSettings[uti] {
            settings.override(fromSettings: s)
            if let extra = s.utiExtra, extra != "" {
                settings.extra = (settings.extra != nil ? settings.extra! + " " : "") + extra
            }
        }
        
        return settings
    }
    
    /// Clear all customized settings for UTIs.
    mutating func clearUTISettings() {
        self.customizedSettings = [:]
    }
    
    /// Get customized settings for a UTI.
    /// If not exists it will be created.
    /// The returned  settings are only customized value.
    mutating func getSettings(forUTI uti: String) -> SCSHSettings?
    {
        guard isGlobal else {
            return nil
        }
        if let s = self.customizedSettings[uti] {
            return s
        } else {
            let s = SCSHSettings(UTI: uti)
            self.customizedSettings[uti] = s
            return s
        }
    }
    
    mutating func setUTISettings(_ settings: SCSHSettings) {
        self.customizedSettings[settings.uti] = settings
    }
    
    mutating func removeUTISettings(uti: String) -> SCSHSettings? {
        return self.customizedSettings.removeValue(forKey: uti)
    }
    
    func hasCustomizedUTI(_ uti: String) -> Bool {
        if let s = self.customizedSettings[uti] {
            return s.isCustomized
        } else {
            return false
        }
    }
}
