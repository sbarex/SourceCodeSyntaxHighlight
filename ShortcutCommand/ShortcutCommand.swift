//
//  ShortcutCommand.swift
//  ShortcutCommand
//
//  Created by Sbarex on 25/12/24.
//  Copyright © 2024 sbarex. All rights reserved.
//

import AppIntents
import AppKit
import OSLog
import UniformTypeIdentifiers

enum ShortcutCommandError: Error {
    case invalidConfiguration
}

enum OptionalEngineEnum: String, AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Option engine")
    
    case predefined
    case html
    case rtf
    
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .predefined: "predefined",
        .html: "HTML",
        .rtf: "RTF",
    ]
}

struct ShortcutCommand: AppIntent {
    static var title: LocalizedStringResource { "Syntax Highlight source file" }
    static var description: LocalizedStringResource { "Syntax Highlights the source code of a file." }
    static var openAppWhenRun: Bool = false
    
    static var parameterSummary: some ParameterSummary {
        Summary("Highlight source code of \(\.$inputFile) to a \(\.$engine) file.") {
            \.$debugLog
        }
    }
    
    // Define the input parameter
    @Parameter(title: "Input File",
                  description: "The source file to hightlights.",
               supportedContentTypes: [UTType.sourceCode, UTType.text, UTType.data, UTType.item])
    var inputFile: IntentFile
    @Parameter(title: "Engine",
               description: "The rendering engine.", default: .predefined)
    var engine: OptionalEngineEnum
    
    @Parameter(title: "Generate debug log",
               description: "Save log to ~/Desktop/colorize.log", default: false)
    var debugLog: Bool
    
    func perform() async throws -> some ReturnsValue<IntentFile> {
        let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "shortcut extension")
        
        os_log(
            "Generating preview for file %{public}s…",
            log: log,
            type: .info,
            inputFile.fileURL?.absoluteString ?? "?"
        )
        
        let _ = inputFile.data
        
        let settings = Settings(defaultsDomain: SCSHBaseXPCService.XPCDomain)
        if self.engine != .predefined {
            settings.format = self.engine == .html ? .html : .rtf
        }
        if let dir = SCSHBaseXPCService.getCustomStylesUrl(createIfMissing: false) {
            settings.populateCSS(cssFolder: dir)
        }
        
        let logFile = debugLog ? SCSHBaseXPCService.initLog(forSettings: settings) : URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("colorize.log")
        if !debugLog {
            // Reset the log file.
            try? "".write(to: logFile, atomically: true, encoding: .utf8)
        }
        defer {
            if !debugLog {
                try? FileManager.default.removeItem(at: logFile)
            }
        }
        
        os_log(
            "Storing log on file %{public}s…",
            log: log,
            type: .debug,
            logFile.path(percentEncoded: false)
        )
        
        let appBundleUrl =  Bundle.main.bundleURL.appendingPathComponent("Contents/Resources")
        
        // TODO: Sandbox prevent to access the bundle of the main app, so is required to have a second copy of all highlight resources inside this extension bundle.
        guard
            let highlightBin = Bundle.main.url(forResource: "highlight", withExtension: "", subdirectory: "highlight/bin"),
            let highlightDataDir = Bundle.main.url(forResource: "share", withExtension: "", subdirectory: "highlight"),
            let dos2unix = Bundle.main.url(forResource: "dos2unix", withExtension: "")?.path,
            let languages = Bundle.main.url(forResource: "languages", withExtension: "json"),
            let extraCSS = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "highlight")
        else {
            throw ShortcutCommandError.invalidConfiguration
        }
        
        let highlightLanguages: [String: [String]] = (try? SCSHBaseXPCService.parseHighlightLanguages(file: languages)) ?? [:]
        
        do {
            let r: (data: Data, settings: SettingsRendering) = try SCSHBaseXPCService.colorize(url: inputFile.fileURL!, settings: settings, highlightBin: highlightBin.path, dataDir: highlightDataDir.path, rsrcEsc: appBundleUrl.path, dos2unixBin: dos2unix, highlightLanguages: highlightLanguages, extraCss: extraCSS, overridingSettings: [:], logFile: logFile, logOs: log)
            let dst = inputFile.fileURL!.deletingPathExtension().lastPathComponent + (settings.format == .html ? ".html" : ".rtf")
            return .result(value: IntentFile(data: r.data, filename: dst, type: settings.format == .html ? UTType.html : UTType.rtf))
        } catch {
            os_log(
                "Error processing %{public}s: %{public}s!",
                log: log,
                type: .error,
                inputFile.fileURL!.path,
                error.localizedDescription
            )
            throw error
        }
    }
}

