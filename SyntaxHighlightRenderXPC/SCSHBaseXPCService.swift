//
//  SCSHBaseXPCService.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 28/11/2019.
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
import Cocoa
import OSLog

@objc
class SCSHBaseXPCService: NSObject {
    // MARK: - Class properties
    
    static let XPCDomain: String = "org.sbarex.SourceCodeSyntaxHighlight"
    
    static let serviceBundle: Bundle = {
        if Bundle.main.bundlePath.hasSuffix(".xpc") || Bundle.main.bundlePath.hasSuffix(".appex") {
            // This is an xpc/appex extension.
            var url = Bundle.main.bundleURL
            while url.pathExtension != "app" {
                let u = url.path
                url.deleteLastPathComponent()
                if u == url.path {
                    return Bundle.main
                }
            }
            url.appendPathComponent("Contents")
            
            if let appBundle = Bundle(url: url) {
                return appBundle
            }
        }
        return Bundle.main
    }()
    
    /// Return the folder for the application support files.
    class var applicationSupportUrl: URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Syntax Highlight")
    }
    
    // MARK: - Class methods
    /*
    internal class func populateSpecialSettings(_ settings: Settings) {
        for (uti, uti_settings) in settings.utiSettings {
            let baseSettings: String
            if let file = applicationSupportUrl?.appendingPathComponent("defaults/\(uti).plist"), FileManager.default.fileExists(atPath: file.path) {
                // Customized file inside the application support folder.
                baseSettings = file.path
            } else if let file = self.serviceBundle.path(forResource: uti, ofType: "plist", inDirectory: "highlight/defaults") {
                // Customized file inside the application resources folder.
                baseSettings = file
            } else {
                baseSettings = ""
            }
            if !baseSettings.isEmpty, let plistXML = FileManager.default.contents(atPath: baseSettings) {
                do {
                    // Customize the base global settings with the special values inside the plist.
                    if let plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainers, format: nil) as? [String: String] {
                    
                        uti_settings.specialSyntax = plistData[SettingsBase.Key.syntax]
                        uti_settings.specialPreprocessor = plistData[SettingsBase.Key.preprocessor]
                        uti_settings.specialAppendArguments = plistData[SettingsBase.Key.appendedExtraArguments]
                    }
                } catch {
                    print("Error reading plist \(baseSettings): \(error)")
                }
            }
        }
        
        let process = { (file: String, p: URL) in
            let url = URL(fileURLWithPath: file, relativeTo: p)
            guard url.pathExtension == "plist" else {
                return
            }
            let name = url.deletingPathExtension().lastPathComponent
            guard !settings.hasCustomizedSettings(forUTI: name) else {
                return
            }
            
            if let plistXML = FileManager.default.contents(atPath: url.path) {
                do {
                    // Customize the base global settings with the special values inside the plist.
                    guard let plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainers, format: nil) as? [String:String] else {
                        return
                    }
                    let uti_settings = settings.createSettings(forUTI: name)
                    uti_settings.specialSyntax = plistData[SettingsBase.Key.syntax]
                    uti_settings.specialPreprocessor = plistData[SettingsBase.Key.preprocessor]
                    uti_settings.specialAppendArguments = plistData[SettingsBase.Key.appendedExtraArguments]
                } catch {
                    print("Error reading plist \(file): \(error)")
                }
            }
        }
        
        var d: ObjCBool = false
        if let p = applicationSupportUrl?.appendingPathComponent("defaults"), FileManager.default.fileExists(atPath: p.path, isDirectory: &d), d.boolValue {
            do {
                for file in try FileManager.default.contentsOfDirectory(atPath: p.path) {
                    process(file, p)
                }
            } catch {
            }
        }
        
        if let p = self.serviceBundle.url(forResource: "defaults", withExtension: nil, subdirectory: "highlight") {
            do {
                for file in try FileManager.default.contentsOfDirectory(atPath: p.path) {
                    if let f = applicationSupportUrl?.appendingPathComponent("defaults/\(file)"), FileManager.default.fileExists(atPath: f.path) {
                        // Exists a custom file on the application support folder.
                        continue
                    }
                    process(file, p)
                }
            } catch {
            }
        }
    }
    */
    
    internal class func initSettings() -> Settings {
        let settings = Settings(defaultsDomain: XPCDomain)
        
        if let dir = self.getCustomStylesUrl(createIfMissing: false) {
            settings.populateCSS(cssFolder: dir)
        }
        
        return settings
    }
    
    // MARK: - Instance properties
    
    /// Get the Bundle with the resources.
    /// For the host app return the main Bundle. For the xpc/appex return the bundle of the hosting app.
    lazy var bundle: Bundle = {
        return type(of: self).serviceBundle
    }()
    
    internal let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.xpc-service")
    }()
    
    var settings: Settings
    
    lazy fileprivate(set) var rsrcEsc: String = {
        return self.bundle.resourceURL!.path
    }()
    
    lazy var dataDir: String? = {
        return self.bundle.path(forResource: "share", ofType: nil, inDirectory: "highlight")
    }()
    
    // MARK: - Init
    
    override init() {
        settings = type(of: self).initSettings()
        super.init()
    }
    
    
    // MARK: - Highlight
    
    /// Get the path of the embedded highlight.
    /// - returns: The path of the embedded highlight.
    func getEmbeddedHighlight() -> String {
        if let path = self.bundle.path(forResource: "highlight", ofType: nil, inDirectory: "highlight/bin") {
            return path
        } else {
            return ""
        }
    }
    
    
    // MARK: - Colorize
    /// Get the global CSS file.
    func getGlobalCSS() -> URL? {
        if #available(macOS 12.0, *) {
            return self.bundle.url(forResource: "style2", withExtension: "css", subdirectory: "highlight")
        } else {
            return self.bundle.url(forResource: "style", withExtension: "css", subdirectory: "highlight")
        }
    }
    
    /// Get all settings need to call colorize.sh.
    func getColorizeArguments(url: URL, custom_settings: SettingsRendering) throws -> ColorizeArguments {
        let colorize = try (type(of: self)).getColorizeArguments(url: url, custom_settings: custom_settings, highlightBin: self.getEmbeddedHighlight(), dataDir: self.dataDir, extraCss: self.getGlobalCSS())
        
        return colorize
    }
    
    class func getColorizeArguments(url: URL, custom_settings: SettingsRendering, highlightBin: String, dataDir: String?, extraCss: URL?) throws -> ColorizeArguments {
        let colorize = try ColorizeArguments(highlight: highlightBin, dataDir: dataDir, url: url, custom_settings: custom_settings, extraCss: extraCss)
        
        return colorize
    }
    
    /// Check if a file has only one line.
    class func checkOneLineFile(_ url: URL) -> Bool {
        guard let f = fopen(url.path, "r") else {
            return false
        }
        defer {
            fclose(f)
        }
        // the smallest multiple of 16 that will fit the byte array for this line
        var lineCap: Int = 0
        
        // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        defer {
            if lineByteArrayPointer != nil {
                free(lineByteArrayPointer!)
            }
        }
        
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, f)
        var lines = 0
        while (bytesRead > 0) {
            bytesRead = getline(&lineByteArrayPointer, &lineCap, f)
            lines += 1
            if lines > 1 {
                break
            }
        }
        
        return lines == 1
    }
    
    /// Colorize a source file.
    /// - parameters:
    ///   - url: File url to colorize.
    ///   - custom_settings: Settings for the rendering.
    ///   - colorize: ColorizeArguments.
    ///   - rsrcEsc: Path for the resources folder that contain the highlight dir.
    ///   - dos2unix: Path of the dos2unix binary.
    ///   - logOs: OSLog.
    class func doColorize(url: URL, custom_settings: SettingsRendering, colorize: inout ColorizeArguments, rsrcEsc: String, dos2unix: String?, logOs: OSLog?) throws -> (result: ShellTask.TaskResult, settings: SettingsRendering) {
        if let logOs = logOs {
            os_log(.debug, log: logOs, "colorizing %{public}@", url.path)
        }
        try? "Start colorizing \(url.path) …".appendLine(to: custom_settings.logFile)
                
        let directory = NSTemporaryDirectory()
        /// Temp file for the css style.
        var temporaryCSSFile: URL? = nil
        /// Temp file for the theme.
        var temporaryThemeFile: URL? = nil
        
        defer {
            if let logFile = custom_settings.logFile {
                var log = "";
                // Log the custom theme.
                if let theme = colorize.inlineTheme, !theme.isEmpty {
                    log += "\n\n#######\n# Custom Theme:\n\(theme)\n\n#######"
                }
                // Log the custom style.
                if let css = colorize.inlineCSS {
                    log += "\n\n#######\n# Custom CSS:\n\(css)\n\n#######"
                }
                
                log += "\n\n#######\n# ENV:\n"
                for (k, v) in colorize.env {
                    log += "\(k)=\(v)\n"
                }
                log += "\n\n####### ENV end\n"
                
                try? log.appendLine(to: logFile)
            }
            
            if let url = temporaryCSSFile {
                do {
                    // Delete the temporary css.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    if let logOs = logOs {
                        os_log(.error, log: logOs, "Unable to delete the temporary CSS file %{public}@: %{public}@", url.path, error.localizedDescription)
                    }
                    try? "ERROR: unable to delete the temporary CSS file \(url.path): \(error.localizedDescription)".appendLine(to: custom_settings.logFile)
                    // print(error)
                }
            }
            if let url = temporaryThemeFile {
                do {
                    // Delete the temporary theme file.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    if let logOs = logOs {
                        os_log(.error, log: logOs, "Unable to delete the temporary theme file %{public}@: %{public}@", url.path, error.localizedDescription)
                    }
                    try? "ERROR: unable to delete the temporary theme file \(url.path): \(error.localizedDescription)".appendLine(to: custom_settings.logFile)
                    // print(error)
                }
            }
        }
        
        var css = colorize.inlineCSS ?? ""
        if custom_settings.isWordWrapped && custom_settings.isWordWrappedSoft {
            css += "pre.hl { white-space: pre-wrap }"
        }
        
        if custom_settings.format == .html, !css.isEmpty {
            temporaryCSSFile = URL(fileURLWithPath: directory).appendingPathComponent(NSUUID().uuidString).appendingPathExtension("css")
            do {
                try css.write(to: temporaryCSSFile!, atomically: false, encoding: .utf8)
                colorize.arguments.append("--style-infile=\(temporaryCSSFile!.path)")
            } catch {
                temporaryCSSFile = nil
            }
        }
        
        if let inline_theme = colorize.inlineTheme, !inline_theme.isEmpty {
            // Use a temporary file for the theme.
            temporaryThemeFile = URL(fileURLWithPath: directory).appendingPathComponent(NSUUID().uuidString).appendingPathExtension("theme")
            do {
                try inline_theme.write(to: temporaryThemeFile!, atomically: true, encoding: .utf8)
                colorize.arguments.append("--style=\(temporaryThemeFile!.path)")
            } catch {
                temporaryThemeFile = nil
            }
        }
        
        colorize.env.merge([
            // Highlight path
            "pathHL": colorize.highlight,
            "pathDos2unix": dos2unix ?? "dos2unix",
            
            "extraFlagsHL": colorize.arguments.joined(separator: "•"),
        ]) { (_, new) in new }
        
        /// Command to execute.
        let cmd = "\(rsrcEsc)/highlight/colorize.sh".g_shell_quote() + " " + url.path.g_shell_quote()
        
        try? "Executing \(cmd)".appendLine(to: custom_settings.logFile)
        
        if let logOs = logOs {
            os_log(.debug, log: logOs, "cmd = %{public}@", cmd)
            os_log(.debug, log: logOs, "env = %@", colorize.env)
        }
        
        let result = try ShellTask.runTask(script: cmd, env: colorize.env)
            
        if result.exitCode != 0 {
            if let logOs = logOs {
                os_log(.error, log: logOs, "Syntax Highlight: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            }
            try? "ERROR: colorize.sh failed with exit code \(result.exitCode): \(result.errorOutput() ?? "")".appendLine(to: custom_settings.logFile)
            
            let e = SCSHError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "Syntax Highlight: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).\n\(result.errorOutput() ?? "")\n\(result.output() ?? "")")
            
            throw e
        } else {
            let final_settings = SettingsRendering(settings: custom_settings.toDictionary())
            final_settings.themeName = colorize.theme
            final_settings.backgroundColor = colorize.backgroundColor
            
            if let css = colorize.inlineCSS {
                final_settings.css = css
            }
            
            if custom_settings.isDebug {
                let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize").appendingPathExtension(final_settings.format == .html ? "html" : "rtf")
                do {
                    try result.data.write(to: u)
                } catch {
                    if let logOs = logOs {
                        os_log(.error, log: logOs, "Unable to create the log output file %{public}@: %{public}@", u.path, error.localizedDescription)
                    }
                    try? "ERROR: unable to create the log output file \(u.path): \(error.localizedDescription)".appendLine(to: custom_settings.logFile)
                }
            }
            
            final_settings.isLight = final_settings.isOSThemeLight()
            
            return (result: result, settings: final_settings)
        }
    }
    
    /// Highlight a file
    /// - parameters:
    ///   - url: File to highlight.
    ///   - settings: Base settings.
    ///   - highlightBin: Path of highlight executable.
    ///   - dataDir: Data dir for highlight resources.
    ///   - rsrcEsc: Path for the resources folder that contain the highlight dir.
    ///   - dos2unix: Path of the dos2unix binary.
    ///   - highlightLanguages:
    ///   - extraCss: Url of extra style sheet to embed in the output.
    ///   - logFile: File to save the log.
    ///   - logOs: OSLog.
    class func colorize(url: URL, settings: Settings, highlightBin: String, dataDir: String?, rsrcEsc: String, dos2unixBin: String?, highlightLanguages: [String: [String]], extraCss: URL?, overridingSettings: [String: AnyHashable]?, logFile: URL?, logOs: OSLog?) throws -> (data: Data, settings: SettingsRendering) {
        
        try? "Start processing \(url.path) …".appendLine(to: logFile)
        
        let custom_settings: SettingsRendering
        
        var uti = settings.searchUTI(for: url)
        var plain: PlainSettings?
        let attributes: MagicAttributes?
        if uti == nil {
            try? "No settings found for the file UTI".appendLine(to: logFile)
            attributes = MagicAttributes(url: url, logFile: logFile)
            plain = settings.searchPlainSettings(for: url)
            if !(plain?.UTI.isEmpty ?? true) {
                uti = plain!.UTI
            }
        
            if uti=="auto" || uti == nil, let attributes = attributes, let utiType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, attributes.mimeType as CFString, nil)?.takeRetainedValue() {
                // Set the uti from the recognized mime.
                uti = utiType as String
            }
            var syntax = "auto"
            if plain == nil || plain?.syntax == "auto", let u = uti {
                // Set the syntax from the extension associated to the UTI.
                let uu = UTI(u)
                let languages = highlightLanguages
                var langs: [(langs: [String], weight: Int)] = []
                // Assign a weight to all compatible languages
                for l in languages {
                    guard !l.value.isEmpty else {
                        continue
                    }
                    var weight = 0
                    if let index = uu.extensions.firstIndex(of: l.value.first!) {
                        weight = index == 0 ? 1000 : 1000 - index * 10
                    } else {
                        for e in uu.extensions {
                            if let index = l.value.firstIndex(of: e) {
                                weight = max(weight, index == 0 ? 100 : 100 - index * 10)
                            }
                        }
                    }
                    guard weight > 0 else {
                        continue
                    }
                    langs.append((langs: l.value, weight: weight))
                }
                langs.sort(by: { $0.weight < $1.weight })
                syntax = langs.first?.langs.first ?? "txt"
                
                if syntax == "" {
                    syntax = "txt"
                }
            }
            
            if plain == nil {
                plain = PlainSettings(pattern: ".*", isRegExp: true, isCaseInsensitive: false, UTI: "public.data", syntax: syntax)
            }
        } else {
            plain = nil
            attributes = nil
        }
        
        if let uti = uti {
            try? "Detected UTI: \(uti)".appendLine(to: logFile)
            let utiSettings = settings.utiSettings[uti] ?? settings.createSettings(forUTI: uti)
            
            if !utiSettings.isSpecialSettingsPopulated {
                utiSettings.populateSpecialSettings(supportFolder: self.applicationSupportUrl, serviceBundle: self.serviceBundle)
            }
            if !utiSettings.isCSSPopulated, let dir = self.getCustomStylesUrl(createIfMissing: false) {
                utiSettings.populateCSS(fromFolder: dir)
            }
            
            custom_settings = SettingsRendering(globalSettings: settings, format: utiSettings)
        } else {
            custom_settings = SettingsRendering(globalSettings: settings, format: nil)
        }
        
        custom_settings.logFile = logFile
        
        if let overridingSettings = overridingSettings, !overridingSettings.isEmpty {
            custom_settings.override(fromDictionary: overridingSettings)
        }
        
        if plain != nil {
            try? "File recognized as plain data.".appendLine(to: custom_settings.logFile)
            var st = stat()
            stat(url.path, &st)
            guard st.st_size > 0 else {
                try? "\tThe file is empty.".appendLine(to: custom_settings.logFile)
                let data = "Syntax Highlight: the file is empty.".toData(settings: custom_settings, cssFile: extraCss)
                return (data: data, settings: custom_settings)
            }
            
            if !plain!.syntax.isEmpty {
                custom_settings.isSyntaxDefined = true
                custom_settings.syntax = plain!.syntax
                try? "\tAdopted syntax: \(custom_settings.syntax)".appendLine(to: logFile)
            }
            
            guard let attributes = attributes else {
                custom_settings.isError = true
                let data = "Syntax Highlight: could not determine the file attributes.".toData(settings: custom_settings, cssFile: extraCss)
                return (data: data, settings: custom_settings)
            }
            
            if #available(macOS 12.0, *) {
                custom_settings.isPDF = attributes.isPDF
                if attributes.isPDF {
                    try? "\tFile is handled as PDF (\(attributes.mimeType)).".appendLine(to: custom_settings.logFile)
                }
                custom_settings.isMovie = attributes.isMovie
                if attributes.isMovie {
                    try? "\tFile is handled as movie (\(attributes.mimeType)).".appendLine(to: custom_settings.logFile)
                }
                custom_settings.isAudio = attributes.isAudio
                if attributes.isAudio {
                    try? "\tFile is handled as audio (\(attributes.mimeType)).".appendLine(to: custom_settings.logFile)
                }
            }
            
            guard !attributes.isImage else {
                if #available(macOS 12.0, *) {
                    try? "\tFile is handled as image (\(attributes.mimeType)).".appendLine(to: custom_settings.logFile)
                    let img_type = attributes.mimeType.dropFirst("image/".count)
                    if (["jpeg", "gif", "png", "heif", "heic"].contains(img_type)) {
                        custom_settings.isImage = true
                    }
                }
                custom_settings.format = .html
                do {
                    let fileData = try Data.init(contentsOf: url)
                    let fileStream = fileData.base64EncodedString()
                    
                        custom_settings.isCSSDefined = true
                    custom_settings.css += """
img {
    max-width: 100%;
    max-height: 100%;
    width: auto;
    height: auto;
}
"""
                    let s = "<img src='data:\(attributes.mimeType);base64,\(fileStream)' />".toHTML(settings: custom_settings, cssFile: extraCss)
                    let data = s.data(using: .utf8);
                    return (data: data!, settings: custom_settings)
                } catch {
                    try? "ERROR: unable to read the file.".appendLine(to: custom_settings.logFile)
                    custom_settings.isError = true
                    return (data: "Syntax Highlight: unable to read the file.".toData(settings: custom_settings, cssFile: extraCss), settings: custom_settings)
                }
            }
            
            guard attributes.isTextual else {
                var s = ""
                if custom_settings.isDumpPlainData {
                    let command: String
                    if custom_settings.maxData > 0 {
                        command = "/usr/bin/head -c \(custom_settings.maxData) '\(url.path)' | /usr/bin/xxd"
                    } else {
                        command = "/usr/bin/xxd '\(url.path)'"
                    }
                    try? "Dumping hex data… \n\t\(command)".appendLine(to: custom_settings.logFile)
                    do {
                        let r = try ShellTask.runTask(script: command)
                        if r.isSuccess, let o = r.output() {
                            s = attributes.mimeType + "\n\n" + (custom_settings.format == .rtf ? o :  o.htmlEntitites())
                            custom_settings.isWordWrappedHard = true
                            custom_settings.isWordWrapDefined = true
                        } else {
                            s = "ERROR: unable to dump the file. \n\(r.errorOutput() ?? "")"
                            try? s.appendLine(to: custom_settings.logFile)
                            s = "Syntax Highlight: \(s)"
                            custom_settings.isError = true
                        }
                    } catch {
                        s = "ERROR: unable to dump the file."
                        try? s.appendLine(to: custom_settings.logFile)
                        s = "Syntax Highlight: \(s)"
                        custom_settings.isError = true
                    }
                } else {
                    try? "WARNING: could not process a binary file (\(attributes.mimeType))".appendLine(to: custom_settings.logFile)
                    s = "Syntax Highlight: could not process a binary file (\(attributes.mimeType))."
                    custom_settings.isError = true
                    custom_settings.isRenderingSupported = false
                }
                
                let data = s.toData(settings: custom_settings, cssFile: extraCss)
                if custom_settings.isDebug {
                    let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize").appendingPathExtension(custom_settings.format == .html ? "html" : "rtf")
                    do {
                        try data.write(to: u)
                    } catch {
                        if let logOs = logOs {
                            os_log(.error, log: logOs, "Unable to create the log output file %{public}@: %{public}@", u.path, error.localizedDescription)
                        }
                        try? "ERROR: unable to create the log output file \(u.path): \(error.localizedDescription)".appendLine(to: custom_settings.logFile)
                    }
                }
                return (data: data, settings: custom_settings)
            }
            
            guard attributes.fileEncoding != kCFStringEncodingInvalidId else {
                try? "ERROR: could not determine encoding of the file.".appendLine(to: custom_settings.logFile)
                custom_settings.isError = true
                let data = "Syntax Highlight: could not determine encoding of the file.".toData(settings: custom_settings, cssFile: extraCss)
                return (data: data, settings: custom_settings)
            }
        } else if custom_settings.isVCS, let diff = self.getVCSDiff(url: url, settings: custom_settings) {
            custom_settings.vcsDiff = diff
            // print(diff)
        }
        
        do {
            let isImage: Bool
            if #available(macOS 12.0, *) {
                isImage = custom_settings.isImage
            } else {
                isImage = false
            }
            let isPDF: Bool
            if #available(macOS 12.0, *) {
                isPDF = custom_settings.isPDF
            } else {
                isPDF = false
            }
            
            if !isImage && !isPDF && (!custom_settings.isWordWrapped || !custom_settings.isWordWrappedSoft) && custom_settings.isWordWrappedSoftForOneLineFiles && self.checkOneLineFile(url) {
                custom_settings.isOneLineFileDetected = true
                custom_settings.isWordWrapped = true
                custom_settings.isWordWrappedHard = false
                custom_settings.isWordWrapDefined = true
            }
            
            var colorize = try self.getColorizeArguments(url: url, custom_settings: custom_settings, highlightBin: highlightBin, dataDir: dataDir, extraCss: extraCss)
            
            let result = try self.doColorize(url: url, custom_settings: custom_settings, colorize: &colorize, rsrcEsc: rsrcEsc, dos2unix: dos2unixBin, logOs: logOs)
            return (data: result.result.data, settings: result.settings)
        } catch {
            throw error
            // return (data: error.localizedDescription.data(using: String.Encoding.utf8)!, settings: custom_settings)
        }
    }
    
    // MARK: - Themes
    
    /// Return the url of the folder of the custom themes.
    /// - parameters:
    ///   - create: If the folder don't exists try to create it.
    /// - returns: The url of the custom themes folder. If is requested to create if missing and the creations fail will be return nil.
    class func getCustomThemesUrl(createIfMissing create: Bool = true) -> URL? {
        if let url = self.applicationSupportUrl?.appendingPathComponent("Themes") {
            if create && !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    return nil
                }
            }
            return url
        } else {
            return nil
        }
    }
    
    // MARK: - Custom styles
    
    /// Return the url of the folder of the custom CSS styles.
    /// - parameters:
    ///   - create: If the folder don't exists try to create it.
    /// - returns: The url of the custom styles folder. If is requested to create if missing and the creations fail will be return nil.
    class func getCustomStylesUrl(createIfMissing create: Bool = true) -> URL? {
        if let url = self.applicationSupportUrl?.appendingPathComponent("Styles") {
            if create && !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    return nil
                }
            }
            return url
        } else {
            return nil
        }
    }
    
    internal static func parseUnifiedDiff(_ text: String) -> [String] {
        var chunks: [String] = []
        for line in text.split(separator: "\n") {
            guard line.hasPrefix("@@ ") else {
                continue
            }
            var s = line.suffix(from: line.index(line.startIndex, offsetBy: 3))
            guard let idx = s.firstIndex(of: "@") else {
                continue
            }
            s = s.prefix(upTo: idx)
            // print(s)
            chunks.append(String(s).trimmingCharacters(in: .whitespaces))
        }
        return chunks
    }

    static func getGitDiff(url: URL, git: String) -> [String]? {
        guard !git.isEmpty else {
            return nil
        }
        do {
            let result = try ShellTask.runTask(command: git, arguments: ["diff", "-U0", "-0", url.path], cwd: url.deletingLastPathComponent().path)
            
            guard result.exitCode == 0, let stringOutput = result.output() else {
                return nil
            }
            let chunks = parseUnifiedDiff(stringOutput)
            return chunks
        } catch {
            // let e = error
            // print(e)
            return nil
        }
    }

    static func getHgDiff(url: URL, hg: String) -> [String]? {
        guard !hg.isEmpty else {
            return nil
        }
        do {
            let result = try ShellTask.runTask(command: hg, arguments: ["diff", "-U0", url.path], cwd: url.deletingLastPathComponent().path)
            
            guard result.exitCode == 0, let stringOutput = result.output() else {
                return nil
            }
            let chunks = parseUnifiedDiff(stringOutput)
            return chunks
        } catch {
            // let e = error
            // print(e)
            return nil
        }
    }

    static func getSVNDiff(url: URL, svn: String) -> [String]? {
        guard !svn.isEmpty else {
            return nil
        }
        return nil
        // TODO: implement support for SVN diff
    }

    static func getVCSDiff(url: URL, settings: Settings) -> [String]? {
        if let diff = getGitDiff(url: url, git: settings.gitPath) {
            return diff
        } else if let diff = getHgDiff(url: url, hg: settings.hgPath) {
            return diff
        } else if let diff = getSVNDiff(url: url, svn: settings.svnPath) {
            return diff
        } else {
            return nil
        }
    }
    
    static func parseHighlightLanguages(file: URL) throws -> [String: [String]] {
        let data = try Data(contentsOf: file)
        
        let json = JSONDecoder()
        let languages = try json.decode([String: [String]].self, from: data)
        
        return languages
    }
    
    static func initLog(forSettings settings: Settings) -> URL {
        let logFile = settings.isDebug ? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log") : URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("colorize.log")
        
        // Reset the log file.
        try? "".write(to: logFile, atomically: true, encoding: .utf8)
        return logFile
    }
    
    static func doneLog(_ logFile: URL, forSettings settings: Settings) {
        if !settings.isDebug {
            // Remove the temporary log file.
            try? FileManager.default.removeItem(at: logFile)
        }
    }
}
