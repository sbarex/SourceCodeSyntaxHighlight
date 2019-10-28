//
//  SCSHXPCService.swift
//  SCSHXPCService
//
//  Created by sbarex on 15/10/2019.
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
    
    let XPCDomain = "org.sbarex.SourceCodeSyntaxHightlight"
    
    var settings: SCSHSettings
    let rsrcEsc: String
    
    override init() {
        let rsrcDirURL = Bundle.main.resourceURL!
        self.rsrcEsc = rsrcDirURL.path
        
        // Set up preferences
        self.settings = SCSHSettings(domain: XPCDomain)
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
    
    /// Colorize a source file
    /// - parameters:
    ///   - url: File url to colorize.
    ///   - format: Format output.
    ///   - overrideSettings: Settings thar override standard preferences.
    private func colorize(url: URL, custom_settings: SCSHSettings) throws -> (result: TaskResult, settings: [String: Any])
    {
        // Set environment variables.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        
        var highlightPath = custom_settings.highlightProgramPath
        if highlightPath == "" || highlightPath == "-" {
            let p  = self.getEmbededHiglight()
            highlightPath = p.path
            env.merge(p.env) { (_, new) in new }
        }
        
        guard highlightPath != "" else {
            throw SCSHError.missingHighlight
        }
        
        env["pathHL"] = highlightPath
        
        let defaults = UserDefaults.standard
        
        /// Output format.
        let format = custom_settings.format.rawValue
        
        let targetEsc = url.path
        
        os_log(OSLogType.debug, log: self.log, "colorizing %{public}@", url.path)
        // os_log(OSLogType.debug, log: log, "target = %@", targetEsc)
        
        env.merge([
            // "qlcc_debug": "1",
            "maxFileSize": "",
            "textEncoding": "UTF-8",
            "webkitTextEncoding": "UTF-8"
        ]) { (_, new) in new }
        
        if let e = defaults.persistentDomain(forName: XPCDomain) as? [String: String] {
            // Export al settings inside the defaults to the environment.
            env.merge(e) { (_, new) in new }
        }
        let isOSThemeLight = (defaults.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light"
        let theme = custom_settings.theme ?? (isOSThemeLight ? custom_settings.lightTheme : custom_settings.darkTheme)
        // Theme to use.
        env["hlTheme"] = theme
        
        // Extra arguments for _highlight_.
        env["extraHLFlags"] = custom_settings.extra
        
        // Show line numbers.
        switch custom_settings.lineNumbers {
        case .hidden:
            break
        case .visible(let omittingWrapLines):
            env["extraHLFlags"]! += " --line-numbers"
            if omittingWrapLines {
                env["extraHLFlags"]! += " --wrap-no-numbers"
            }
        }
        
        // Word wrap and line length.
        if custom_settings.wordWrap != .off {
            env["extraHLFlags"]! += " --line-length=\(custom_settings.lineLength)"
            env["extraHLFlags"]! += custom_settings.wordWrap == .simple ? " -V" : " -W"
        }
        
        // Convert tab to spaces.
        let space = custom_settings.tabSpaces
        if space > 0 {
            env["extraHLFlags"]! += " --replace-tabs=\(space)"
        }
        
        // Font family.
        let font = custom_settings.fontFamily
        if font != "" {
            env["font"] = font
        }
        
        // Font size.
        let fontSize = custom_settings.fontSize
        if fontSize > 0 {
            if custom_settings.format == .html {
                env["fontSizePoints"] = String(format: "%2f", fontSize * 0.75)
            } else {
                env["fontSizePoints"] = "\(fontSize)"
            }
        }
        
        // Debug
        env["qlcc_debug"] = custom_settings.debug ? "1" : ""
        
        // Output format.
        env["extraHLFlags"]! += " -O \(format)"
        if format == SCSHFormat.rtf.rawValue {
            env["extraHLFlags"]! += " --page-color --char-styles"
        } else {
            if let style = Bundle.main.path(forResource: "style", ofType: "css") {
                env["extraHLFlags"]! += " --style-infile=\(style)"
            }
        }
        
        /// Command to execute.
        let cmd = "'\(self.rsrcEsc)/colorize.sh' '\(self.rsrcEsc)' '\(targetEsc.replacingOccurrences(of: "'", with: "'\\''"))' 0"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", env)
        
        let result = try SCSHXPCService.runTask(script: cmd, env: env)
            
        if result.exitCode != 0 {
            os_log(OSLogType.error, log: self.log, "QLColorCode: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            
            let e = SCSHError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "QLColorCode: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).")
            throw e
        } else {
            var final_settings = settings.overriding([
                SCSHSettings.Key.theme.rawValue: theme,
                SCSHSettings.Key.format.rawValue: format,
            ])
            if format == SCSHFormat.rtf.rawValue {
                let bgLight = custom_settings.rtfLightBackgroundColor
                let bgDark = custom_settings.rtfDarkBackgroundColor
                let bg = custom_settings.rtfBackgroundColor ?? (isOSThemeLight ? bgLight : bgDark)
                final_settings.rtfBackgroundColor = bg
            }
            
            return (result: result, settings: final_settings.toDictionary())
        }
    }
    
    /// Colorize a source file returning a formatted rtf code.
    func colorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        let custom_settings = self.settings.overriding(overrideSettings as? [String: Any])
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted html code.
    func htmlColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (String, NSDictionary, Error?) -> Void) {
        var custom_settings = self.settings.overriding(overrideSettings as? [String: Any])
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
        var custom_settings = self.settings.overriding(overrideSettings as? [String: Any])
        custom_settings.format = SCSHFormat.rtf
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Get the list of available themes.
    /// Return an array of dictionary with key _name_ and _desc_ and _color_ for the background color.
    func getThemes(withReply reply: @escaping ([NSDictionary], Error?) -> Void) {
        self.getThemes(highlight: self.settings.highlightProgramPath, withReply: reply)
    }
    
    func getThemes(highlight path: String, withReply reply: @escaping ([NSDictionary], Error?) -> Void) {
        let result: TaskResult
        
        let highlight_executable: String
        let env: [String: String]
        if path == "-" {
            let r = self.getEmbededHiglight()
            highlight_executable = r.path
            env = r.env
        } else {
            highlight_executable = path
            env = [:]
        }
        do {
            guard highlight_executable != "", highlight_executable != "false" else {
                reply([], nil)
                return
            }
            result = try SCSHXPCService.runTask(script: "\(highlight_executable) --list-scripts=theme", env: env)
            guard result.isSuccess else {
                reply([], nil)
                return
            }
        } catch {
            reply([], error)
            return
        }
        
        guard let output = result.output(), let regex = try? NSRegularExpression(pattern: #"^(.+)\s+:\s+(.+)$"#, options: []) else {
            reply([], nil)
            return
        }
        
        let fileManager = FileManager.default
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
        
        var results: [NSDictionary] = []
        for line in output.split(separator: "\n").map({ String($0) }) {
            let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, options: [], range: nsrange) {
                let firstCaptureRange = Range(match.range(at: 1), in: line)!
                let secondCaptureRange = Range(match.range(at: 2), in: line)!
                let name = line[firstCaptureRange].trimmingCharacters(in: CharacterSet.whitespaces)
                let desc = line[secondCaptureRange].trimmingCharacters(in: CharacterSet.whitespaces)
                
                let result = NSMutableDictionary()
                
                result["name"] = name
                result["desc"] = desc
                if let theme_url = theme_dir_url?.appendingPathComponent("\(name).theme") {
                    // Parse theme file.
                    let theme = SCSHTheme(url: theme_url)
                    if theme.categories.count > 0 {
                        result["desc"] = "\(desc) [\(theme.categories.joined(separator: ", "))]"
                    }
                    result["bg-color"] = theme.backgroundColor
                    result["base16"] = theme.isBase16
                }
                
                results.append(result)
            }
        }
        results.sort { (a, b) -> Bool in
            let desc1 = a["desc"] as! String
            let desc2 = b["desc"] as! String
            return desc1 < desc2
        }
        
       
        reply(results, nil)
    }
    
    /// Get settings.
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void) {
        reply(self.settings.toDictionary() as NSDictionary)
    }
    
    /// Set and store the settings.
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void) {
        if let s = settings as? [String: Any] {
            self.settings.fromDictionary(s)
            reply(self.settings.synchronize())
        } else {
            reply(false)
        }
    }
    
    func getEmbededHiglight() -> (path: String, env: [String: String]) {
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
            guard let r = try? SCSHXPCService.runTask(script: "\(path) --version", env: env), r.isSuccess, let output = r.output(), output.contains("Andre Simon"), let regex = try? NSRegularExpression(pattern: #"highlight version (\d\.\d+)"#, options: []) else {
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
        
        let embedHiglight = self.getEmbededHiglight()
        if let v = parse_version(embedHiglight.path, embedHiglight.env) {
            result.append([embedHiglight.path, v, true])
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
}
