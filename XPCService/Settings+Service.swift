//
//  Settings+Service.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 01/04/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import OSLog
import Yams

protocol SettingsCSS: SettingsBase {
    func getCSSFile(inFolder folder: URL) -> URL
    func exportCSSFile(toFolder folder: URL) throws
    func purgeCSS(inFolder folder: URL) throws
}

extension SettingsCSS {
    func exportCSSFile(toFolder folder: URL) throws {
        let file = getCSSFile(inFolder: folder)
        
        if !self.isCSSDefined || self.css.isEmpty {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        } else {
            try self.css.write(to: file, atomically: true, encoding: .utf8)
        }
        self.isCSSDefined = true
    }
    
    func purgeCSS(inFolder folder: URL) throws {
        let file = getCSSFile(inFolder: folder)
        if FileManager.default.fileExists(atPath: file.path) {
            try FileManager.default.removeItem(at: file)
            self.lockRefresh()
            self.isCSSDefined = false
            self.css = ""
            self.unlockRefresh()
        }
    }
}

extension SettingsFormat: SettingsCSS {
    /// Get the url of a custom .plist file with some special settings fort the UTI.
    static func getSpecialSettingsFile(uti: String, supportFolder: URL?, serviceBundle: Bundle?) -> URL? {
        if let supportFile = supportFolder?.appendingPathComponent("defaults/\(uti).plist"), FileManager.default.fileExists(atPath: supportFile.path) {
            // Customized file is inside the application support folder.
            return supportFile
        } else if let file = serviceBundle?.path(forResource: uti, ofType: "plist", inDirectory: "highlight/defaults") {
            // Customized file is inside the application resources folder.
            return URL(fileURLWithPath: file)
        } else {
            return nil
        }
    }
    
    /// Fill the CSS with value of associated file.
    /// - parameters:
    ///   - cssFolder: Folder for search the CSS file.
    func populateCSS(fromFolder folder: URL) {
        populateCSS(fromFile: self.getCSSFile(inFolder: folder))
    }
    
    /// Fill the CSS with value of associated file.
    /// - parameters:
    ///   - file: CSS file.
    func populateCSS(fromFile file: URL) {
        if file.pathExtension == "css", !isCSSPopulated, let style = try? String(contentsOf: file, encoding: .utf8), !style.isEmpty {
            self.isCSSPopulated = true
            self.css = style
            self.isCSSDefined = true
        }
    }
    
    func getCSSFile(inFolder folder: URL) -> URL {
        return folder.appendingPathComponent(self.uti).appendingPathExtension("css")
    }
}

extension Settings: SettingsCSS {
    /// Initialize from a preferences loaded from the domain defaults.
    convenience init(defaultsDomain domain: String) {
        let defaults = UserDefaults.standard
        // Remember that macOS store the precerences inside a cache. If you manual edit the preferences file you need to reset this cache:
        // $ killall -u $USER cfprefsd
        let defaultsDomain = defaults.persistentDomain(forName: domain) as? [String: AnyHashable] ?? [:]
        self.init(settings: defaultsDomain)
    }
    
    func populateAllSpecialSettings(supportFolder: URL?, serviceBundle: Bundle) {
        self.isAllSpecialSettingsPopulated = true
        
        // Process files on bundle the application support folder.
        var enc: String.Encoding = .utf8
        if let p = serviceBundle.url(forResource: "settings", withExtension: "yaml"), let data = try? String(contentsOf: p, usedEncoding: &enc) {
            do {
                if let raw_d = try Yams.load(yaml: data) {
                    if let d = raw_d as? [String: [String: [String: String]]] {
                        self.specialSettings = d
                    } else {
                        if #available(macOS 13.0, *) {
                            os_log(OSLogType.error, "Settings %{public}s is not valid!", p.path(percentEncoded: false))
                        } else {
                            os_log(OSLogType.error, "Settings %{public}s is not valid!", p.path)
                        }
                    }
                }
            } catch {
                if #available(macOS 13.0, *) {
                    os_log(OSLogType.error, "Settings %{public}s is not valid yaml file!", p.path(percentEncoded: false))
                } else {
                    os_log(OSLogType.error, "Settings %{public}s is not valid yaml file!", p.path)
                }
                print(error)
            }
        }
        
        // Process files on support folder.
        enc = .utf8
        if let p = supportFolder?.appendingPathComponent("settings.yaml"), let data = try? String(contentsOf: p, usedEncoding: &enc) {
            do {
                if let raw_d = try Yams.load(yaml: data) {
                    if let d = raw_d as? [String: [String: [String: String]]] {
                        for group in d {
                            if self.specialSettings[group.key] == nil {
                                self.specialSettings[group.key] = [:]
                            }
                            for item in group.value {
                                if self.specialSettings[group.key]![item.key] == nil {
                                    self.specialSettings[group.key]![item.key] = item.value
                                } else {
                                    self.specialSettings[group.key]![item.key] = self.specialSettings[group.key]![item.key]?.merging(item.value, uniquingKeysWith: { _, new in
                                        return new
                                    })
                                }
                            }
                        }
                    } else {
                        if #available(macOS 13.0, *) {
                            os_log(OSLogType.error, "Settings %{public}s is not valid!", p.path(percentEncoded: false))
                        } else {
                            os_log(OSLogType.error, "Settings %{public}s is not valid!", p.path)
                        }
                    }
                }
            } catch {
                if #available(macOS 13.0, *) {
                    os_log(OSLogType.error, "Settings %{public}s is not valid yaml file!", p.path(percentEncoded: false))
                } else {
                    os_log(OSLogType.error, "Settings %{public}s is not valid yaml file!", p.path)
                }
                print(error)
            }
        }
        
        if let utis = self.specialSettings["UTIs"] {
            for item in utis {
                let uti_settings = self.utiSettings[item.key] ?? self.createSettings(forUTI: item.key)
                if let v = item.value["syntax"] {
                    uti_settings.specialSyntax = v
                }
                if let v = item.value["preprocessor"] {
                    uti_settings.specialPreprocessor = v
                }
                if let v = item.value["extra"] {
                    uti_settings.specialAppendArguments = v
                }
            }
        }
    }
    
    /// Fill the CSS with value of associated file.
    /// - parameters:
    ///   - cssFolder: Folder for search the CSS file.
    func populateCSS(cssFolder: URL) {
        if let style = try? String(contentsOf: getCSSFile(inFolder: cssFolder), encoding: .utf8), !style.isEmpty {
            self.css = style
            self.isCSSDefined = true
        }
    }
    
    func getCSSFile(inFolder folder: URL) -> URL {
        return folder.appendingPathComponent("global.css")
    }
    
    /// Process all CSS files.
    /// - parameters:
    ///   - cssFolder: Folder for search the CSS file.
    func populateUTIsCSS(cssFolder: URL) {
        self.isAllCSSPopulated = true
        
        // Populate the custom css.
        if let files = try? FileManager.default.contentsOfDirectory(at: cssFolder, includingPropertiesForKeys: nil, options: []) {
            for file in files {
                guard file.pathExtension == "css" else {
                    continue
                }
                
                let uti = file.deletingPathExtension().lastPathComponent
                if uti != "global" {
                    if !self.hasSettings(forUTI: uti) {
                        _ = self.createSettings(forUTI: uti)
                    }
                    self.utiSettings[uti]?.populateCSS(fromFile: file)
                }
            }
        }
    }
    
    
    /// Save the settings to the defaults preferences.
    @discardableResult
    func synchronize(domain: String, CSSFolder: URL?) -> Bool {
        guard !domain.isEmpty else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: domain) ?? [:]
        
        let updateDomains = { (key: String, value: AnyHashable?) -> Void in
            if let v = value {
                defaultsDomain[key] = v
            } else {
                defaultsDomain.removeValue(forKey: key)
            }
        }
        
        updateDomains(SettingsBase.Key.version, self.version)
        
        updateDomains(SettingsBase.Key.format, self.format.rawValue)
        
        updateDomains(SettingsBase.Key.lightTheme, lightThemeName.isEmpty ? nil : lightThemeName)
        updateDomains(SettingsBase.Key.lightBackgroundColor, lightBackgroundColor)
        updateDomains(SettingsBase.Key.lightForegroundColor, lightForegroundColor)
        
        updateDomains(SettingsBase.Key.darkTheme, darkThemeName.isEmpty ? nil : darkThemeName)
        updateDomains(SettingsBase.Key.darkBackgroundColor, darkBackgroundColor)
        updateDomains(SettingsBase.Key.darkForegroundColor, darkForegroundColor)
        
        updateDomains(SettingsBase.Key.lineNumbers, self.isLineNumbersVisible)
        updateDomains(SettingsBase.Key.lineNumbersFillToZeroes, self.isLineNumbersFillToZeroes)
        
        updateDomains(SettingsBase.Key.wordWrap, self.isWordWrapped ? (self.isWordWrappedIndented ? 2 : 1) : 0)
        updateDomains(SettingsBase.Key.wordWrapHard, self.isWordWrappedHard)
        updateDomains(SettingsBase.Key.wordWrapOneLineFiles, self.isWordWrappedSoftForOneLineFiles)
        updateDomains(SettingsBase.Key.lineLength, lineLength)
        
        updateDomains(SettingsBase.Key.tabSpaces, tabSpaces)
        
        updateDomains(SettingsBase.Key.extraArguments, arguments)
        
        updateDomains(SettingsBase.Key.fontFamily, fontName)
        updateDomains(SettingsBase.Key.fontSize, fontSize)
        
        updateDomains(SettingsBase.Key.maxData, maxData)
        updateDomains(SettingsBase.Key.interactive, allowInteractiveActions)
        updateDomains(SettingsBase.Key.convertEOL, convertEOL)
        updateDomains(SettingsBase.Key.debug, isDebug)
        updateDomains(SettingsBase.Key.about, isAboutVisible)
        
        updateDomains(SettingsBase.Key.dumpPlain, isDumpPlainData)
        updateDomains(SettingsBase.Key.vcs, isVCS)
        updateDomains(SettingsBase.Key.vcs_add_light, self.vcsAddLightColor)
        updateDomains(SettingsBase.Key.vcs_add_dark, self.vcsAddDarkColor)
        updateDomains(SettingsBase.Key.vcs_edit_light, self.vcsEditLightColor)
        updateDomains(SettingsBase.Key.vcs_edit_dark, self.vcsEditDarkColor)
        updateDomains(SettingsBase.Key.vcs_del_light, self.vcsDelLightColor)
        updateDomains(SettingsBase.Key.vcs_del_dark, self.vcsDelDarkColor)
        updateDomains(SettingsBase.Key.git_path, gitPath)
        updateDomains(SettingsBase.Key.hg_path, hgPath)
        updateDomains(SettingsBase.Key.svn_path, svnPath)
        
        updateDomains(SettingsBase.Key.qlWidth, qlWindowWidth ?? 0)
        updateDomains(SettingsBase.Key.qlHeight, qlWindowHeight ?? 0)
        
        var customized_formats: [String: [String: AnyHashable]] = [:]
        for (uti, settings) in self.utiSettings {
            var d = settings.toDictionary(forSaving: true)
            d.removeValue(forKey: SettingsBase.Key.customCSS) // CSS is saved on external files.
            if d.count > 0 {
                customized_formats[uti] = d
            }
            if let folder = CSSFolder {
                try? settings.exportCSSFile(toFolder: folder)
            }
        }
        
        if let folder = CSSFolder {
            try? self.exportCSSFile(toFolder: folder)
        }
        
        updateDomains(SettingsBase.Key.customizedUTISettings, customized_formats.count > 0 ? customized_formats : nil)
        
        var plain_formats: [[String: AnyHashable]] = []
        for settings in self.getPlainSettings() {
            let d = settings.toDictionary(forSaving: true)
            if !d.isEmpty {
                plain_formats.append(d)
            }
        }
        updateDomains(SettingsBase.Key.plainSettings, plain_formats.count > 0 ? plain_formats : nil)
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: domain)
        
        if userDefaults.synchronize() {
            DistributedNotificationCenter.default().post(name: .SettingsUpdated, object: nil)
            return true
        } else {
            return false
        }
    }
}
