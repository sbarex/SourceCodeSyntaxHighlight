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


class SCSHXPCService: NSObject, SCSHXPCServiceProtocol {
    struct TaskResult {
        /// stdout data.
        let data: Data
        /// stderr data.
        let dataErr: Data
        /// Program exit code.
        let exitCode: Int
        
        init(output data: Data, error: Data, exitCode: Int) {
            self.data = data
            self.dataErr = error
            self.exitCode = exitCode
        }
        
        var isSuccess: Bool {
            return self.exitCode == 0
        }
        
        /// Convert stdout data to a string.
        func output(encoding: String.Encoding = String.Encoding.utf8) -> String? {
            return (String(data: data, encoding: String.Encoding.utf8) ?? "").trimmingCharacters(in: CharacterSet.newlines)
        }
        
        /// Convert stderr data to a string.
        func errorOutput(encoding: String.Encoding = String.Encoding.utf8) -> String? {
            return (String(data: dataErr, encoding: String.Encoding.utf8) ?? "").trimmingCharacters(in: CharacterSet.newlines)
        }
    }
    
    
    private let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.xpc-service")
    }()
    
    let XPCDomain = "org.sbarex.SourceCodeSyntaxHighlight"
    
    var settings: SCSHSettings
    let rsrcEsc: String
    
    override init() {
        let rsrcDirURL = Bundle.main.resourceURL!
        self.rsrcEsc = rsrcDirURL.path
        
        if let url = SCSHXPCService.preferencesUrl?.appendingPathComponent("org.sbarex.SourceCodeSyntaxHightlight.plist"), let url1 = SCSHXPCService.preferencesUrl?.appendingPathComponent(XPCDomain + ".plist"), FileManager.default.fileExists(atPath: url.path) && !FileManager.default.fileExists(atPath: url1.path) {
            // Rename old preferences to new name (typo fix).
            try? FileManager.default.moveItem(at: url, to: url1)
        }
        // Set up preferences
        self.settings = SCSHSettings(domain: XPCDomain)
        
        super.init()
        
        migrate(settings: &settings)
    }

    /// Migrate the stored settings to the current format.
    @discardableResult
    internal func migrate(settings: inout SCSHSettings) -> Bool {
        guard settings.isGlobal, settings.version < SCSHSettings.version else {
            return false
        }
        
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: settings.domain) ?? [:]
        
        // "commands-toolbar" is not yet used.
        defaultsDomain.removeValue(forKey: "commands-toolbar")
        
        // "theme-light-is16" and "theme-dark-is16" are replaced by "base16/" prefix on theme name.
        let migrateBase16 = { (settings: inout SCSHSettings, defaultsDomain: inout [String: Any]) -> Bool in
            var changed = false
            if let lightThemeIsBase16 = defaultsDomain["theme-light-is16"] as? Bool {
                if lightThemeIsBase16, let t = settings.lightTheme, !t.hasPrefix("base16") {
                    settings.lightTheme = "base16/\(t)"
                }
                defaultsDomain.removeValue(forKey: "theme-light-is16")
                changed = true
            }
            if let darkThemeIsBase16 = defaultsDomain["theme-dark-is16"] as? Bool {
                if darkThemeIsBase16, let t = settings.darkTheme, !t.hasPrefix("base16") {
                    settings.darkTheme = "base16/\(t)"
                }
                defaultsDomain.removeValue(forKey: "theme-dark-is16")
                changed = true
            }
            return changed
        }
        
        // Custom CSS are saved on external files.
        let migrateCSS = { (settings: inout SCSHSettings, defaultsDomain: inout [String: Any]) -> Bool in
            var changed = false
            if let customCSS = defaultsDomain["css"] as? String {
                if let success = try? self.setCustomStyle(customCSS, forUTI: settings.uti), success {
                    defaultsDomain.removeValue(forKey: "css")
                    changed = true
                }
            }
            return changed
        }
        
        _ = migrateBase16(&settings, &defaultsDomain)
        _ = migrateCSS(&settings, &defaultsDomain)
        
        if let custom_formats = defaultsDomain[SCSHSettings.Key.customizedUTISettings] as? [String: [String: Any]] {
            for (uti, _) in custom_formats {
                if var s = settings.getSettings(forUTI: uti) {
                    _ = migrateBase16(&s, &defaultsDomain)
                    _ = migrateCSS(&s, &defaultsDomain)
                }
            }
        }
        
        // Update settings version.
        settings.version = SCSHSettings.version
        defaultsDomain[SCSHSettings.Key.version] = SCSHSettings.version
        
        // Store the converted settings.
        defaults.setPersistentDomain(defaultsDomain, forName: settings.domain)
        defaults.synchronize()
        
        return true
    }
    
    /// Return the folder for the application support files.
    var applicationSupportUrl: URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Syntax Highlight")
    }
    
    /// Return the folder for the application support files.
    static var preferencesUrl: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Preferences")
    }
    
    /// Execute a shell task
    /// - parameters:
    ///   - script: Program to execute.
    ///   - env: Environment variables.
    private static func runTask(script: String, env: [String: String] = [:]) throws -> TaskResult {
        let task = Process()
        
        task.currentDirectoryPath = NSTemporaryDirectory()
        task.environment = env
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Let stderr go to the usual place
        let pipeErr = Pipe()
        task.standardError = pipeErr
        
        do {
            try task.run()
        } catch {
            throw SCSHError.shellError(cmd: script, exitCode: -1, stdOut: "", stdErr: "", message: error.localizedDescription)
        }
        
        let file = pipe.fileHandleForReading
        let fileErr = pipeErr.fileHandleForReading
        
        defer {
            if #available(OSX 10.15, *) {
                /* The docs claim this isn't needed, but we leak descriptors otherwise */
                try? file.close()
                try? fileErr.close()
            }
        }
        
        let data = file.readDataToEndOfFile()
        let dataErr = file.readDataToEndOfFile()
        
        task.waitUntilExit()
        
        let r = TaskResult(output: data, error: dataErr, exitCode: Int(task.terminationStatus))
        
        return r
    }
    
    /// Colorize a source file.
    /// - parameters:
    ///   - url: File url to colorize.
    ///   - format: Format output.
    ///   - custom_settings: Settings.
    private func colorize(url: URL, custom_settings: SCSHSettings) throws -> (result: TaskResult, settings: [String: Any]) {
        let directory = NSTemporaryDirectory()
        /// Temp file for the css style.
        var temporaryCSSFile: URL? = nil
        /// Temp file for the theme.
        var temporaryThemeFile: URL? = nil
        
        defer {
            if custom_settings.debug {
                let log = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log")
                
                // Log the custom theme.
                if let url = temporaryThemeFile, let s = try? String(contentsOf: url) {
                    try? "\n\n#######\n# Custom Theme:\n\(s)\n\n#######".append(to: log)
                }
                // Log the custom style.
                if let url = temporaryCSSFile, let s = try? String(contentsOf: url) {
                    try? "\n\n#######\n# Custom CSS:\n\(s)\n\n#######".append(to: log)
                }
            }
            
            if let url = temporaryCSSFile {
                do {
                    // Delete the temporary css.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
            if let url = temporaryThemeFile {
                do {
                    // Delete the temporary theme file.
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
        
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
            throw SCSHError.missingHighlight
        }
        
        // Extra arguments for _highlight_ spliced in single arguments.
        // Warning: all white spaces that are not arguments separators must be quote protected.
        let extra = custom_settings.extra?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        var extraHLFlags: [String] = extra.isEmpty ? [] : try extra.shell_parse_argv()
        
        env["pathHL"] = highlightPath
        
        let defaults = UserDefaults.standard
        
        /// Output format.
        let format = custom_settings.format ?? .html
        
        let target = url.path
        
        os_log(OSLogType.debug, log: self.log, "colorizing %{public}@", url.path)
        // os_log(OSLogType.debug, log: log, "target = %@", target)
        
        env.merge([
            "maxFileSize": "",
            "textEncoding": "UTF-8",
            "webkitTextEncoding": "UTF-8",
            
            // Debug
            "qlcc_debug": custom_settings.debug ? "1" : "",
        ]) { (_, new) in new }
        
        // if let e = defaults.persistentDomain(forName: XPCDomain) as? [String: String] {
        //     // Export all settings inside the defaults to the environment.
        //     env.merge(e) { (_, new) in new }
        // }
        let isOSThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        
        var theme = custom_settings.theme ?? (isOSThemeLight ? custom_settings.lightTheme : custom_settings.darkTheme)
        if (theme ?? "").hasPrefix("!") {
            // Custom theme.
            theme!.remove(at: theme!.startIndex)
            if let theme_url = self.getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent("\(theme!).theme") {
                extraHLFlags.append("--config-file=\(theme_url.path)")
            }
        }
        
        // Theme to use.
        env["hlTheme"] = theme
        
        if let inline_theme = custom_settings.inline_theme {
            // Use a temporary file for the theme.
            let fileName = NSUUID().uuidString + ".theme"
            
            temporaryThemeFile = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
            do {
                try inline_theme.save(to: temporaryThemeFile!)
                extraHLFlags.append("--config-file=\(temporaryThemeFile!.path)")
                theme = inline_theme.name
            } catch {
                temporaryThemeFile = nil
            }
        }
        
        // Show line numbers.
        if let lineNumbers = custom_settings.lineNumbers {
            switch lineNumbers {
            case .hidden:
                break
            case .visible(let omittingWrapLines):
                extraHLFlags.append("--line-numbers")
                if omittingWrapLines {
                    extraHLFlags.append("--wrap-no-numbers")
                }
            }
        }
        
        // Word wrap and line length.
        if let wordWrap = custom_settings.wordWrap, wordWrap != .off {
            if let lineLength = custom_settings.lineLength {
                extraHLFlags.append("--line-length=\(lineLength)")
            }
            extraHLFlags.append(custom_settings.wordWrap == .simple ? "-V" : "-W")
        }
        
        // Convert tab to spaces.
        if let space = custom_settings.tabSpaces, space > 0 {
            extraHLFlags.append("--replace-tabs=\(space)")
        }
        
        // Font family.
        if let font = custom_settings.fontFamily, !font.isEmpty {
            env["font"] = font
        }
        
        // Font size.
        if let fontSize = custom_settings.fontSize, fontSize > 0 {
            env["fontSizePoints"] = String(format: "%.2f", fontSize * (custom_settings.format == .html ? 0.75 : 1))
        }
        
        var cssCode: String?
        // Output format.
        extraHLFlags.append("--out-format=\(format.rawValue)")
        if custom_settings.format == .rtf {
            extraHLFlags.append("--page-color")
            extraHLFlags.append("--char-styles")
        } else {
            cssCode = ""
            if let css = custom_settings.css {
                // Passing a css value in the settings prevent the embed of styles saved on disk.
                cssCode! += "\(css)\n"
            } else {
                // Import global css style.
                if let css_url = getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("global.css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
                
                // Import per file css style.
                if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier, let css_url = getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("\(uti).css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
            }
            
            // Embed the custom standard style.
            if custom_settings.embedCustomStyle, let style = Bundle.main.path(forResource: "style", ofType: "css") {
                if !cssCode!.isEmpty {
                    cssCode! += "\n"
                }
                do {
                    cssCode! += try String(contentsOfFile: style)
                } catch {
                    cssCode! += "/* unable to append `\(style)` css file| */\n";
                }
            }
            
            if !cssCode!.isEmpty {
                let fileName = NSUUID().uuidString + ".css"
                
                temporaryCSSFile = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
                do {
                    try cssCode!.write(to: temporaryCSSFile!, atomically: false, encoding: .utf8)
                    extraHLFlags.append("--style-infile=\(temporaryCSSFile!.path)")
                } catch {
                    temporaryCSSFile = nil
                }
            }
        }
        
        env["extraHLFlags"] = extraHLFlags.joined(separator: "•")
        if let preprocessor = try? custom_settings.preprocessor?.trimmingCharacters(in: CharacterSet.whitespaces).tokenize_command_line() {
            env["preprocessorHL"] = preprocessor.joined(separator: "•")
        } else {
            env.removeValue(forKey: "preprocessorHL")
        }
        
        /// Command to execute.
        let cmd = "\(self.rsrcEsc)/colorize.sh".g_shell_quote() + " " + target.g_shell_quote() + " 0"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", env)
        
        let result = try SCSHXPCService.runTask(script: cmd, env: env)
            
        if result.exitCode != 0 {
            os_log(OSLogType.error, log: self.log, "QLColorCode: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            
            let e = SCSHError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "QLColorCode: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).")
            
            throw e
        } else {
            let final_settings = settings.overriding(fromDictionary: [
                SCSHSettings.Key.format: format,
            ])
            if let t = theme {
                final_settings.theme = t
            }
            if let style = cssCode {
                custom_settings.css = style
            }
            
            if format == .rtf {
                let bgLight = custom_settings.rtfLightBackgroundColor
                let bgDark = custom_settings.rtfDarkBackgroundColor
                let bg = custom_settings.rtfBackgroundColor ?? (isOSThemeLight ? bgLight : bgDark)
                final_settings.rtfBackgroundColor = bg
            }
            
            if custom_settings.debug {
                if format == .html {
                    let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.html")
                    try? result.output()?.write(to: u, atomically: true, encoding: .utf8)
                } else {
                   let u = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.rtf")
                    try? result.data.write(to: u)
               }
            }
            
            return (result: result, settings: final_settings.toDictionary())
        }
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters
    ///   - url: Url of source file to format.
    ///   - overrideSettings: list of settings that override the current preferences. Only elements defined inside the dict are overridden.
    func colorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: settings)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        colorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters
    ///   - url: Url of source file to format.
    ///   - settings: settings to use, is nil uses the current settings.
    func colorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let s = settings as? [String : Any] {
            custom_settings = SCSHSettings(dictionary: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: self.settings)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
            }
        }
        
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted html code.
    func htmlColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (String, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: settings)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        htmlColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    func htmlColorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (String, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let s = settings as? [String: Any] {
            custom_settings = SCSHSettings(dictionary: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: self.settings)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
            }
        }
        
        custom_settings.format = SCSHFormat.html
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.output() ?? "", result.settings as NSDictionary, nil)
        } catch {
            reply("<pre>" + error.localizedDescription + "</pre>", custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted rtf code.
    func rtfColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            custom_settings = settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: settings)
        } else {
            custom_settings = SCSHSettings(settings: settings)
        }
        custom_settings.override(fromDictionary: overrideSettings as? [String: Any])
        
        rtfColorize(url: url, settings: custom_settings.toDictionary() as NSDictionary, withReply: reply)
    }
    
    func rtfColorize(url: URL, settings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings: SCSHSettings
        
        if let s = settings as? [String: Any] {
            custom_settings = SCSHSettings(dictionary: s)
        } else {
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                custom_settings = self.settings.getGlobalSettingsForUti(uti) ?? SCSHSettings(settings: self.settings)
            } else {
                custom_settings = SCSHSettings(settings: self.settings)
            }
        }
        custom_settings.format = SCSHFormat.rtf
        
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    // MARK: - Themes
    
    /// Return the url of the folder of the custom themes.
    /// - parameters:
    ///   - create: If the folder don't exists try to create it.
    /// - returns: The url of the custom themes folder. If is requested to create if missing and the creations fail will be return nil.
    func getCustomThemesUrl(createIfMissing create: Bool = true) -> URL? {
        if let url = applicationSupportUrl?.appendingPathComponent("Themes") {
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
    
    /// Get the list of available themes.
    func getThemes(withReply reply: @escaping ([NSDictionary], Error?) -> Void) {
        self.getThemes(highlight: self.settings.highlightProgramPath, withReply: reply)
    }
    
    /// Get the list of available themes.
    /// - parameters:
    ///   - highlightPath: Path of highlight. If empty or - use the embed highlight.
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
        let result: TaskResult
        
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
            result = try SCSHXPCService.runTask(script: "\(highlight_executable.g_shell_quote()) --list-scripts=theme", env: env)
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
                            settings.synchronize()
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
                    settings.synchronize()
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
    
    /// Return the url of the folder of the custom CSS styles.
    /// - parameters:
    ///   - create: If the folder don't exists try to create it.
    /// - returns: The url of the custom styles folder. If is requested to create if missing and the creations fail will be return nil.
    func getCustomStylesUrl(createIfMissing create: Bool = true) -> URL? {
        if let url = applicationSupportUrl?.appendingPathComponent("Styles") {
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
    
    
    // MARK: -
    
    /// Get settings.
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void) {
        // Populate the custom css.
        if let stylesDir = getCustomStylesUrl(createIfMissing: false), let files = try? FileManager.default.contentsOfDirectory(at: stylesDir, includingPropertiesForKeys: nil, options: []) {
            for file in files {
                guard file.pathExtension == "css" else {
                    continue
                }
                
                if let style = try? String(contentsOf: file, encoding: .utf8) {
                    let uti = file.deletingPathExtension().lastPathComponent
                    if uti != "global" {
                        let s = settings.getSettings(forUTI: uti)
                        s?.css = style
                    } else {
                        settings.css = style
                    }
                }
            }
        }
        
        reply(self.settings.toDictionary() as NSDictionary)
    }
    
    /// Set and store the settings.
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void) {
        if let s = settings as? [String: Any] {
            self.settings.override(fromDictionary: s)
            reply(self.settings.synchronize())
            _ = try? setCustomStyle(self.settings.css ?? "", forUTI: "")
            for (uti, utiSettings) in self.settings.customizedSettings {
                _ = try? setCustomStyle(utiSettings.css ?? "", forUTI: uti)
            }
        } else {
            reply(false)
        }
    }
    
    /// Return the url of the application support folder that contains themes and custom css styles.
    func getApplicationSupport(reply: @escaping (_ url: URL?)->Void) {
        reply(applicationSupportUrl)
    }
    
    func getEmbeddedHighlight() -> (path: String, env: [String: String]) {
        if let path = Bundle.main.path(forResource: "highlight", ofType: nil, inDirectory: "highlight/bin"), let data_dir = Bundle.main.path(forResource: "share", ofType: nil, inDirectory: "highlight") {
            return (path: path, env: ["HIGHLIGHT_DATADIR": "\(data_dir)/"])
        } else {
            return (path: "false", env: [:])
        }
    }
    
    func locateHighlight(reply: @escaping ([[Any]]) -> Void) {
        let current = self.settings.highlightProgramPath
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        let parse_version = { (path: String, env: [String: String]) -> String? in
            guard let r = try? SCSHXPCService.runTask(script: "\(path.g_shell_quote()) --version", env: env), r.isSuccess, let output = r.output(), output.contains("Andre Simon"), let regex = try? NSRegularExpression(pattern: #"highlight version (\d\.\d+)"#, options: []) else {
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
        if let r = try? SCSHXPCService.runTask(script: "which -a highlight", env: env), r.isSuccess, let output = r.output() {
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
        
        if let result = try? SCSHXPCService.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=langs"
        if let result = try? SCSHXPCService.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=themes"
        if let result = try? SCSHXPCService.runTask(script: cmd, env: env), let s = result.output() {
            text += s + "\n\n"
        }
        
        cmd = "\(highlightPath.g_shell_quote()) --list-scripts=plugins"
        if let result = try? SCSHXPCService.runTask(script: cmd, env: env), let s = result.output()  {
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
        
        if let result = try? SCSHXPCService.runTask(script: cmd, env: env) {
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
            
            if let result = try? SCSHXPCService.runTask(script: cmd, env: env), result.exitCode == 0 {
                reply(true)
                return
            }
        }
        
        reply(false)
    }
    
    func getXPCPath(replay: @escaping (URL)->Void) {
        replay(Bundle.main.bundleURL)
    }
}
