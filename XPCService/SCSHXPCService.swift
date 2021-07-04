//
//  SCSHXPCService.swift
//  SCSHXPCService
//
//  Created by sbarex on 15/10/2019.
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
import OSLog

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.


class SCSHXPCService: SCSHBaseXPCService, SCSHXPCServiceProtocol {
    // MARK: - Class properties
    
    /// Return the folder for the application support files.
    static var preferencesUrl: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Preferences")
    }
    
    // MARK: - Initializers
    
    override init() {
        if let pref = SCSHXPCService.preferencesUrl {
            /// Old settings name.
            let url_old = pref.appendingPathComponent("org.sbarex.SourceCodeSyntaxHightlight.plist")
            /// New settings name.
            let url_new = pref.appendingPathComponent(type(of: self).XPCDomain + ".plist")
            if FileManager.default.fileExists(atPath: url_old.path) && !FileManager.default.fileExists(atPath: url_new.path) {
                // Rename old preferences to new name (typo fix).
                try? FileManager.default.moveItem(at: url_old, to: url_new)
            }
        }
        
        if let baseDir = SCSHXPCService.applicationSupportUrl, !FileManager.default.fileExists(atPath: baseDir.path)  {
            do {
                try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        super.init()
        
        migrate(settings: settings)
    }

    /// Migrate the stored settings to the current format.
    @discardableResult
    internal func migrate(settings: Settings) -> Bool {
        guard settings.version < Settings.version else {
            return false
        }
        
        if settings.version <= 2.1 {
            for (_, uti_settings) in settings.utiSettings {
                guard !uti_settings.isPreprocessorDefined, !uti_settings.preprocessor.isEmpty else {
                    continue
                }
                if uti_settings.preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) == nil {
                    // Append the target placeholder at the end of the preprocessor command.
                    uti_settings.preprocessor = uti_settings.preprocessor.appending(" $targetHL")
                }
            }
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: type(of: self).XPCDomain) ?? [:]
        
        if let c = defaultsDomain["rtf-background-color-light"] as? String {
            settings.lightBackgroundColor = c
            defaultsDomain.removeValue(forKey: "rtf-background-color-light")
        }
        if let c = defaultsDomain["rtf-background-color-dark"] as? String {
            settings.darkBackgroundColor = c
            defaultsDomain.removeValue(forKey: "rtf-background-color-dark")
        }
        
        if settings.version <= 2.2 {
            defaultsDomain.removeValue(forKey: "highlight") // remove custom highlight path.
        }
        
        // "commands-toolbar" is not yet used.
        defaultsDomain.removeValue(forKey: "commands-toolbar")
        
        // "theme-light-is16" and "theme-dark-is16" are replaced by "base16/" prefix on theme name.
        let migrateBase16 = { (settings: SettingsBase, defaultsDomain: inout [String: Any], UTI: String) -> Bool in
            var changed = false
            if let lightThemeIsBase16 = (UTI.isEmpty ? defaultsDomain : defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]![jsonDict: UTI]!)["theme-light-is16"] as? Bool {
                if lightThemeIsBase16 && settings.isLightThemeNameDefined && !settings.lightThemeName.hasPrefix("base16") {
                    settings.lightThemeName = "base16/\(settings.lightThemeName)"
                }
                if UTI.isEmpty {
                    defaultsDomain.removeValue(forKey: "theme-light-is16")
                } else {
                    defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "theme-light-is16")
                }
                changed = true
            }
            if let darkThemeIsBase16 = (UTI.isEmpty ? defaultsDomain : defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]![jsonDict: UTI]!)["theme-dark-is16"] as? Bool {
                if darkThemeIsBase16 && settings.isDarkThemeNameDefined && !settings.darkThemeName.hasPrefix("base16") {
                    settings.darkThemeName = "base16/\(settings.darkThemeName)"
                }
                if UTI.isEmpty {
                    defaultsDomain.removeValue(forKey: "theme-dark-is16")
                } else {
                    defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "theme-dark-is16")
                }
                changed = true
            }
            return changed
        }
        
        let CSSFolder = type(of: self).getCustomStylesUrl(createIfMissing: true)
        
        // Custom CSS are saved on external files.
        let migrateCSS = { (settings: SettingsCSS, defaultsDomain: inout [String: Any], UTI: String, CSSFolder: URL?) -> Bool in
            guard let CSSFolder = CSSFolder else {
                return false
            }
            var changed = false
            if let customCSS = (!UTI.isEmpty ? defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]![jsonDict: UTI]! : defaultsDomain)["css"] as? String {
                settings.css = customCSS
                settings.isCSSDefined = !customCSS.isEmpty
                do {
                try settings.exportCSSFile(toFolder: CSSFolder)
                    if UTI.isEmpty {
                        defaultsDomain.removeValue(forKey: "css")
                    } else {
                        defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "css")
                    }
                    changed = true
                } catch {
                    
                }
            }
            return changed
        }
        
        _ = migrateBase16(settings, &defaultsDomain, "")
        _ = migrateCSS(settings, &defaultsDomain, "", CSSFolder)
        
        if let custom_formats = defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings] {
            for (uti, _) in custom_formats {
                var utiDefaultsDomain = (defaultsDomain[SettingsBase.Key.customizedUTISettings] as! [String: [String: Any]])[uti]!
                if let s = settings.utiSettings[uti] {
                    _ = migrateBase16(s, &defaultsDomain, uti)
                    _ = migrateCSS(s, &defaultsDomain, uti, CSSFolder)
                    
                    if settings.version <= 2.1, let preprocessor = utiDefaultsDomain["preprocessor"] as? String, !preprocessor.isEmpty, preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) == nil {
                        defaultsDomain[customizedTypes: SettingsBase.Key.customizedUTISettings]![uti]!["preprocessor"] = preprocessor.appending(" $targetHL")
                    }
                    
                    if let c = defaultsDomain["rtf-background-color-light"] as? String {
                        s.lightBackgroundColor = c
                        utiDefaultsDomain.removeValue(forKey: "rtf-background-color-light")
                    }
                    if let c = defaultsDomain["rtf-background-color-dark"] as? String {
                        s.darkBackgroundColor = c
                        utiDefaultsDomain.removeValue(forKey: "rtf-background-color-dark")
                    }
                }
            }
        }
        
        // Update settings version.
        settings.version = Settings.version
        defaultsDomain[SettingsBase.Key.version] = SettingsBase.version
        
        // Store the converted settings.
        defaults.setPersistentDomain(defaultsDomain, forName: type(of: self).XPCDomain)
        defaults.synchronize()
        
        return true
    }
    
    
    // MARK: - Colorize
    
    override func getColorizeArguments(url: URL, custom_settings: SettingsRendering) throws -> ColorizeArguments {
        var r = try super.getColorizeArguments(url: url, custom_settings: custom_settings)
        
        if !custom_settings.themeLua.isEmpty {
            r.inlineTheme = custom_settings.themeLua
            //r.theme = inline_theme.name
            //r.backgroundColor = inline_theme.backgroundColor
        }
        
        return r
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    func colorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SettingsRendering
        
        // Get current settings.
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.settings(forUTI: uti)
        } else {
            custom_settings = SettingsRendering(settings: settings.toDictionary())
        }
        
        // Override the settings.
        custom_settings.override(fromDictionary: overrideSettings as? [String: AnyHashable])
        
        colorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Settings to use, is nil uses the current settings.
    ///   - data: Data returned by highlight.
    ///   - error: Error returned by the colorize process.
    func colorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (_ data: Data, NSDictionary, _ error: Error?) -> Void) {
        var custom_settings: SettingsRendering
        
        if let s = settings as? [String : AnyHashable] {
            custom_settings = SettingsRendering(settings: s)
        } else {
            // Get current settings.
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.settings(forUTI: uti)
            } else {
                custom_settings = SettingsRendering(settings: self.settings.toDictionary())
            }
        }
        
        do {
            let result = try doColorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted html code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    ///   - html: The html output code.l
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func htmlColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (_ html: String, _ settings: NSDictionary, _ error: Error?) -> Void) {
        let custom_settings: SettingsRendering
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = self.settings.settings(forUTI: uti)
        } else {
            custom_settings = SettingsRendering(settings: settings.toDictionary())
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: AnyHashable])
        
        htmlColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    /// Colorize a source file returning a formatted html code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Render settings.
    ///   - html: The html output code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func htmlColorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (_ html: String, _ settings: NSDictionary, _ error: Error?) -> Void) {
        let custom_settings: SettingsRendering
        
        if let s = settings as? [String: AnyHashable] {
            custom_settings = SettingsRendering(settings: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.settings(forUTI: uti)
            } else {
                custom_settings = SettingsRendering(settings: self.settings.toDictionary())
            }
        }
        
        custom_settings.format = .html
        do {
            let result = try doColorize(url: url, custom_settings: custom_settings)
            reply(result.result.output() ?? "", result.settings as NSDictionary, nil)
        } catch {
            reply("<pre>" + error.localizedDescription + "</pre>", custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    ///   - rtfData: Data with the rtf code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func rtfColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (_ rtfData: Data, _ settings: NSDictionary, _ error: Error?) -> Void) {
        let custom_settings: SettingsRendering
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = self.settings.settings(forUTI: uti)
        } else {
            custom_settings = SettingsRendering(settings: settings.toDictionary())
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: AnyHashable])
        
        rtfColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Render settings.
    ///   - rtfData: Data with the rtf code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func rtfColorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (_ rtfData: Data, _ settings: NSDictionary, _ error: Error?) -> Void) {
        let custom_settings: SettingsRendering
        
        if let s = settings as? [String: AnyHashable] {
            custom_settings = SettingsRendering(settings: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.settings(forUTI: uti)
            } else {
                custom_settings = SettingsRendering(settings: self.settings.toDictionary())
            }
        }
        
        custom_settings.format = .rtf
        do {
            let result = try doColorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    
    // MARK: - Themes
    
    func getCustomThemesFolder(createIfMissing: Bool = true, reply: @escaping (URL?)->Void) {
        let u = getCustomThemesUrl(createIfMissing: createIfMissing)
        reply(u)
    }
    
    /// Delete a custom theme.
    /// Any references of deleted theme in the settings are replaced with a default theme.
    /// - parameters:
    ///   - name: Name of the theme. Is equal to the file name.
    ///   - reply:
    ///   - changed: True if the settings are changed.
    func updateSettingsAfterThemeDeleted(name: String, withReply reply: @escaping (_ changed: Bool) -> Void) {
        // Search if any settings use the deleted theme.
        let name = "!\(name)"
        var changed = false
        if settings.lightThemeName == name {
            settings.lightThemeName = "edit-kwrite"
            changed = true
        }
        if settings.darkThemeName == name {
            settings.darkThemeName = "edit-vim-dark"
            changed = true
        }
        for (_, settings) in self.settings.utiSettings {
            if settings.lightThemeName == name {
                settings.lightThemeName = "edit-kwrite"
                settings.isLightThemeNameDefined = false
                changed = true
            }
            if settings.darkThemeName == name {
                settings.darkThemeName = "edit-vim-dark"
                settings.isDarkThemeNameDefined = false
                changed = true
            }
        }
        if changed {
            // Save the changed settings.
            settings.synchronize(domain: type(of: self).XPCDomain, CSSFolder: type(of: self).getCustomStylesUrl(createIfMissing: true))
        }
        
        reply(changed)
    }
    
    // MARK: - Custom styles
    
    // MARK: - Settings

    override internal class func initSettings() -> Settings {
        let settings = super.initSettings()
        settings.populateAllSpecialSettings(supportFolder: applicationSupportUrl, serviceBundle: self.serviceBundle)
        if let dir = self.getCustomStylesUrl(createIfMissing: false) {
            settings.populateUTIsCSS(cssFolder: dir)
        }
        
        return settings
    }
    
    /// Get settings.
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void) {
        reply(self.settings.toDictionary() as NSDictionary)
    }
    
    /// Set and store the settings.
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void) {
        if let s = settings as? [String: AnyHashable] {
            let new_settings = Settings(settings: s)
            
            let CSSFolder = type(of: self).getCustomStylesUrl(createIfMissing: true)
            if let CSSFolder = CSSFolder {
                // Delete custom CSS for a not handled uti.
                
                for uti in self.settings.utiSettings.keys.filter({ !new_settings.utiSettings.keys.contains($0) }) {
                    try? self.settings.utiSettings[uti]?.purgeCSS(inFolder: CSSFolder)
                }
            }
            
            for (_, settings) in new_settings.utiSettings {
                settings.isSpecialSettingsPopulated = true
            }
            
            self.settings = new_settings
            reply(new_settings.synchronize(domain: type(of: self).XPCDomain, CSSFolder: CSSFolder))
        } else {
            reply(false)
        }
    }
    
    func getSettingsURL(reply: @escaping (_ url: URL?)->Void) {
        reply(type(of: self).preferencesUrl?.appendingPathComponent(type(of: self).XPCDomain + ".plist"))
    }
    
    /// Return the url of the application support folder that contains themes and custom css styles.
    func getApplicationSupport(reply: @escaping (_ url: URL?)->Void) {
        reply(type(of: self).applicationSupportUrl)
    }
}

fileprivate extension Dictionary {
    subscript(jsonDict key: Key) -> [String: Any]? {
        get {
            return self[key] as? [String: Any]
        }
        set {
            self[key] = newValue as? Value
        }
    }
    
    subscript(customizedTypes key: Key) -> [String: [String: Any]]? {
        get {
            return self[key] as? [String: [String: Any]]
        }
        set {
            self[key] = newValue as? Value
        }
    }
}
