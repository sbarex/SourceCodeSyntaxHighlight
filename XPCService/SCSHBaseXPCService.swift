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
    var highlight: String
    var env: [String: String]
    var theme: String
    var backgroundColor: String
    var inlineCSS: String?
    var inlineTheme: String?
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
    internal let log = {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook.xpc-service")
    }()
    
    static let XPCDomain: String = "org.sbarex.SourceCodeSyntaxHighlight"
    
    var settings: SCSHGlobalBaseSettings
    let rsrcEsc: String
    
    let settingsType = SCSHGlobalBaseSettings.self
    
    /// Return the folder for the application support files.
    var applicationSupportUrl: URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Syntax Highlight")
    }
    
    // MARK: - Initializer
    internal class func initSettings() -> SCSHGlobalBaseSettings {
        return  SCSHGlobalBaseSettings(defaultsDomain: XPCDomain)
    }
    
    override init() {
        let rsrcDirURL = Bundle.main.resourceURL!
        self.rsrcEsc = rsrcDirURL.path
        
        settings = type(of: self).initSettings()
        
        //  settings = SCSHGlobalBaseSettings(defaultsDomain: XPCDomain)
        
        super.init()
    }
    
    
    // MARK: - Highlight
    
    /// Get the path of the embedded highlight.
    /// - returns: The path and the environment of the embedded highlight.
    func getEmbeddedHighlight() -> (path: String, env: [String: String]) {
        if let path = Bundle.main.path(forResource: "highlight", ofType: nil, inDirectory: "highlight/bin"), let data_dir = Bundle.main.path(forResource: "share", ofType: nil, inDirectory: "highlight") {
            return (path: path, env: ["HIGHLIGHT_DATADIR": "\(data_dir)/"])
        } else {
            return (path: "false", env: [:])
        }
    }
    
    
    // MARK: - Colorize
    
    /// Get all settings need to call colorize.sh.
    func getColorizeArguments(url: URL, custom_settings: SCSHGlobalBaseSettings) throws -> ColorizeArguments {
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        
        var highlightPath = custom_settings.highlightProgramPath
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbeddedHighlight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        } else {
            env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        }
        
        guard highlightPath != "" else {
            throw SCSHError.missingHighlight
        }
        
        var hlArguments = try custom_settings.getHighlightArguments()
        if hlArguments.theme.hasPrefix("!") {
            // Custom theme.
            hlArguments.theme.remove(at: hlArguments.theme.startIndex)
            if let theme_url = self.getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent("\(hlArguments.theme).theme") {
                hlArguments.arguments.append("--config-file=\(theme_url.path)")
            }
        }
        
        var cssCode: String?
        if custom_settings.format == .html {
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
            if custom_settings.renderForExtension, let style = Bundle.main.path(forResource: "style", ofType: "css") {
                if !cssCode!.isEmpty {
                    cssCode! += "\n"
                }
                do {
                    cssCode! += try String(contentsOfFile: style)
                } catch {
                    cssCode! += "/* unable to append `\(style)` css file| */\n";
                }
            }
        }
        
        env.merge([
            "maxFileSize": "",
            "textEncoding": "UTF-8",
            "webkitTextEncoding": "UTF-8",
            
            // Debug
            "qlcc_debug": custom_settings.debug ? "1" : "",
        ]) { (_, new) in new }
        
        if let preprocessor = try? custom_settings.preprocessor?.trimmingCharacters(in: CharacterSet.whitespaces).tokenize_command_line() {
            env["preprocessorHL"] = preprocessor.joined(separator: "•")
        } else {
            env.removeValue(forKey: "preprocessorHL")
        }
        
        return ColorizeArguments(highlight: highlightPath, env: env, theme: hlArguments.theme, backgroundColor: hlArguments.backgroundColor, css: cssCode, inlineTheme: nil, arguments: hlArguments.arguments)
    }
    
    /// Colorize a source file.
    /// - parameters:
    ///   - url: File url to colorize.
    ///   - custom_settings: Settings for the rendering.
    internal func doColorize(url: URL, custom_settings: SCSHGlobalBaseSettings) throws -> (result: ShellTask.TaskResult, settings: [String: Any]) {
        os_log(OSLogType.debug, log: self.log, "colorizing %{public}@", url.path)
        
        var colorize = try getColorizeArguments(url: url, custom_settings: custom_settings)
        
        let directory = NSTemporaryDirectory()
        /// Temp file for the css style.
        var temporaryCSSFile: URL? = nil
        /// Temp file for the theme.
        var temporaryThemeFile: URL? = nil
        
        defer {
            if custom_settings.debug {
                let log = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log")
                
                // Log the custom theme.
                if let theme = colorize.inlineTheme {
                    try? "\n\n#######\n# Custom Theme:\n\(theme)\n\n#######".append(to: log)
                }
                // Log the custom style.
                if let css = colorize.inlineCSS {
                    try? "\n\n#######\n# Custom CSS:\n\(css)\n\n#######".append(to: log)
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
        
        if custom_settings.format == .html, let css = colorize.inlineCSS, !css.isEmpty {
            let fileName = NSUUID().uuidString + ".css"
            
            temporaryCSSFile = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
            do {
                try css.write(to: temporaryCSSFile!, atomically: false, encoding: .utf8)
                colorize.arguments.append("--style-infile=\(temporaryCSSFile!.path)")
            } catch {
                temporaryCSSFile = nil
            }
        }
        
        if let inline_theme = colorize.inlineTheme {
            // Use a temporary file for the theme.
            let fileName = NSUUID().uuidString + ".theme"
            
            temporaryThemeFile = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
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
            
            // Theme to use.
            "hlTheme": colorize.theme,
            
            "extraHLFlags": colorize.arguments.joined(separator: "•"),
        ]) { (_, new) in new }
        
        /// Command to execute.
        let cmd = "\(self.rsrcEsc)/colorize.sh".g_shell_quote() + " " + url.path.g_shell_quote() + " 0"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", colorize.env)
        
        let result = try ShellTask.runTask(script: cmd, env: colorize.env)
            
        if result.exitCode != 0 {
            os_log(OSLogType.error, log: self.log, "QLColorCode: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            
            let e = SCSHError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "QLColorCode: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).")
            
            throw e
        } else {
            let final_settings = SCSHGlobalBaseSettings(settings: custom_settings)
            final_settings.theme = colorize.theme
            final_settings.backgroundColor = colorize.backgroundColor
            
            if let css = colorize.inlineCSS {
                final_settings.css = css
            }
            
            if custom_settings.debug {
                if final_settings.format == .html {
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
}
