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
    public struct Key: Hashable, Equatable, RawRepresentable {
        public var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        static let lightTheme: Self = {
            return Self("theme-light")
        }()
        static let darkTheme: Self = {
            return Self("theme-dark")
        }()
        static let theme: Self = {
            return Self("theme")
        }()
        
        static let rtfLightBackgroundColor: Self = {
            return Self("rtf-background-color-light")
        }()
        static let rtfDarkBackgroundColor: Self = {
            return Self("rtf-background-color-dark")
        }()
        static let rtfBackgroundColor: Self = {
            return Self("rtf-background-color")
        }()
        
        static let lineNumbers: Self = {
            return Self("line-numbers")
        }()
        static let lineNumbersOmittedWrap: Self = {
            return Self("line-numbers-omitted-wrap")
        }()
        
        static let wordWrap: Self = {
            return Self("word-wrap")
        }()
        static let lineLength: Self = {
            return Self("line-length")
        }()
        
        static let tabSpaces: Self = {
            return Self("tab-spaces")
        }()
        
        static let highlightPath: Self = {
            return Self("highlight")
        }()
        
        static let format: Self = {
            return Self("format")
        }()
        
        static let extraArguments: Self = {
            return Self("extra")
        }()
        
        
        static let fontFamily: Self = {
            return Self("font-family")
        }()
        static let fontSize: Self = {
            return Self("font-size")
        }()
        
        static let debug: Self = {
            return Self("debug")
        }()
        
        static let embedCustomStyle: Self = {
            return Self("embed-style")
        }()
    }
    
    /// Name of theme for light visualization.
    var lightTheme: String = ""
    /// Name of theme for dark visualization.
    var darkTheme: String = ""
    /// Name of theme overriding the light/dark settings
    var theme: String?
    
    /// Background color for the rgb view in light theme.
    var rtfLightBackgroundColor: String = ""
    /// Background color for the rgb view in dark theme.
    var rtfDarkBackgroundColor: String = ""
    /// Background color overriding the light/dark settings
    var rtfBackgroundColor: String?
    
    /// Show line number.
    var lineNumbers: SCSHLineNumbers = .visible(omittingWrapLines: true)
    var wordWrap: SCSHWordWrap = .standard
    var lineLength: Int = 80
    
    /// Number of spaces use for a tab. Set to 0 to disable converting tab to spaces.
    var tabSpaces: Int = 4
    
    /// Path of highlight executable.
    var highlightProgramPath: String = ""
    /// Extra arguments for highlight.
    var extra: String = ""
    
    /// Output format.
    var format: SCSHFormat = .html
    
    var fontFamily: String = "Menlo"
    var fontSize: Float = 10
    
    var debug = false
    
    /// Embed custom style in the output.
    var embedCustomStyle = true
    
    /// Domain for storing defaults.
    let domain: String
    
    init() {
        self.domain = ""
    }
    
    /// Initialize from a preferences default loaded from the domain.
    init(domain: String) {
        self.domain = domain
        
        let defaults = UserDefaults.standard
        let defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        
        self.highlightProgramPath = defaultsDomain[Key.highlightPath.rawValue] as? String ?? "-"
        if self.highlightProgramPath == "" {
            // Use embedded highlight.
            self.highlightProgramPath = "-"
        }
        
        self.lightTheme = defaultsDomain[Key.lightTheme.rawValue] as? String ?? "edit-xcode"
        self.rtfLightBackgroundColor = defaultsDomain[Key.rtfLightBackgroundColor.rawValue] as? String ?? "#ffffff"
        
        self.darkTheme = defaultsDomain[Key.darkTheme.rawValue] as? String ?? "edit-xcode"
        self.rtfDarkBackgroundColor = defaultsDomain[Key.rtfDarkBackgroundColor.rawValue] as? String ?? "#000000"
        
        if let ln = defaultsDomain[Key.lineNumbers.rawValue] as? Bool {
            self.lineNumbers = ln ? .visible(omittingWrapLines: defaultsDomain[Key.lineNumbersOmittedWrap.rawValue] as? Bool ?? true) : .hidden
        } else {
            self.lineNumbers = .visible(omittingWrapLines: true)
        }
        self.wordWrap = SCSHWordWrap(rawValue: defaultsDomain[Key.wordWrap.rawValue] as? Int ?? 0) ?? .off
        self.lineLength = defaultsDomain[Key.lineLength.rawValue] as? Int ?? 80
        
        self.tabSpaces = defaultsDomain[Key.tabSpaces.rawValue] as? Int ?? 4
        
        self.format = SCSHFormat(rawValue: defaultsDomain[Key.format.rawValue] as? String ?? "") ?? .html
        self.extra = defaultsDomain[Key.extraArguments.rawValue] as? String ?? ""
        
        self.fontFamily = defaultsDomain[Key.fontFamily.rawValue] as? String ?? "Menlo"
        self.fontSize = defaultsDomain[Key.fontSize.rawValue] as? Float ?? 10
    }
    
    /// Save the settings to the defauls preferences.
    mutating func synchronize(domain: String? = nil) -> Bool {
        let d = domain ?? self.domain
        guard d != "" else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: d) ?? [:]
        
        defaultsDomain[Key.highlightPath.rawValue] = highlightProgramPath
        defaultsDomain[Key.format.rawValue] = format.rawValue
        
        defaultsDomain[Key.lightTheme.rawValue] = lightTheme
        defaultsDomain[Key.rtfLightBackgroundColor.rawValue] = rtfLightBackgroundColor
        defaultsDomain[Key.darkTheme.rawValue] = darkTheme
        defaultsDomain[Key.rtfDarkBackgroundColor.rawValue] = rtfDarkBackgroundColor
        
        switch lineNumbers {
        case .hidden:
            defaultsDomain[Key.lineNumbers.rawValue] = false
        case .visible(let omittingWrapLines):
            defaultsDomain[Key.lineNumbers.rawValue] = true
            defaultsDomain[Key.lineNumbersOmittedWrap.rawValue] = omittingWrapLines
        }
        
        defaultsDomain[Key.wordWrap.rawValue] = self.wordWrap.rawValue
        defaultsDomain[Key.lineLength.rawValue] = self.lineLength
        
        defaultsDomain[Key.tabSpaces.rawValue] = tabSpaces
        
        defaultsDomain[Key.extraArguments.rawValue] = extra
        
        defaultsDomain[Key.fontFamily.rawValue] = fontFamily
        defaultsDomain[Key.fontSize.rawValue] = fontSize
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: d)
        return userDefaults.synchronize()
    }
    
    func toDictionary() -> [String: Any] {
        var r: [String: Any] = [
            Key.highlightPath.rawValue: self.highlightProgramPath,
            Key.format.rawValue: self.format.rawValue,
        
            Key.lightTheme.rawValue: self.lightTheme,
            Key.rtfLightBackgroundColor.rawValue: self.rtfLightBackgroundColor,
            
            Key.darkTheme.rawValue: self.darkTheme,
            Key.rtfDarkBackgroundColor.rawValue: self.rtfDarkBackgroundColor,
        
            Key.wordWrap.rawValue: self.wordWrap.rawValue,
            Key.lineLength.rawValue: self.lineLength,
            
            Key.tabSpaces.rawValue: self.tabSpaces,
            
            Key.extraArguments.rawValue: self.extra,
        
            Key.fontFamily.rawValue: self.fontFamily,
            Key.fontSize.rawValue: self.fontSize,
            
            Key.embedCustomStyle.rawValue: self.embedCustomStyle,
        ]
        
        switch self.lineNumbers {
        case .hidden:
            r[Key.lineNumbers.rawValue] = false
        case .visible(let omittingWrapLines):
            r[Key.lineNumbers.rawValue] = true
            r[Key.lineNumbersOmittedWrap.rawValue] = omittingWrapLines
        }
        
        if let v = self.theme {
            r[Key.theme.rawValue] = v
        }
        if let v = self.rtfBackgroundColor {
            r[Key.rtfBackgroundColor.rawValue] = v
        }
        return r
    }
    
    /// Updating values from a dictionary.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    mutating func fromDictionary(_ data: [String: Any]) {
        if let v = data[Key.highlightPath.rawValue] as? String {
            self.highlightProgramPath = v
        }
        if let v = data[Key.format.rawValue] as? String, let f = SCSHFormat(rawValue: v) {
            self.format = f
        }
        
        if let v = data[Key.lightTheme.rawValue] as? String {
            self.lightTheme = v
        }
        if let v = data[Key.rtfLightBackgroundColor.rawValue] as? String {
            self.rtfLightBackgroundColor = v
        }
        
        if let v = data[Key.darkTheme.rawValue] as? String {
            self.darkTheme = v
        }
        if let v = data[Key.rtfDarkBackgroundColor.rawValue] as? String {
            self.rtfDarkBackgroundColor = v
        }
        
        if let _ = data.keys.first(where: { $0 == Key.theme.rawValue }) {
            self.theme = data[Key.theme.rawValue] as? String
        }
        if let _ = data.keys.first(where: { $0 == Key.rtfBackgroundColor.rawValue }) {
            self.rtfBackgroundColor = data[Key.rtfBackgroundColor.rawValue] as? String
        }
        
        if let v = data[Key.lineNumbers.rawValue] as? Bool {
            self.lineNumbers = v ? .visible(omittingWrapLines: data[Key.lineNumbersOmittedWrap.rawValue] as? Bool ?? true) : .hidden
        }
        
        if let v = data[Key.wordWrap.rawValue] as? Int {
            self.wordWrap = SCSHWordWrap(rawValue: v) ?? .off
        }
        if let v = data[Key.lineLength.rawValue] as? Int {
            self.lineLength = v
        }
        
        if let v = data[Key.tabSpaces.rawValue] as? Int {
            self.tabSpaces = v
        }
        
        if let v = data[Key.extraArguments.rawValue] as? String {
            self.extra = v
        }
        
        if let v = data[Key.fontFamily.rawValue] as? String {
            self.fontFamily = v
        }
        if let v = data[Key.fontSize.rawValue] as? Float {
            self.fontSize = v
        }
        if let v = data[Key.embedCustomStyle.rawValue] as? Bool {
            self.embedCustomStyle = v
        }
    }
    
    /// Create a new settings overriding current values
    /// - parameters:
    ///   - override:
    func overriding(_ override: [String: Any]?) -> Self {
        var final_settings = SCSHSettings()
        final_settings.highlightProgramPath = override?[Key.highlightPath.rawValue] as? String ?? self.highlightProgramPath
        
        // Output format.
        if let f = override?[Key.format.rawValue] as? String, let format = SCSHFormat(rawValue: f) {
            final_settings.format = format
        } else {
            final_settings.format = self.format
        }
        
        // Light theme.
        final_settings.lightTheme = override?[Key.lightTheme.rawValue] as? String ?? self.lightTheme
        // Light background color.
        final_settings.rtfLightBackgroundColor = override?[Key.rtfLightBackgroundColor.rawValue] as? String ?? self.rtfLightBackgroundColor
        
        // Dark theme.
        final_settings.darkTheme = override?[Key.darkTheme.rawValue] as? String ?? self.darkTheme
        
        // Dark background color.
        final_settings.rtfDarkBackgroundColor = override?[Key.rtfDarkBackgroundColor.rawValue] as? String ?? self.rtfDarkBackgroundColor
        
        // Forcing a theme.
        final_settings.theme = override?[Key.theme.rawValue] as? String ?? self.theme
        // Forcing a background color.
        final_settings.rtfBackgroundColor = override?[Key.rtfBackgroundColor.rawValue] as? String ?? self.rtfBackgroundColor
        
        // Extra arguments for _highlight_.
        final_settings.extra = override?[Key.extraArguments.rawValue] as? String ?? self.extra
        
        // Show line numbers.
        if let v = override?[Key.lineNumbers.rawValue] as? Bool {
            final_settings.lineNumbers = v ? .visible(omittingWrapLines: override?[Key.lineNumbersOmittedWrap.rawValue] as? Bool ?? true) : .hidden
        } else {
            final_settings.lineNumbers = self.lineNumbers
        }
        
        if let v = override?[Key.wordWrap.rawValue] as? Int, let ww = SCSHWordWrap(rawValue: v) {
            final_settings.wordWrap = ww
        } else {
            final_settings.lineLength = self.lineLength
        }
        final_settings.lineLength = override?[Key.lineLength.rawValue] as? Int ?? self.lineLength
        
        // Convert tab to spaces.
        final_settings.tabSpaces = override?[Key.tabSpaces.rawValue] as? Int ?? self.tabSpaces
        
        // Font family.
        final_settings.fontFamily = override?[Key.fontFamily.rawValue] as? String ?? self.fontFamily
        // Font size.
        final_settings.fontSize = override?[Key.fontSize.rawValue] as? Float ?? self.fontSize
        
        // Debug
        final_settings.debug = override?[Key.debug.rawValue] as? Bool ?? debug
        
        final_settings.embedCustomStyle = override?[Key.embedCustomStyle.rawValue] as? Bool ?? embedCustomStyle
        
        return final_settings
    }
}
