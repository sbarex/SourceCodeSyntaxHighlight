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
import OSLog

struct ColorizeArguments {
    /// Path of the `highlight` executable.
    var highlight: String
    /// Env variables.
    var env: [String: String]
    /// Theme name.
    var theme: String
    /// Theme background color.
    var backgroundColor: String
    /// Custom CSS Style.
    var inlineCSS: String?
    /// Lua code of a custom theme.
    var inlineTheme: String?
    /// Arguments passed to the `highlight` executable.
    var arguments: [String]
    
    init(highlight: String, env: [String: String], theme: String, backgroundColor: String, css: String?, inlineTheme: String?, arguments: [String]) {
        self.highlight = highlight
        self.env = env
        self.theme = theme
        self.backgroundColor = backgroundColor
        self.inlineCSS = css
        self.inlineTheme = inlineTheme
        self.arguments = arguments
    }
}

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
    /// - returns: The path and the environment of the embedded highlight.
    func getEmbeddedHighlight() -> (path: String, env: [String: String]) {
        if let path = self.bundle.path(forResource: "highlight", ofType: nil, inDirectory: "highlight/bin"), let data_dir = self.dataDir {
            return (path: path, env: ["HIGHLIGHT_DATADIR": "\(data_dir)/"])
        } else {
            return (path: "false", env: [:])
        }
    }
    
    
    // MARK: - Colorize
    
    /// Get all settings need to call colorize.sh.
    func getColorizeArguments(url: URL, custom_settings: SettingsRendering) throws -> ColorizeArguments {
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        
        let p  = self.getEmbeddedHighlight()
        let highlightPath = p.path
        env.merge(p.env) { (_, new) in new }
        
        var hlArguments = try custom_settings.getHighlightArguments()
        if let dataDir = self.dataDir {
            hlArguments.arguments.append("--data-dir=\(dataDir)")
        }
        
        if hlArguments.theme.hasPrefix("!") {
            // Custom theme.
            hlArguments.theme.remove(at: hlArguments.theme.startIndex)
            if let theme_url = self.getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent(hlArguments.theme).appendingPathExtension("theme") {
                hlArguments.arguments.append("--config-file=\(theme_url.path)")
            }
        }
        
        var cssCode: String?
        if custom_settings.format == .html {
            cssCode = ""
            if custom_settings.isCSSDefined && !custom_settings.css.isEmpty {
                // Passing a css value in the settings prevent the embed of styles saved on disk.
                cssCode! += "\(custom_settings.css)\n"
            } else {
                // Import global css style.
                if let css_url = type(of: self).getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("global.css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
                
                // Import per file css style.
                if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier, let css_url = type(of: self).getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("\(uti).css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
            }
            
            // Embed the custom standard style.
            if let style = self.bundle.path(forResource: "style", ofType: "css", inDirectory: "highlight") {
                if !cssCode!.isEmpty {
                    cssCode! += "\n"
                }
                do {
                    cssCode! += try String(contentsOfFile: style)
                } catch {
                    cssCode! += "/* Error: unable to append `\(style)` CSS file! */\n";
                }
            }
        }
        
        let maxData: String
        if custom_settings.maxData > 0 {
            maxData = "\(custom_settings.maxData)"
        } else {
            maxData = ""
        }
        
        env.merge([
            "maxFileSizeHL": maxData,
            "textEncoding": "UTF-8",
            "webkitTextEncoding": "UTF-8",
            "convertEOL": custom_settings.convertEOL ? "1" : "",
            
            // Debug
            "debugHL": custom_settings.isDebug ? "1" : "",
        ]) { (_, new) in new }
        
        if let _ = env["preprocessorHL"] {
            env.removeValue(forKey: "convertEOL")
        }
        if custom_settings.isUsingLSP {
            env["useLSP"] = "1"
            env.removeValue(forKey: "maxFileSizeHL") // unsupported options for LSP
            env.removeValue(forKey: "preprocessorHL") // unsupported options for LSP
            env.removeValue(forKey: "convertEOL") // unsupported options for LSP
        } else {
            if custom_settings.isPreprocessorDefined, !custom_settings.preprocessor.isEmpty {
                env["preprocessorHL"] = custom_settings.preprocessor.trimmingCharacters(in: CharacterSet.whitespaces)
            } else {
                env.removeValue(forKey: "preprocessorHL")
            }
        }
        
        if custom_settings.isSyntaxDefined && !custom_settings.syntax.isEmpty {
            env["syntaxHL"] = custom_settings.syntax
        }
        
        return ColorizeArguments(highlight: highlightPath, env: env, theme: hlArguments.theme, backgroundColor: hlArguments.backgroundColor, css: cssCode, inlineTheme: custom_settings.themeLua, arguments: hlArguments.arguments)
    }
    
    /// Colorize a source file.
    /// - parameters:
    ///   - url: File url to colorize.
    ///   - custom_settings: Settings for the rendering.
    internal func doColorize(url: URL, custom_settings: SettingsRendering) throws -> (result: ShellTask.TaskResult, settings: [String: Any]) {
        os_log(OSLogType.debug, log: self.log, "colorizing %{public}@", url.path)
        
        var colorize = try getColorizeArguments(url: url, custom_settings: custom_settings)
        
        let directory = NSTemporaryDirectory()
        /// Temp file for the css style.
        var temporaryCSSFile: URL? = nil
        /// Temp file for the theme.
        var temporaryThemeFile: URL? = nil
        
        defer {
            if custom_settings.isDebug {
                let logFile = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log")
                
                // Log the custom theme.
                if let theme = colorize.inlineTheme, !theme.isEmpty {
                    try? "\n\n#######\n# Custom Theme:\n\(theme)\n\n#######".append(to: logFile)
                }
                // Log the custom style.
                if let css = colorize.inlineCSS {
                    try? "\n\n#######\n# Custom CSS:\n\(css)\n\n#######".append(to: logFile)
                }
            }
            
            if let url = temporaryCSSFile {
                do {
                    // Delete the temporary css.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    os_log(OSLogType.error, log: self.log, "Unable to delete the temporary CSS file %{public}@: %{public}@", url.path, error.localizedDescription)
                    print(error)
                }
            }
            if let url = temporaryThemeFile {
                do {
                    // Delete the temporary theme file.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    os_log(OSLogType.error, log: self.log, "Unable to delete the temporary theme file %{public}@: %{public}@", url.path, error.localizedDescription)
                    print(error)
                }
            }
        }
        
        if custom_settings.format == .html, let css = colorize.inlineCSS, !css.isEmpty {
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
                colorize.arguments.append("--config-file=\(temporaryThemeFile!.path)")
            } catch {
                temporaryThemeFile = nil
            }
        }
        
        
        colorize.env.merge([
            // Highlight path
            "pathHL": colorize.highlight,
            "pathDos2unix": self.bundle.path(forResource: "dos2unix", ofType: nil) ?? "dos2unix",
            
            // Theme to use.
            "themeHL": colorize.theme,
            
            "extraFlagsHL": colorize.arguments.joined(separator: "•"),
        ]) { (_, new) in new }
        
        /// Command to execute.
        let cmd = "\(self.rsrcEsc)/highlight/colorize.sh".g_shell_quote() + " " + url.path.g_shell_quote()
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", colorize.env)
        
        let result = try ShellTask.runTask(script: cmd, env: colorize.env)
            
        if result.exitCode != 0 {
            os_log(OSLogType.error, log: self.log, "QLColorCode: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            
            let e = SCSHError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "QLColorCode: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).")
            
            throw e
        } else {
            let final_settings = SettingsRendering(settings: custom_settings.toDictionary())
            final_settings.themeName = colorize.theme
            final_settings.backgroundColor = colorize.backgroundColor
            
            if let css = colorize.inlineCSS {
                final_settings.css = css
            }
            
            if custom_settings.isDebug {
                if final_settings.format == .html {
                    let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.html")
                    do {
                        try result.data.write(to: u)
                    } catch {
                        os_log(OSLogType.error, log: self.log, "Unable to create the log output file %{public}@: %{public}@", u.path, error.localizedDescription)
                        print("\(error)")
                    }
                } else {
                    let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.rtf")
                    do {
                        try result.data.write(to: u)
                    } catch {
                        os_log(OSLogType.error, log: self.log, "Unable to create the log output file %{public}@: %{public}@", u.path, error.localizedDescription)
                        print("\(error)")
                    }
               }
            }
            
            return (result: result, settings: final_settings.toDictionary())
        }
    }
    
    // MARK: - Themes
    
    /// Return the url of the folder of the custom themes.
    /// - parameters:
    ///   - create: If the folder don't exists try to create it.
    /// - returns: The url of the custom themes folder. If is requested to create if missing and the creations fail will be return nil.
    func getCustomThemesUrl(createIfMissing create: Bool = true) -> URL? {
        if let url = type(of: self).applicationSupportUrl?.appendingPathComponent("Themes") {
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
}
