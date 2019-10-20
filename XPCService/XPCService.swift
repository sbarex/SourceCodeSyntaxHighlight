//
//  XPCService.swift
//  XPCService
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

import Foundation
import OSLog

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.

class XPCService: NSObject, XPCServiceProtocol {
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
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook-xpc-qlcolorcode")
    }()
    
    let XPCDomain = "org.sbarex.QLColorCode"
    
    var settings: QLCSettings
    let rsrcEsc: String
    
    override init() {
        let rsrcDirURL = Bundle.main.resourceURL!
        self.rsrcEsc = rsrcDirURL.path
        
        // Set up preferences
        self.settings = QLCSettings(domain: XPCDomain)
        
        // Try to find highlight location
        var highlightPath: String = settings.highlightProgramPath
        if highlightPath == "" {
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
            let r = try? XPCService.runTask(script: "which highlight", env: env)
            if r?.isSuccess ?? false {
                highlightPath = r!.output() ?? ""
                if highlightPath.hasPrefix("/") && highlightPath.hasSuffix("highlight") {
                    // i.e. highlightPath looks like the actual path
                    settings.highlightProgramPath = highlightPath
                    _ = settings.synchronize()
                }
            }
        }
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
            throw QLCError.shellError(cmd: script, exitCode: -1, stdOut: "", stdErr: "", message: error.localizedDescription)
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
    private func colorize(url: URL, custom_settings: QLCSettings) throws -> (result: TaskResult, settings: [String: Any])
    {
        let highlightPath = custom_settings.highlightProgramPath
        
        guard highlightPath != "" else {
            throw QLCError.missingHighlight
        }
        
        let defaults = UserDefaults.standard
        
        /// Output format.
        let format = custom_settings.format.rawValue
        
        let targetEsc = url.path
        
        os_log(OSLogType.debug, log: self.log, "colorizing %{public}@", url.path)
        // os_log(OSLogType.debug, log: log, "target = %@", targetEsc)

        // Set environment variables.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (env["PATH"] ?? "") + ":/usr/local/bin:/usr/local/sbin"
        env["pathHL"] = highlightPath
        
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
        if custom_settings.lineNumbers {
            env["extraHLFlags"]! += " --line-numbers"
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
            env["fontSizePoints"] = "\(fontSize)"
        }
        
        // Debug
        env["qlcc_debug"] = custom_settings.debug ? "1" : ""
        
        // Output format.
        env["extraHLFlags"]! += " -O \(format)"
        if format == QLCFormat.rtf.rawValue {
            env["extraHLFlags"]! += " --page-color --char-styles"
        }
        
        /// Command to execute.
        let cmd = "'\(self.rsrcEsc)/colorize.sh' '\(self.rsrcEsc)' '\(targetEsc.replacingOccurrences(of: "'", with: "'\\''"))' 0"
        
        os_log(OSLogType.debug, log: self.log, "cmd = %{public}@", cmd)
        os_log(OSLogType.debug, log: self.log, "env = %@", env)
        
        let result = try XPCService.runTask(script: cmd, env: env)
            
        if result.exitCode != 0 {
            os_log(OSLogType.error, log: self.log, "QLColorCode: colorize.sh failed with exit code %d. Command was (%{public}@).", result.exitCode, cmd)
            
            let e = QLCError.shellError(cmd: cmd, exitCode: result.exitCode, stdOut: result.output() ?? "", stdErr: result.errorOutput() ?? "", message: "QLColorCode: colorize.sh failed with exit code \(result.exitCode). Command was (\(cmd)).")
            throw e
        } else {
            var final_settings = settings.overriding([
                QLCSettings.Key.theme.rawValue: theme,
                QLCSettings.Key.format.rawValue: format,
            ])
            if format == QLCFormat.rtf.rawValue {
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
            reply("".data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted html code.
    func htmlColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (String, NSDictionary, Error?) -> Void) {
        var custom_settings = self.settings.overriding(overrideSettings as? [String: Any])
        custom_settings.format = QLCFormat.html
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.output() ?? "", result.settings as NSDictionary, nil)
        } catch {
            reply("", custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Colorize a source file returning a formatted rtf code.
    func rtfColorize(url: URL, overrideSettings: NSDictionary? = nil, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        var custom_settings = self.settings.overriding(overrideSettings as? [String: Any])
        custom_settings.format = QLCFormat.rtf
        do {
            let result = try colorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply("".data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
    
    /// Get the list of available themes.
    /// Return an array of dictionary with key _name_ and _desc_ and _color_ for the background color.
    func getThemes(withReply reply: @escaping ([NSDictionary], Error?) -> Void) {
        let result: TaskResult
        do {
            guard self.settings.highlightProgramPath != "" else {
                reply([], nil)
                return
            }
            result = try XPCService.runTask(script: "\(self.settings.highlightProgramPath) --list-scripts=theme")
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
                    let theme = Theme(url: theme_url)
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
}
