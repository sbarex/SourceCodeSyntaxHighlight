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
    // MARK: Initializers
    
    /// Return the folder for the application support files.
    static var preferencesUrl: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Preferences")
    }
    
    override internal class func initSettings() -> SCSHGlobalBaseSettings {
        let s = SCSHSettings(defaultsDomain: XPCDomain)
        populateSpecialSettings(s)
        return s
    }
    
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
        
        super.init()
        
        migrate(settings: settings)
    }

    /// Migrate the stored settings to the current format.
    @discardableResult
    internal func migrate(settings: SCSHGlobalBaseSettings) -> Bool {
        guard settings.version < SCSHSettings.version else {
            return false
        }
        
        if settings.version <= 2.1 {
            for (_, uti_settings) in settings.customizedSettings {
                guard let preprocessor = uti_settings.preprocessor, !preprocessor.isEmpty else {
                    continue
                }
                if preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) == nil {
                    // Append the target placeholder at the end of the preprocessor command.
                    uti_settings.preprocessor = preprocessor.appending(" $targetHL")
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
        
        // "commands-toolbar" is not yet used.
        defaultsDomain.removeValue(forKey: "commands-toolbar")
        
        // "theme-light-is16" and "theme-dark-is16" are replaced by "base16/" prefix on theme name.
        let migrateBase16 = { (settings: SCSHBaseSettings, defaultsDomain: inout [String: Any], UTI: String) -> Bool in
            var changed = false
            if let lightThemeIsBase16 = (UTI.isEmpty ? defaultsDomain : defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]![jsonDict: UTI]!)["theme-light-is16"] as? Bool {
                if lightThemeIsBase16, let t = settings.lightTheme, !t.hasPrefix("base16") {
                    settings.lightTheme = "base16/\(t)"
                }
                if UTI.isEmpty {
                    defaultsDomain.removeValue(forKey: "theme-light-is16")
                } else {
                    defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "theme-light-is16")
                }
                changed = true
            }
            if let darkThemeIsBase16 = (UTI.isEmpty ? defaultsDomain : defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]![jsonDict: UTI]!)["theme-dark-is16"] as? Bool {
                if darkThemeIsBase16, let t = settings.darkTheme, !t.hasPrefix("base16") {
                    settings.darkTheme = "base16/\(t)"
                }
                if UTI.isEmpty {
                    defaultsDomain.removeValue(forKey: "theme-dark-is16")
                } else {
                    defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "theme-dark-is16")
                }
                changed = true
            }
            return changed
        }
        
        // Custom CSS are saved on external files.
        let migrateCSS = { (settings: SCSHBaseSettings, defaultsDomain: inout [String: Any], UTI: String) -> Bool in
            var changed = false
            if let customCSS = (!UTI.isEmpty ? defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]![jsonDict: UTI]! : defaultsDomain)["css"] as? String {
                if let success = try? self.setCustomStyle(customCSS, forUTI: UTI), success {
                    if UTI.isEmpty {
                        defaultsDomain.removeValue(forKey: "css")
                    } else {
                        defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]?[jsonDict: UTI]?.removeValue(forKey: "css")
                    }
                    changed = true
                }
            }
            return changed
        }
        
        _ = migrateBase16(settings, &defaultsDomain, "")
        _ = migrateCSS(settings, &defaultsDomain, "")
        
        if let custom_formats = defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings] {
            for (uti, _) in custom_formats {
                var utiDefaultsDomain = (defaultsDomain[SCSHSettings.Key.customizedUTISettings] as! [String: [String: Any]])[uti]!
                if let s = settings.getCustomizedSettings(forUTI: uti) {
                    _ = migrateBase16(s, &defaultsDomain, uti)
                    _ = migrateCSS(s, &defaultsDomain, uti)
                    
                    if settings.version <= 2.1, let preprocessor = utiDefaultsDomain["preprocessor"] as? String, !preprocessor.isEmpty, preprocessor.range(of: #"(?<=\s|^)\$targetHL(?=\s|$)"#, options: .regularExpression, range: nil, locale: nil) == nil {
                        defaultsDomain[customizedTypes: SCSHSettings.Key.customizedUTISettings]![uti]!["preprocessor"] = preprocessor.appending(" $targetHL")
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
        settings.version = SCSHSettings.version
        defaultsDomain[SCSHSettings.Key.version] = SCSHSettings.version
        
        // Store the converted settings.
        defaults.setPersistentDomain(defaultsDomain, forName: type(of: self).XPCDomain)
        defaults.synchronize()
        
        return true
    }
    
    
    // MARK: Colorize
    
    override func getColorizeArguments(url: URL, custom_settings: SCSHGlobalBaseSettings) throws -> ColorizeArguments {
        var r = try super.getColorizeArguments(url: url, custom_settings: custom_settings)
        
        if let settings = custom_settings as? SCSHSettings, let inline_theme = settings.inlineTheme {
            r.inlineTheme = inline_theme.getLua()
            r.theme = inline_theme.name
            r.backgroundColor = inline_theme.backgroundColor
        }
        
        return r
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    func colorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHGlobalBaseSettings
        
        // Get current settings.
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettings(forUTI: uti)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        
        // Override the settings.
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        colorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Settings to use, is nil uses the current settings.
    ///   - data: Data returned by highlight.
    ///   - error: Error returned by the colorize process.
    func colorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (_ data: Data, NSDictionary, _ error: Error?) -> Void) {
        var custom_settings: SCSHGlobalBaseSettings
        
        if let s = settings as? [String : Any] {
            custom_settings = SCSHSettings(settings: s)
        } else {
            // Get current settings.
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettings(forUTI: uti)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
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
        let custom_settings: SCSHGlobalBaseSettings
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettings(forUTI: uti)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
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
        let custom_settings: SCSHGlobalBaseSettings
        
        if let s = settings as? [String: Any] {
            custom_settings = SCSHSettings(settings: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettings(forUTI: uti)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
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
        let custom_settings: SCSHGlobalBaseSettings
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettings(forUTI: uti)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
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
        let custom_settings: SCSHGlobalBaseSettings
        
        if let s = settings as? [String: Any] {
            custom_settings = SCSHSettings(settings: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettings(forUTI: uti)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
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
    
    /// Get the list of available themes.
    /// - parameters:
    ///   - themes: Array of themes exported as a dictionary [String: Any].
    ///   - error: Error during the extraction of the themes.   
    func getThemes(withReply reply: @escaping (_ themes: [NSDictionary], _ error: Error?) -> Void) {
        self.getThemes(highlight: self.settings.highlightProgramPath, withReply: reply)
    }
    
    /// Get the list of available themes.
    /// - parameters:
    ///   - highlightPath: Path of highlight. If empty or "-" use the embedded highlight.
    ///   - reply: Callback.
    ///   - themes: Array of themes exported as a dictionary [String: Any].
    ///   - error: Error during the extraction of the themes.
    func getThemes(highlight highlightPath: String, withReply reply: @escaping (_ themes: [NSDictionary], _ error: Error?) -> Void) {
        var themes: [SCSHTheme] = []
        var execution_error: Error? = nil
        
        defer {
            // Sort the list.
            themes.sort { (a, b) -> Bool in
                return a.desc < b.desc
            }
            
            reply(themes.map({ $0.toDictionary() as NSDictionary }), execution_error)
        }
        
        let fileManager = FileManager.default
        
        // Search for custom themes.
        if let customThemeDir = getCustomThemesUrl(createIfMissing: false) {
            let files: [URL]
            do {
                files = try fileManager.contentsOfDirectory(at: customThemeDir, includingPropertiesForKeys: nil, options: [])
            } catch {
                files = []
            }
            for file in files {
                guard file.pathExtension == "theme" else {
                    continue
                }
                if let theme = try? SCSHTheme(url: file) {
                    theme.isStandalone = false
                    themes.append(theme)
                }
            }
        }
        
        // Search for standalone themes.
        let result: ShellTask.TaskResult
        
        let highlight_executable: String
        let env: [String: String]
        if highlightPath == "-" || highlightPath == "" {
            let r = self.getEmbeddedHighlight()
            highlight_executable = r.path
            env = r.env
        } else {
            highlight_executable = highlightPath
            env = [:]
        }
        do {
            guard highlight_executable != "", highlight_executable != "false" else {
                return
            }
            result = try ShellTask.runTask(script: "\(highlight_executable.g_shell_quote()) --list-scripts=theme", env: env)
            guard result.isSuccess else {
                return
            }
        } catch {
            execution_error = error
            return
        }
        
        guard let output = result.output(), let regex = try? NSRegularExpression(pattern: #"^(.+)\s+:\s+(.+)$"#, options: []) else {
            return
        }
        
        let theme_dir_url: URL?
        
        if let regex_dir = try? NSRegularExpression(pattern: #"Installed themes \(located in (.+)\):"#, options: []), let match = regex_dir.firstMatch(in: output, options: [], range: NSRange(output.startIndex ..< output.endIndex, in: output)) {
            let firstCaptureRange = Range(match.range(at: 1), in: output)!
            let theme_dir = String(output[firstCaptureRange].trimmingCharacters(in: CharacterSet.whitespaces))
            
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: theme_dir, isDirectory: &isDir) && isDir.boolValue {
                theme_dir_url = URL(fileURLWithPath: theme_dir, isDirectory: true)
            } else {
                theme_dir_url = nil
            }
        } else {
            theme_dir_url = nil
        }
        
        for line in output.split(separator: "\n").map({ String($0) }) {
            let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, options: [], range: nsrange) {
                let firstCaptureRange = Range(match.range(at: 1), in: line)!
                let name = line[firstCaptureRange].trimmingCharacters(in: CharacterSet.whitespaces)
                // Parse theme file.
                if let theme_url = theme_dir_url?.appendingPathComponent("\(name).theme"), let theme = try? SCSHTheme(url: theme_url) {
                    let name = theme_url.deletingPathExtension().path.replacingOccurrences(of: theme_dir_url!.path+"/", with: "")
                    theme.name = name
                    themes.append(theme)
                }
            }
        }
    }
    
    /// Save a custom theme to a file.
    /// The file is located inside the application support directory, with the name of the theme.
    /// If the theme had previously been saved with a different name, it is registered with the new name and the old file deleted.
    /// An existing file will be overwritten.
    /// When renaming a theme will be search if the old name is used in the settings and then updated.
    /// - parameters:
    ///   - theme: Theme exported as dictionary.
    ///   - success: True if the theme is correctly saved.
    ///   - error: Error on saving operation.
    func saveTheme(_ theme: NSDictionary, withReply reply: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        if let t = SCSHTheme(dict: theme as? [String: Any]) {
            if let u = getCustomThemesUrl(createIfMissing: true)?.appendingPathComponent("\(t.name).theme") {
                do {
                    let originalName = t.originalName
                    // Save to the url.
                    try t.save(to: u)
                    if originalName != "" && originalName != t.name, let originalUrl = getCustomThemesUrl(createIfMissing: true)?.appendingPathComponent("\(originalName).theme"), FileManager.default.fileExists(atPath: originalUrl.path) {
                        // The theme previously had another name.
                        
                        // Delete the previous file.
                        try? FileManager.default.removeItem(at: originalUrl)
                        
                        // Search if any settings use the renamed theme.
                        let oldName = "!\(originalName)"
                        let newName = "!\(t.name)"
                        var changed = false
                        if settings.lightTheme == oldName {
                            settings.lightTheme = newName
                            changed = true
                        }
                        if settings.darkTheme == oldName {
                            settings.darkTheme = newName
                            changed = false
                        }
                        for (_, settings) in self.settings.customizedSettings {
                            if settings.lightTheme == oldName {
                                settings.lightTheme = newName
                                changed = true
                            }
                            if settings.darkTheme == oldName {
                                settings.darkTheme = newName
                                changed = false
                            }
                        }
                        if changed {
                            // Save the changed settings.
                            (settings as? SCSHSettings)?.synchronize(domain: type(of: self).XPCDomain)
                        }
                    }
                    
                    reply(true, nil)
                } catch {
                    reply(false, error)
                }
            }
        }
        
        reply(false, nil)
    }
    
    /// Delete a custom theme.
    /// Any references of deleted theme in the settings are replaced with a default theme.
    /// - parameters:
    ///   - name: Name of the theme. Is equal to the file name.
    ///   - success: True if the theme is correctly deleted.
    ///   - error: Error on deleting operation.
    func deleteTheme(name: String, withReply reply: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        if let originalUrl = getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent("\(name).theme"), FileManager.default.fileExists(atPath: originalUrl.path) {
            do {
                try FileManager.default.removeItem(at: originalUrl)
                
                // Search if any settings use the deleted theme.
                let name = "!\(name)"
                var changed = false
                if settings.lightTheme == name {
                    settings.lightTheme = "edit-kwrite"
                    changed = true
                }
                if settings.darkTheme == name {
                    settings.darkTheme = "edit-vim-dark"
                    changed = false
                }
                for (_, settings) in self.settings.customizedSettings {
                    if settings.lightTheme == name {
                        settings.lightTheme = "edit-kwrite"
                        changed = true
                    }
                    if settings.darkTheme == name {
                        settings.darkTheme = "edit-vim-dark"
                        changed = false
                    }
                }
                if changed {
                    // Save the changed settings.
                    (settings as? SCSHSettings)?.synchronize(domain: type(of: self).XPCDomain)
                }
                
                reply(true, nil)
            } catch {
                reply(false, error)
            }
        } else {
            reply(true, nil)
        }
    }
    
    
    // MARK: - Custom styles
    
    /// Get a custom CSS style for a UTI.
    /// - parameters:
    ///   - uti: UTI associated to the style. Il empty is search the global style for all files.
    /// - returns: Return an empty string if there the css style don't exists.
    func getCustomStyleForUTI(uti: String) throws -> String {
        if let url = getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent(uti.isEmpty ? "global" : uti).appendingPathExtension("css"), FileManager.default.fileExists(atPath: url.path) {
            return try String(contentsOf: url, encoding: .utf8)
        } else {
            return ""
        }
    }
    
    /// Get a custom CSS style for a UTI.
    /// - parameters:
    ///   - uti: UTI associated to the style. Il empty is search the global style for all files.
    ///   - style: Custom CSS style.
    ///   - error: Error on saving file.
    func getCustomStyleForUTI(uti: String, reply: @escaping (_ style: String, _ error: Error?) -> Void) {
        do {
            let s = try getCustomStyleForUTI(uti: uti)
            reply(s, nil)
        } catch {
            reply("", error)
        }
    }
    
    /// Save a custom style for a uti to a file.
    /// - parameters:
    ///   - style: CSS style. If it's empty delete the associated file.
    ///   - uti: UTI associated to the style. Il empty is used for all files.
    @discardableResult
    func setCustomStyle(_ style: String, forUTI uti: String) throws -> Bool {
        guard let url = getCustomStylesUrl(createIfMissing: true)?.appendingPathComponent(uti.isEmpty ? "global" : uti).appendingPathExtension("css") else {
            return false
        }
        
        if style.isEmpty {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } else {
            try style.write(to: url, atomically: true, encoding: .utf8)
        }
        return true
    }
    
    /// Save a custom style for a uti to a file.
    /// - parameters:
    ///   - style: CSS style.
    ///   - uti: UTI associated to the style. Il empty is used for all files.
    ///   - success: True if file is saved correctly.
    ///   - error: Error on saving file.
    func setCustomStyle(_ style: String, forUTI uti: String, reply: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        do {
            let r = try setCustomStyle(style, forUTI: uti)
            reply(r, nil)
        } catch {
            reply(false, error)
        }
    }
    
    
    // MARK: - Settings
    
    /// Get settings.
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void) {
        let settings = SCSHSettings(settings: self.settings)
        
        // Populate the custom css.
        if let stylesDir = getCustomStylesUrl(createIfMissing: false), let files = try? FileManager.default.contentsOfDirectory(at: stylesDir, includingPropertiesForKeys: nil, options: []) {
            for file in files {
                guard file.pathExtension == "css" else {
                    continue
                }
                
                if let style = try? String(contentsOf: file, encoding: .utf8) {
                    let uti = file.deletingPathExtension().lastPathComponent
                    if uti != "global" {
                        let s = settings.getCustomizedSettings(forUTI: uti)
                        s?.css = style
                    } else {
                        settings.css = style
                    }
                }
            }
        }
        
        reply(settings.toDictionary() as NSDictionary)
    }
    
    /// Set and store the settings.
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void) {
        if let s = settings as? [String: Any] {
            let UTIs = Array(self.settings.customizedSettings.keys)
            let new_settings = SCSHSettings(settings: s)
            self.settings = new_settings
            reply(new_settings.synchronize(domain: type(of: self).XPCDomain))
            
            let newUTIs = Array(self.settings.customizedSettings.keys)
            
            // Save / Delete the custom css code.
            _ = try? setCustomStyle(self.settings.css ?? "", forUTI: "")
            for (uti, utiSettings) in self.settings.customizedSettings {
                _ = try? setCustomStyle(utiSettings.css ?? "", forUTI: uti)
            }
            for uti in UTIs.filter({ !newUTIs.contains($0) }) {
                // Delete custom CSS for a not handled uti.
                _ = try? setCustomStyle("", forUTI: uti)
            }
        } else {
            reply(false)
        }
    }
    
    /// Return the url of the application support folder that contains themes and custom css styles.
    func getApplicationSupport(reply: @escaping (_ url: URL?)->Void) {
        reply(type(of: self).applicationSupportUrl)
    }
    
    func getXPCPath(replay: @escaping (URL)->Void) {
        replay(Bundle.main.bundleURL)
    }
    
    // MARK: Highlight
    
    func locateHighlight(reply: @escaping ([[Any]]) -> Void) {
        let current = self.settings.highlightProgramPath
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        let parse_version = { (path: String, env: [String: String]) -> String? in
            guard let r = try? ShellTask.runTask(script: "\(path.g_shell_quote()) --version", env: env), r.isSuccess, let output = r.output(), output.contains("Andre Simon"), let regex = try? NSRegularExpression(pattern: #"highlight version (\d\.\d+)"#, options: []) else {
                return nil
            }
            
            guard let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex ..< output.endIndex, in: output)) else {
                return nil
            }
            let firstCaptureRange = Range(match.range(at: 1), in: output)!
            let version = String(output[firstCaptureRange])
            
            return version
        }
        
        var result: [[Any]] = []
        
        let embedHighlight = self.getEmbeddedHighlight()
        if let v = parse_version(embedHighlight.path, embedHighlight.env) {
            result.append([embedHighlight.path, v, true])
        }
        var found = false
        if let r = try? ShellTask.runTask(script: "which -a highlight", env: env), r.isSuccess, let output = r.output() {
            let paths = output.split(separator: "\n")
            for path in paths {
                if let v = parse_version(String(path), env) {
                    result.append([path, v, false])
                    if current == path {
                        found = true
                    }
                }
            }
        }
        if !found && current != "" && current != "-", let v = parse_version(String(current), env) {
            // Parse current customized highlight path.
            result.append([current, v, false])
        }
        
        reply(result)
    }
    
    /// Return info about highlight.
    /// - parameters:
    ///   - highlight: Path of highlight. Empty or "-" for use the embedded version.
    func highlightInfo(highlight: String, reply: @escaping (String) -> Void) {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        var highlightPath = highlight
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbeddedHighlight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        }
        
        var text = ""
        
        /// Command to execute.
        var cmd = "\(highlightPath.g_shell_quote()) --version"
        
        if let result = try? ShellTask.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=langs"
        if let result = try? ShellTask.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=themes"
        if let result = try? ShellTask.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=plugins"
        if let result = try? ShellTask.runTask(script: cmd, env: env), let s = result.output()  {
            text += s + "\n\n"
        }
        
        if text.isEmpty {
            text += "Highlight not available!"
        }
        reply(text)
    }
    
    func highlightInfo(reply: @escaping (String) -> Void) {
        highlightInfo(highlight: "-", reply: reply)
    }
    
    /// Get all syntax format supported by highlight.
    /// Returns a dictionary, with on the keys the description of the syntax format, and on values an array of recognized extensions.
    /// - parameters:
    ///   - highlight: Path of highlight. Empty or "-" for use the embedded version.
    func highlightAvailableSyntax(highlight: String, reply: @escaping (NSDictionary) -> Void) {
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        var highlightPath = highlight
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbeddedHighlight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        }
        
        guard highlightPath != "" else {
            reply(NSDictionary())
            return
        }
        
        /// Command to execute.
        let cmd = "echo \"\" | \(highlightPath.g_shell_quote()) --list-scripts=langs"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", env)
        
        var res: [String: [String: Any]] = [:]
        if let result = try? ShellTask.runTask(script: cmd, env: env), result.exitCode == 0, let s = result.output() {
            let rows = s.split(separator: "\n")
            let regex = try! NSRegularExpression(pattern: #"^(.+) +: (.*)$"#)
            for row in rows {
                if let match = regex.firstMatch(in: String(row), options: [], range: NSRange(location: 0, length: row.utf16.count)) {
                    if let descRange = Range(match.range(at: 1), in: row), let extsRange = Range(match.range(at: 2), in: row) {
                        let desc = String(row[descRange]).trimmingCharacters(in: CharacterSet.whitespaces)
                        var exts = String(row[extsRange]).split(separator: " ").map({ String($0) })
                        exts = exts.filter({ $0 != "(" && $0 != ")" })
                        
                        res[desc] = [
                            "extension": exts.first!,
                            "extensions": exts
                        ]
                    }
                }
            }
        }
        reply(res as NSDictionary)
    }
    
    func highlightAvailableSyntax(reply: @escaping (NSDictionary) -> Void) {
        highlightAvailableSyntax(highlight: "-", reply: reply)
    }
    
    /// Check if a file extension is handled by highlight.
    func isSyntaxSupported(_ syntax: String, overrideSettings: NSDictionary?, reply: @escaping (Bool) -> Void) {
        let custom_settings = SCSHSettings(settings: settings)
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        var highlightPath = custom_settings.highlightProgramPath
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbeddedHighlight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        }
        
        guard highlightPath != "" else {
            reply(false)
            return
        }
        
        /// Command to execute.
        let cmd = "echo \"\" | \(highlightPath.g_shell_quote()) -S \(syntax)"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", env)
        
        if let result = try? ShellTask.runTask(script: cmd, env: env) {
            reply(result.exitCode == 0)
        } else {
            reply(false)
        }
    }
    
    /// Check if some of specified file extensions are handled by highlight.
    func areSomeSyntaxSupported(_ syntax: [String], overrideSettings: NSDictionary?, reply: @escaping (Bool) -> Void) {
        let custom_settings = SCSHSettings(settings: settings)
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        var highlightPath = custom_settings.highlightProgramPath
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbeddedHighlight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        }
        
        guard highlightPath != "" else {
            reply(false)
            return
        }
        
        for ext in syntax {
            /// Command to execute.
            let cmd = "echo \"\" | \(highlightPath.g_shell_quote()) -S \(ext)"
            
            os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
            os_log(OSLogType.debug, log: self.log, "env = %@", env)
            
            if let result = try? ShellTask.runTask(script: cmd, env: env), result.exitCode == 0 {
                reply(true)
                return
            }
        }
        
        reply(false)
    }
    
    /*
    /// Add a custom uti to the info.plist of the app and the appex.
    /// **This clear the code signature**
    ///
    /// FIXME: Clearing the signature prevent macos to recognize and use the appex!
    func registerUTI(_ uti: String, result: @escaping (Bool)->Void ) {
        let infoPlistAppex = Bundle.main.resourceURL!.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("PlugIns/Syntax Highlight Quicklook Extension.appex/Contents/Info.plist")
        var task = Process()
        task.launchPath = "/usr/libexec/PlistBuddy"
        task.arguments = [
            "-c",
            "Add :NSExtension:NSExtensionAttributes:QLSupportedContentTypes: string \"\(uti)\"",
            infoPlistAppex.path
        ]
        task.launch()
        task.waitUntilExit()
        print("result Appex: \(task.terminationStatus)")

        guard task.terminationStatus == 0 else {
            result(false)
            return
        }
        
        let infoPlistApp = Bundle.main.resourceURL!.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Info.plist")
        
        task = Process()
        task.launchPath = "/usr/libexec/PlistBuddy"
        task.arguments = [
            "-c",
            "Add :CFBundleDocumentTypes:0:LSItemContentTypes: string \"\(uti)\"",
            infoPlistApp.path
        ]
        task.launch()
        task.waitUntilExit()
        print("result App: \(task.terminationStatus)")
        
        // Strip code signature.
        task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = [
            "--remove-signature",
            infoPlistApp.deletingLastPathComponent().deletingLastPathComponent().path
        ]
        task.launch()
        task.waitUntilExit()
        print("result remove codesign: \(task.terminationStatus)")
        
        result(task.terminationStatus == 0)
    }
 
    */
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
