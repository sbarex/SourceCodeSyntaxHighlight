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

extension SCSHBaseSettings.Key {
    static let inlineTheme = "inline_theme"
}

class SCSHSettings: SCSHGlobalBaseSettings {
    /// A theme to use instead of the theme name.
    var inlineTheme: SCSHTheme?
    
    // MARK: - Initialisers
    
    /// Initialize from a preferences loaded from the domain defaults.
    required init(settings: [String: Any]) {
        super.init(settings: settings)
        
        if lightTheme == nil {
            lightTheme = "edit-xcode"
        }
        if darkTheme == nil {
            darkTheme = "neon"
        }
        
        inlineTheme = SCSHTheme(dict: settings[Key.inlineTheme] as? [String: Any])
    }
    
    convenience init(settings: SCSHGlobalBaseSettings) {
        self.init(settings: settings.toDictionary())
    }
    
    // MARK: - Methods
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func synchronize(domain: String) -> Bool {
        guard domain != "" else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        
        let updateDomains = { (key: String, value: Any?) in
            if let v = value {
                defaultsDomain[key] = v
            } else {
                defaultsDomain.removeValue(forKey: key)
            }
        }
        
        defaultsDomain[Key.highlightPath] = highlightProgramPath
        updateDomains(Key.format, self.format?.rawValue)
        
        var customized_formats: [String: [String: Any]] = [:]
        for (uti, settings) in self.customizedSettings {
            let d = settings.toDictionary()
            if d.count > 0 {
                customized_formats[uti] = d
            }
        }
        updateDomains(Key.customizedUTISettings, customized_formats.count > 0 ? customized_formats : nil)
        
        updateDomains(Key.lightTheme, lightTheme?.isEmpty ?? true ? nil : lightTheme)
        updateDomains(Key.lightBackgroundColor, lightBackgroundColor)
        
        updateDomains(Key.darkTheme, darkTheme?.isEmpty ?? true ? nil : darkTheme)
        updateDomains(Key.darkBackgroundColor, darkBackgroundColor)
        
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
        
        updateDomains(Key.wordWrap, wordWrap?.rawValue)
        updateDomains(Key.lineLength, lineLength)
        updateDomains(Key.tabSpaces, tabSpaces)
        updateDomains(Key.extraArguments, extra)
        
        updateDomains(Key.fontFamily, fontFamily)
        updateDomains(Key.fontSize, fontSize)
        
        updateDomains(Key.preprocessor, preprocessor?.isEmpty ?? true ? nil : preprocessor)
        
        if let v = maxData, v > 0 {
            defaultsDomain[Key.maxData] = v
        } else {
            defaultsDomain.removeValue(forKey: Key.maxData)
        }
        
        updateDomains(Key.interactive, allowInteractiveActions)
        updateDomains(Key.debug, debug ? true : nil)
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: domain)
        return userDefaults.synchronize()
    }
    
    /// Output the settings to a dictionary.
    override func toDictionary() -> [String: Any] {
        var r: [String: Any] = super.toDictionary()

        if let inlineTheme = self.inlineTheme {
            r[Key.inlineTheme] = inlineTheme.toDictionary()
        } else {
            r[Key.inlineTheme] = nil
        }
        
        return r
    }
    
    /// Updating values from a dictionary. Settings not defined on dictionary are not updated.
    /// - parameters:
    ///   - data: NSDictionary [String: Any]
    override func override(fromDictionary dict: [String: Any]?) {
        guard let data = dict else {
            return
        }
        super.override(fromDictionary: data)
        
        if let inlineTheme = data[Key.inlineTheme] as? [String: Any] {
            self.inlineTheme = SCSHTheme(dict: inlineTheme)
        }
    }
    
    override func getHighlightArguments() throws -> (theme: String, backgroundColor: String, arguments: [String]) {
        var hlArguments = try super.getHighlightArguments()
        if let theme = self.theme {
            hlArguments.theme = theme
        }
        if let themeBackground = self.backgroundColor {
            hlArguments.backgroundColor = themeBackground
        }
        return hlArguments
    }
}
