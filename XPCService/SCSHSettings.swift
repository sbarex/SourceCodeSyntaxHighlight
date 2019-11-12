//
//  SCSHSettings.swift
//  SCSHXPCService
//
//  Created by sbarex on 18/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

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
            } else if (lightTheme != nil && lightTheme != "") || (darkTheme != nil && darkTheme != "") || lineNumbers != nil || fontFamily != nil || wordWrap != nil || lineLength != nil || tabSpaces != nil || extra != nil {
                return true
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
    
    init(dictionary: [String: Any]) {
        if let uti = dictionary[Key.connectedUTI] as? String {
            self.uti = uti
        } else {
            self.uti = ""
        }
        self.domain = ""
        self.fromDictionary(dictionary)
    }
    
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
        
        if let custom_formats = defaultsDomain[Key.customizedUTISettings] as? [String: [String: Any]] {
            for (uti, settings) in custom_formats {
                var s = SCSHSettings(UTI: uti)
                s.fromDictionary(settings)
                self.customizedSettings[uti] = s
            }
        }
        
        self.debug = defaultsDomain[Key.debug] as? Bool ?? false
    }
    
    /// Save the settings to the defaults preferences.
    mutating func synchronize(domain: String? = nil) -> Bool {
        let d = domain ?? self.domain
        guard d != "" else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: d) ?? [:]
        
        if isGlobal {
            defaultsDomain[Key.highlightPath] = highlightProgramPath
            if let format = self.format {
                defaultsDomain[Key.format] = format.rawValue
            } else {
                defaultsDomain.removeValue(forKey: Key.format)
            }
            
            defaultsDomain.removeValue(forKey: Key.connectedUTI)
            defaultsDomain.removeValue(forKey: Key.utiExtraArguments)
            
            var n = 0
            var customized_formats: [String: [String: Any]] = [:]
            for (uti, settings) in self.customizedSettings {
                let d = settings.toDictionary()
                if d.count > 0 {
                    customized_formats[uti] = d
                    n += 0
                }
            }
            if n > 0 {
                defaultsDomain[Key.customizedUTISettings] = customized_formats
            } else {
                defaultsDomain.removeValue(forKey: Key.customizedUTISettings)
            }
        } else {
            defaultsDomain.removeValue(forKey: Key.highlightPath)
            defaultsDomain.removeValue(forKey: Key.format)
            
            defaultsDomain[Key.connectedUTI] = self.uti
            if let utiExtra = self.utiExtra {
                defaultsDomain[Key.utiExtraArguments] = utiExtra
            } else {
                defaultsDomain.removeValue(forKey: Key.utiExtraArguments)
            }
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
        
        defaultsDomain[Key.debug] = self.debug
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: d)
        return userDefaults.synchronize()
    }
    
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
        if let color = self.rtfBackgroundColor {
            r[Key.rtfBackgroundColor] = color
        }
        
        return r
    }
    
    /// Updating values from a dictionary.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    mutating func fromDictionary(_ data: [String: Any]) {
        if isGlobal {
            if let v = data[Key.highlightPath] as? String {
                self.highlightProgramPath = v
            }
            if let v = data[Key.format] as? String, let f = SCSHFormat(rawValue: v) {
                self.format = f
            }
            if let customized_formats = data[Key.customizedUTISettings] as? [String: [String: Any]] {
                self.customizedSettings = [:]
                for (uti, dict) in customized_formats {
                    var uti_settings = self.customizedSettings[uti] ?? SCSHSettings(UTI: uti)
                    uti_settings.fromDictionary(dict)
                    self.customizedSettings[uti] = uti_settings
                }
            }
            if let debug = data[Key.debug] as? Bool {
                self.debug = debug
            }
        } else {
            if let v = data[Key.utiExtraArguments] as? String {
                self.utiExtra = v
            }
        }
        
        if let v = data[Key.lightTheme] as? String {
            self.lightTheme = v
        }
        if let v = data[Key.lightThemeIsBase16] as? Bool {
            self.lightThemeIsBase16 = v
        }
        if let v = data[Key.rtfLightBackgroundColor] as? String {
            self.rtfLightBackgroundColor = v
        }
        
        if let v = data[Key.darkTheme] as? String {
            self.darkTheme = v
        }
        if let v = data[Key.darkThemeIsBase16] as? Bool {
            self.darkThemeIsBase16 = v
        }
        if let v = data[Key.rtfDarkBackgroundColor] as? String {
            self.rtfDarkBackgroundColor = v
        }
        
        if let _ = data.keys.first(where: { $0 == Key.theme }) {
            self.theme = data[Key.theme] as? String
        }
        if let _ = data.keys.first(where: { $0 == Key.rtfBackgroundColor }) {
            self.rtfBackgroundColor = data[Key.rtfBackgroundColor] as? String
        }
        
        if let v = data[Key.lineNumbers] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: data[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        }
        
        if let v = data[Key.wordWrap] as? Int {
            self.wordWrap = SCSHWordWrap(rawValue: v) ?? .off
        }
        if let v = data[Key.lineLength] as? Int {
            self.lineLength = v
        }
        
        if let v = data[Key.tabSpaces] as? Int {
            self.tabSpaces = v
        }
        
        if let v = data[Key.extraArguments] as? String {
            self.extra = v
        }
        
        if let v = data[Key.fontFamily] as? String {
            self.fontFamily = v
        }
        if let v = data[Key.fontSize] as? Float {
            self.fontSize = v
        }
        if let v = data[Key.embedCustomStyle] as? Bool {
            self.embedCustomStyle = v
        }
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    func overriding(_ override: [String: Any]?) -> Self {
        var final_settings = SCSHSettings()
        
        final_settings.highlightProgramPath = override?[Key.highlightPath] as? String ?? self.highlightProgramPath
        
        // Output format.
        if let f = override?[Key.format] as? String, let format = SCSHFormat(rawValue: f) {
            final_settings.format = format
        } else {
            final_settings.format = self.format
        }
        
        // Light theme.
        final_settings.lightTheme = override?[Key.lightTheme] as? String ?? self.lightTheme
        final_settings.lightThemeIsBase16 = override?[Key.lightThemeIsBase16] as? Bool ?? self.lightThemeIsBase16
        // Light background color.
        final_settings.rtfLightBackgroundColor = override?[Key.rtfLightBackgroundColor] as? String ?? self.rtfLightBackgroundColor
        
        // Dark theme.
        final_settings.darkTheme = override?[Key.darkTheme] as? String ?? self.darkTheme
        final_settings.darkThemeIsBase16 = override?[Key.darkThemeIsBase16] as? Bool ?? self.darkThemeIsBase16
        
        // Dark background color.
        final_settings.rtfDarkBackgroundColor = override?[Key.rtfDarkBackgroundColor] as? String ?? self.rtfDarkBackgroundColor
        
        // Forcing a theme.
        final_settings.theme = override?[Key.theme] as? String ?? self.theme
        // Forcing a background color.
        final_settings.rtfBackgroundColor = override?[Key.rtfBackgroundColor] as? String ?? self.rtfBackgroundColor
        
        // Extra arguments for _highlight_.
        final_settings.extra = override?[Key.extraArguments] as? String ?? self.extra
        
        // Show line numbers.
        if let v = override?[Key.lineNumbers] as? Bool {
            final_settings.lineNumbers = v ? .visible(omittingWrapLines: override?[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        } else {
            final_settings.lineNumbers = self.lineNumbers
        }
        
        if let v = override?[Key.wordWrap] as? Int, let ww = SCSHWordWrap(rawValue: v) {
            final_settings.wordWrap = ww
        } else {
            final_settings.lineLength = self.lineLength
        }
        final_settings.lineLength = override?[Key.lineLength] as? Int ?? self.lineLength
        
        // Convert tab to spaces.
        final_settings.tabSpaces = override?[Key.tabSpaces] as? Int ?? self.tabSpaces
        
        // Font family.
        final_settings.fontFamily = override?[Key.fontFamily] as? String ?? self.fontFamily
        // Font size.
        final_settings.fontSize = override?[Key.fontSize] as? Float ?? self.fontSize
        
        // Debug
        final_settings.debug = override?[Key.debug] as? Bool ?? debug
        
        final_settings.embedCustomStyle = override?[Key.embedCustomStyle] as? Bool ?? embedCustomStyle
        
        return final_settings
    }
    
    mutating func override(fromDictionary override: [String: Any]?) {
        if let path = override?[Key.highlightPath] as? String {
            self.highlightProgramPath = path
        }
        
        // Output format.
        if let f = override?[Key.format] as? String, let format = SCSHFormat(rawValue: f) {
            self.format = format
        }
        
        // Light theme.
        if let lightTheme = override?[Key.lightTheme] as? String {
            self.lightTheme = lightTheme
        }
        if let lightThemeIsBase16 = override?[Key.lightThemeIsBase16] as? Bool {
            self.lightThemeIsBase16 = lightThemeIsBase16
        }
        // Light background color.
        if let rtfLightBackgroundColor = override?[Key.rtfLightBackgroundColor] as? String {
            self.rtfLightBackgroundColor = rtfLightBackgroundColor
        }
        
        // Dark theme.
        if let darkTheme = override?[Key.darkTheme] as? String {
            self.darkTheme = darkTheme
        }
        if let darkThemeIsBase16 = override?[Key.darkThemeIsBase16] as? Bool {
            self.darkThemeIsBase16 = darkThemeIsBase16
        }
        // Dark background color.
        if let rtfDarkBackgroundColor = override?[Key.rtfDarkBackgroundColor] as? String {
            self.rtfDarkBackgroundColor = rtfDarkBackgroundColor
        }
        
        // Forcing a theme.
        if let theme = override?[Key.theme] as? String {
            self.theme = theme
        }
        if let theme16 = override?[Key.themeIsBase16] as? Bool {
            self.themeIsBase16 = theme16
        }
        // Forcing a background color.
        if let rtfBackgroundColor = override?[Key.rtfBackgroundColor] as? String {
            self.rtfBackgroundColor = rtfBackgroundColor
        }
        
        // Extra arguments for _highlight_.
        if let extra = override?[Key.extraArguments] as? String {
            self.extra = extra
        }
        
        // Show line numbers.
        if let v = override?[Key.lineNumbers] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: override?[Key.lineNumbersOmittedWrap] as? Bool ?? true) : .hidden
        }
        
        if let v = override?[Key.wordWrap] as? Int, let ww = SCSHWordWrap(rawValue: v) {
            self.wordWrap = ww
        }
        if let lineLength = override?[Key.lineLength] as? Int {
            self.lineLength = lineLength
        }
        
        // Convert tab to spaces.
        if let tabSpaces = override?[Key.tabSpaces] as? Int {
            self.tabSpaces = tabSpaces
        }
        
        // Font family.
        if let fontFamily = override?[Key.fontFamily] as? String {
            self.fontFamily = fontFamily
        }
        // Font size.
        if let fontSize = override?[Key.fontSize] as? Float {
            self.fontSize = fontSize
        }
        
        // Debug
        if let debug = override?[Key.debug] as? Bool {
            self.debug = debug
        }
        
        if let embedCustomStyle = override?[Key.embedCustomStyle] as? Bool {
            self.embedCustomStyle = embedCustomStyle
        }
    }
    
    mutating func override(fromSettings override: SCSHSettings?) {
        if let path = override?.highlightProgramPath {
            self.highlightProgramPath = path
        }
        
        // Output format.
        if let format = override?.format {
            self.format = format
        }
        
        // Light theme.
        if let lightTheme = override?.lightTheme {
            self.lightTheme = lightTheme
        }
        if let lightThemeIsBase16 = override?.lightThemeIsBase16 {
            self.lightThemeIsBase16 = lightThemeIsBase16
        }
        // Light background color.
        if let rtfLightBackgroundColor = override?.rtfLightBackgroundColor{
            self.rtfLightBackgroundColor = rtfLightBackgroundColor
        }
        
        // Dark theme.
        if let darkTheme = override?.darkTheme {
            self.darkTheme = darkTheme
        }
        if let darkThemeIsBase16 = override?.darkThemeIsBase16 {
            self.darkThemeIsBase16 = darkThemeIsBase16
        }
        
        // Dark background color.
        if let rtfDarkBackgroundColor = override?.rtfDarkBackgroundColor {
            self.rtfDarkBackgroundColor = rtfDarkBackgroundColor
        }
        
        // Forcing a theme.
        if let theme = override?.theme {
            self.theme = theme
        }
        // Forcing a background color.
        if let rtfBackgroundColor = override?.rtfBackgroundColor {
            self.rtfBackgroundColor = rtfBackgroundColor
        }
        
        // Extra arguments for _highlight_.
        if let extra = override?.extra {
            self.extra = extra
        }
        
        // Show line numbers.
        if let lineNumbers = override?.lineNumbers {
            self.lineNumbers = lineNumbers
        }
        
        if let wordWrap = override?.wordWrap {
            self.wordWrap = wordWrap
        }
        if let lineLength = override?.lineLength {
            self.lineLength = lineLength
        }
        
        // Convert tab to spaces.
        if let tabSpaces = override?.tabSpaces {
            self.tabSpaces = tabSpaces
        }
        
        // Font family.
        if let fontFamily = override?.fontFamily {
            self.fontFamily = fontFamily
        }
        // Font size.
        if let fontSize = override?.fontSize {
            self.fontSize = fontSize
        }
        
        // Debug
        if let debug = override?.debug {
            self.debug = debug
        }
        
        if let embedCustomStyle = override?.embedCustomStyle {
            self.embedCustomStyle = embedCustomStyle
        }
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
