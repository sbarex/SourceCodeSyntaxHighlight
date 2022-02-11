//
//  Settings+Service.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 01/04/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

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
    
    /// Fill the settings loading a custom .plist file for the UTI (if exists).
    func populateSpecialSettings(supportFolder: URL?, serviceBundle: Bundle?) {
        self.isSpecialSettingsPopulated = true
        
        guard let baseSettings = type(of: self).getSpecialSettingsFile(uti: uti, supportFolder: supportFolder, serviceBundle: serviceBundle)?.path else {
            return
        }
        populateSpecialSettings(fromPlist: URL(fileURLWithPath: baseSettings))
    }
    
    func populateSpecialSettings(fromPlist file: URL) {
        guard let plistXML = FileManager.default.contents(atPath: file.path) else {
            return
        }
        do {
            // Customize the base global settings with the special values inside the plist.
            if let plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainers, format: nil) as? [String: String] {
            
                if let v = plistData[SettingsBase.Key.syntax] {
                    self.specialSyntax = v
                }
                if let v = plistData[SettingsBase.Key.preprocessor] {
                    self.specialPreprocessor = v
                }
                if let v = plistData[SettingsBase.Key.extraArguments] {
                    self.specialAppendArguments = v
                }
            }
        } catch {
            print("Error reading plist \(file.path): \(error)")
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
        
        let process = { (file: String, p: URL) in
            let url = URL(fileURLWithPath: file, relativeTo: p)
            guard url.pathExtension == "plist" else {
                return
            }
            let name = url.deletingPathExtension().lastPathComponent
            let uti_settings = self.utiSettings[name] ?? self.createSettings(forUTI: name)
            uti_settings.populateSpecialSettings(fromPlist: url)
        }
        
        var d: ObjCBool = false
        // Process files on support folder.
        if let supportDir = supportFolder?.appendingPathComponent("defaults"), FileManager.default.fileExists(atPath: supportDir.path, isDirectory: &d), d.boolValue {
            do {
                for file in try FileManager.default.contentsOfDirectory(atPath: supportDir.path) {
                    process(file, supportDir)
                }
            } catch {
            }
        }
        
        // Process files on bundle the application support folder.
        if let p = serviceBundle.url(forResource: "defaults", withExtension: nil, subdirectory: "highlight") {
            do {
                for file in try FileManager.default.contentsOfDirectory(atPath: p.path) {
                    if let f = supportFolder?.appendingPathComponent("defaults/\(file)"), FileManager.default.fileExists(atPath: f.path) {
                        // Exists a custom file on the application support folder.
                        continue
                    }
                    process(file, p)
                }
            } catch {
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
        
        let updateDomains = { (key: String, value: AnyHashable?) in
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
        
        updateDomains(SettingsBase.Key.dumpPlain, isDumpPlainData)
        updateDomains(SettingsBase.Key.vcs, isVCS)
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
