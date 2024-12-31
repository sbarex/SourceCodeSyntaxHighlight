//
//  main.swift
//  syntax_highlight_cli
//
//  Created by Sbarex on 12/10/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import OSLog

func getCliUrl() -> URL {
    let fileManager = FileManager.default
    let currentExecutablePath = URL(fileURLWithPath: CommandLine.arguments[0])
    
    let attributes = try? fileManager.attributesOfItem(atPath: currentExecutablePath.path)
    
    if let fileType = attributes?[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
        if let originalPath = try? fileManager.destinationOfSymbolicLink(atPath: currentExecutablePath.path) {
            return URL(fileURLWithPath: originalPath)
        }
    }
    
    return currentExecutablePath
}

let cliUrl = getCliUrl()

var standardError = FileHandle.standardError

extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

func usage(exitCode: Int = -1) {
    let name = cliUrl.lastPathComponent
    print("\(name)")
    print("Usage: \(name) [-o <path>] <file> [..]")
    print("\nArguments:")
    print(" -h                          \tShow this help and exit.")
    
    print(" -t                          \tTest without save/output the result.")
    print(" -o <path>                   \tSave the output to <path>.")
    print("                             \tIf <path> is a directory a new file is created with the name of the source.")
    print("                             \tExtension will be automatically added.")
    print("                             \tDestination file is always overwritten.")
    
    print(" -v                          \tVerbose mode. Valid only with the -o option.")
    print(" --app <path>                \tSet the path of \"Source Highlight.app\" otherwise assume that \(name) is called from the Contents/Resources of the app bundle.")
    print(" --log file                  \tSave the log to the specified file.")
    print("")
    print(" --appearance light|dark     \tForce the requested appearance.")
    print(" --theme-light name          \tTheme for light appearance.")
    print(" --theme-dark name           \tTheme for dark appearance.")
    print(" --theme name                \tTheme for all appearance.")
    print(" --format html|rtf           ")
    print(" --syntax value              ")
    print(" --preprocessor value        \tProtect the preprocessor code inside quotes.")
    print(" --font family               \tFont name. Use '-' to choose the system monospace.")
    print(" --font-size value           \tFont size in points.")
    print(" --wrap hard|soft|no         \tWord wrap.")
    print(" --wrap-one-line             \tForce word wrap for only one line files.")
    print(" --line-length value         ")
    print(" --line-numbers on|zeros|off ")
    print(" --tab-spaces value          \tNumber of spaces for every tab. Set to zero to disable the tab conversion.")
    print(" --extra arguments           \tExtra arguments passed to highlight. Protect the arguments inside quotes.")
    print(" --extra-appended arguments  \tExtra arguments passed to highlight. Protect the arguments inside quotes.")
    print(" --css file                  \tExtra css loaded from the specified file.")
    print(" --max-data bytes            \tTrim source file that exceeds the size.")
    print(" --convert-eol on|off        \tConvert end of line.")
    print(" --vcs on|off                \tEnable support for version control.")
    print(" --vcs-git path              \tPath of git binary.")
    print(" --vcs-hg path               \tPath of mercurial binary.")
    print(" --vcs-color-add             \tColor (in #rrggbb) for added lines.")
    print(" --vcs-color-del             \tColor (in #rrggbb) for removed lines.")
    print(" --vcs-color-edit            \tColor (in #rrggbb) for changed lines.")
    print(" --lsp on|off                \tEnable Language server protocol.")
    print(" --lsp-exe file              \tPath of the LSP executable.")
    print(" --lsp-delay ms              ")
    print(" --lsp-syntax value          \tRecognize data processed by LSP with the provided syntax.")
    print(" --lsp-hover on|off          ")
    print(" --lsp-semantic on|off       ")
    print(" --lsp-errors on|off         ")
    print(" --lsp-option arg            \tExtra argument passed to the LSP program. Protect the value inside quotes. You can repeat --lsp-option multiple times.")
    print(" --about on|off              Show a footer with info about Syntax Highlight engine.")
    print(" --debug on|off              ")
    print("\nTo handle multiple files at time you must pass the -o argument with a destination folder.")
    print("\nUnspecified rendering options will use the settings defined in the main application.")
    if exitCode >= 0 {
        exit(Int32(exitCode))
    }
}

func dump(settings: SettingsRendering) {
    print("  Rendering settings")
    if let isLight = settings.isLight {
        print("  - Appearance: \(isLight ? "light" : "dark")")
    } else {
        print("  - Appearance: auto")
    }
    print("  - Render engine: \(settings.format.rawValue)")
    print("  - Color scheme: \(settings.themeName)")
    print("  - Font: \(settings.fontName == "-" ? "System monospace" : settings.fontName), \(settings.fontSize) pt")
    if settings.isWordWrapped {
        print("  - Word wrap: \(settings.isWordWrappedHard ? "hard, at column \(settings.lineLength)" : "soft")")
    } else if settings.isWordWrappedSoftForOneLineFiles {
        print("  - Word wrap: hard, at column \(settings.lineLength), only for one line files")
    } else {
        print("  - Word wrap: disabled")
    }
    print("  - Line numbers: \(settings.isLineNumbersVisible ? "visible" + (settings.isLineNumbersFillToZeroes ? " filled with zeros" : "") : "disabled")")
    print("  - Tabs: \(settings.tabSpaces > 0 ? "converted to \(settings.tabSpaces) spaces" : "not converted")")
    if !settings.arguments.isEmpty {
        print("  - Extra highlight arguments: \(settings.arguments)")
    }
    if !settings.isAppendArgumentsDefined {
        print("  - Extra appended highlight arguments: \(settings.appendArguments)")
    }
    if settings.isPreprocessorDefined {
        print("  - Preprocessor: \(settings.preprocessor)")
    }
    if settings.isSyntaxDefined {
        print("  - Syntax: \(settings.syntax)")
    }
    if settings.isUsingLSP {
        print("  - LSP: enabled")
        print("      LSP executable: \(settings.lspExecutable)")
        print("      LSP options: \(settings.lspOptions)")
        print("      LSP delay: \(settings.lspDelay) ms")
        print("      LSP syntax: \(settings.lspSyntax)")
        print("      LSP hover: \(settings.lspHover ? "on" : "off")")
        print("      LSP semantic: \(settings.lspSemantic ? "on" : "off")")
        print("      LSP errors: \(settings.lspSyntaxError ? "on" : "off")")
    } else {
        print("  - LSP: disabled")
    }
    if settings.format == .html && !settings.css.isEmpty {
        print("  - Extra CSS: \(settings.css)")
    }
    if settings.maxData > 0 {
        let f = ByteCountFormatter()
        f.countStyle = .file
        print("  - Max data: \(f.string(fromByteCount: Int64(settings.maxData)))")
    }
    print("  - Convert line ending: \(settings.convertEOL ? "enabled" : "disabled")")
    print("  - VCS: \(settings.isVCS ? "enabled" : "disabled")")
    print("  - About info: \(settings.isAboutVisible ? "on" : "off")")
    print("  - Debug: \(settings.isDebug ? "on" : "off")")
}

func parseArgOnOff(index i: Int) -> Bool {
    guard i+1 < CommandLine.arguments.count else {
        print("\(cliUrl.lastPathComponent): \(CommandLine.arguments[i]) require an on|off argument.\n", to: &standardError)
        usage(exitCode: 1)
        return false
    }
    
    let u = CommandLine.arguments[i+1]
    switch u {
    case "on", "1": return true
    case "off", "0": return false
    default:
        print("\(cliUrl.lastPathComponent): illegal argument '\(u)' for \(CommandLine.arguments[i]) option.\n", to: &standardError)
        usage(exitCode: 1)
        return false
    }
}
func parseArgInt(index i: Int) -> Int {
    guard i+1 < CommandLine.arguments.count else {
        print("\(cliUrl.lastPathComponent): \(CommandLine.arguments[i]) require a numeric argument.\n", to: &standardError)
        usage(exitCode: 1)
        return 0
    }
    let u = CommandLine.arguments[i+1]
    if let u1 = Int(u) {
        return u1
    } else {
        print("\(cliUrl.lastPathComponent): illegal argument '\(u)' for \(CommandLine.arguments[i]) option.\n", to: &standardError)
        usage(exitCode: 1)
        return 0
    }
}
func parseArgFloat(index i: Int) -> Float {
    guard i+1 < CommandLine.arguments.count else {
        print("\(cliUrl.lastPathComponent): \(CommandLine.arguments[i]) require a numeric argument.\n", to: &standardError)
        usage(exitCode: 1)
        return 0
    }
    let u = CommandLine.arguments[i+1]
    if let u1 = Float(u) {
        return u1
    } else {
        print("\(cliUrl.lastPathComponent): illegal argument '\(u)' for \(CommandLine.arguments[i]) option.\n", to: &standardError)
        usage(exitCode: 1)
        return 0
    }
}
func parseArgString(index i: Int) -> String {
    guard i+1 < CommandLine.arguments.count else {
        print("\(cliUrl.lastPathComponent): \(CommandLine.arguments[i]) require an extra argument.\n", to: &standardError)
        usage(exitCode: 1)
        return ""
    }
    return CommandLine.arguments[i+1]
}

var overridingSettings: [String: AnyHashable] = [:]

var appUrl: URL!
var logFile: URL? = nil
var verbose = false
var test = false

var files: [URL] = []
var dest: URL?
var i = 1
while i < Int(CommandLine.argc) {
    var arg = CommandLine.arguments[i]
    if arg.hasPrefix("-") {
        if arg.hasPrefix("--") {
            // process a --arg
            switch arg {
            case "--help":
                usage(exitCode: 0)
            case "--app":
                appUrl = URL(fileURLWithPath: parseArgString(index: i))
                i += 1
            case "--log":
                logFile = URL(fileURLWithPath: parseArgString(index: i))
                i += 1
            
            case "--appearance":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings["isLight"] = u == "light"
            case "--theme-light":
                overridingSettings[SettingsBase.Key.lightTheme] = parseArgString(index: i)
                i += 1
            case "--theme-dark":
                overridingSettings[SettingsBase.Key.darkTheme] = parseArgString(index: i)
                i += 1
            case "--theme":
                overridingSettings[SettingsBase.Key.theme] = parseArgString(index: i)
                i += 1
            
            case "--format":
                overridingSettings[SettingsBase.Key.format] = parseArgString(index: i)
                i += 1
            
            case "--syntax":
                overridingSettings[SettingsBase.Key.syntax] = parseArgString(index: i)
                i += 1
            case "--preprocessor":
                overridingSettings[SettingsBase.Key.preprocessor] = parseArgString(index: i)
                i += 1
            
            case "--font":
                overridingSettings[SettingsBase.Key.fontFamily] = parseArgString(index: i)
                i += 1
            case "--font-size":
                overridingSettings[SettingsBase.Key.fontSize] = parseArgFloat(index: i)
                i += 1
            case "--wrap":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.wordWrap] = u != "off"
                overridingSettings[SettingsBase.Key.wordWrapHard] = u == "hard"
            case "--wrap-one-line":
                overridingSettings[SettingsBase.Key.wordWrapOneLineFiles] = true
            case "--line-length":
                overridingSettings[SettingsBase.Key.lineLength] = parseArgInt(index: i)
                i += 1
            case "--line-numbers":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.lineNumbers] = u != "off"
                overridingSettings[SettingsBase.Key.lineNumbersFillToZeroes] = u != "zeros"
            case "--tab-spaces":
                overridingSettings[SettingsBase.Key.tabSpaces] = parseArgInt(index: i)
                i += 1
                
            case "--extra":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.extraArguments] = u
            case "--extra-appended":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.appendedExtraArguments] = u
            
            case "--css":
                let u = parseArgString(index: i)
                i += 1
                let file = URL(fileURLWithPath: u)
                do {
                    let s = try String(contentsOf: file)
                    overridingSettings[SettingsBase.Key.customCSS] = s
                } catch {
                    print("\(cliUrl.lastPathComponent): unable to read css from file \(u)\n", to: &standardError)
                    usage(exitCode: 1)
                }
            
            case "--max-data":
                overridingSettings[SettingsBase.Key.maxData] = parseArgInt(index: i)
                i += 1
            
            case "--convert-eol":
                overridingSettings[SettingsBase.Key.convertEOL] = parseArgOnOff(index: i)
                i += 1
                
            case "--vcs":
                overridingSettings[SettingsBase.Key.vcs] = parseArgOnOff(index: i)
                i += 1
            case "--vcs-git":
                overridingSettings[SettingsBase.Key.git_path] = parseArgString(index: i)
                i += 1
            case "--vcs-hg":
                overridingSettings[SettingsBase.Key.hg_path] = parseArgString(index: i)
                i += 1
            case "--vcs-color-add":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.vcs_add_light] = u
                overridingSettings[SettingsBase.Key.vcs_add_dark] = u
            case "--vcs-color-del":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.vcs_del_light] = u
                overridingSettings[SettingsBase.Key.vcs_del_dark] = u
            case "--vcs-color-edit":
                let u = parseArgString(index: i)
                i += 1
                overridingSettings[SettingsBase.Key.vcs_edit_light] = u
                overridingSettings[SettingsBase.Key.vcs_edit_dark] = u
            
            case "--lsp":
                overridingSettings[SettingsBase.Key.lsp] = parseArgOnOff(index: i)
                i += 1
            case "--lsp-exe":
                overridingSettings[SettingsBase.Key.lspExecutable] = parseArgString(index: i)
                i += 1
            case "--lsp-delay":
                overridingSettings[SettingsBase.Key.lspDelay] = parseArgInt(index: i)
                i += 1
            case "--lsp-syntax":
                overridingSettings[SettingsBase.Key.lspSyntax] = parseArgOnOff(index: i)
                i += 1
            case "--lsp-hover":
                overridingSettings[SettingsBase.Key.lspHover] = parseArgOnOff(index: i)
                i += 1
            case "--lsp-semantic":
                overridingSettings[SettingsBase.Key.lspSemantic] = parseArgOnOff(index: i)
                i += 1
            case "--lsp-errors":
                overridingSettings[SettingsBase.Key.lspSyntaxError] = parseArgOnOff(index: i)
                i += 1
            case "--lsp-option":
                let u = parseArgString(index: i)
                i += 1
                var options: [String] = []
                if let o = overridingSettings[SettingsBase.Key.lspOptions] as? [String] {
                    options = o
                }
                options.append(u)
                overridingSettings[SettingsBase.Key.lspOptions] = options
                
            case "--about":
                overridingSettings[SettingsBase.Key.about] = parseArgOnOff(index: i)
                i += 1
            case "--debug":
                overridingSettings[SettingsBase.Key.debug] = parseArgOnOff(index: i)
                i += 1
                
            default:
                print("\(cliUrl.lastPathComponent): illegal option \(arg)\n", to: &standardError)
                usage(exitCode: 1)
            }
        } else {
            // process a -arg
            arg.removeFirst()
            for (j, arg1) in arg.enumerated() {
                switch arg1 {
                case "h":
                    usage(exitCode: 0)
                case "t":
                    test = true
                case "o":
                    if j + 1 == arg.count {
                        dest = URL(fileURLWithPath: CommandLine.arguments[i+1])
                        i += 1
                    } else {
                        print("\(cliUrl.lastPathComponent): option -\(arg1) require a destination path\n", to: &standardError)
                        usage(exitCode: 1)
                    }
                case "v":
                    verbose = true
                default:
                    print("\(cliUrl.lastPathComponent): illegal option -\(arg1)\n", to: &standardError)
                    usage(exitCode: 1)
                }
            }
        }
    } else {
        files.append(URL(fileURLWithPath: arg))
    }
    i += 1
}

verbose = verbose && dest != nil

if appUrl == nil {
    appUrl = cliUrl.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

/*
if logFile == nil {
    logFile = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log")
}
*/

if let logFile = logFile {
    // Reset the log file.
    try? "".write(to: logFile, atomically: true, encoding: .utf8)
}

let appBundleUrl = appUrl.appendingPathComponent("Contents/Resources")
let xpcBundleUrl = appBundleUrl.appendingPathComponent("../PlugIns/Syntax Highlight Quick Look Extension.appex/Contents/XPCServices/Resources")

let highlightBin = appBundleUrl.appendingPathComponent("highlight/bin/highlight")
let highlightDataDir = appBundleUrl.appendingPathComponent("highlight/share")

let settings = Settings(defaultsDomain: SCSHBaseXPCService.XPCDomain)
if let dir = SCSHBaseXPCService.getCustomStylesUrl(createIfMissing: false) {
    settings.populateCSS(cssFolder: dir)
}

var isDir: ObjCBool = false
if let dest = dest {
    FileManager.default.fileExists(atPath: dest.path, isDirectory: &isDir)
}

if files.count > 1 {
    if !isDir.boolValue {
        print("Error: to process multiple files you must use the -o argument with a folder path!", to: &standardError)
        exit(1)
    }
}

var n = 0
defer {
    if verbose {
        print(n != 1 ? "Processed \(n) files." : "Processed 1 file.")
    }
}

let env = ProcessInfo.processInfo.environment

let highlightLanguages: [String: [String]] = (try? SCSHBaseXPCService.parseHighlightLanguages(file: xpcBundleUrl.appendingPathComponent("languages.json"))) ?? [:]

let dos2unix = appBundleUrl.appendingPathComponent("dos2unix").path

if files.isEmpty {
    usage(exitCode: 1)
}

for src in files {
    guard FileManager.default.isReadableFile(atPath: src.path) else {
        print("Unable to read the file \(src.path)", to: &standardError)
        exit(127)
    }
    
    if verbose {
        print("- processing \(src.path) ...")
    }
    
    let r: (data: Data, settings: SettingsRendering)
    do {
        r = try SCSHBaseXPCService.colorize(url: src, settings: settings, highlightBin: highlightBin.path, dataDir: highlightDataDir.path, rsrcEsc: appBundleUrl.path, dos2unixBin: dos2unix, highlightLanguages: highlightLanguages, extraCss: appBundleUrl.appendingPathComponent("highlight/style.css"), overridingSettings: overridingSettings, logFile: logFile, logOs: nil)
        if verbose {
            dump(settings: r.settings)
        }
    } catch {
        print("Error processing \(src.path): \(error.localizedDescription)", to: &standardError)
        exit(1)
    }
    
    var output: URL?
    if let dest = dest {
        if isDir.boolValue {
            output = dest.appendingPathComponent(src.deletingPathExtension().lastPathComponent)
        } else {
            output = dest
        }
        let ext = output!.pathExtension.lowercased()
        if r.settings.format == .rtf && ext != "rtf" {
            output!.appendPathExtension("rtf")
        } else if r.settings.format == .html && !ext.hasPrefix("htm") {
            output!.appendPathExtension("html")
        }
    }
    
    guard !test else {
        continue
    }
    do {
        if let output = output {
            try r.data.write(to: output)
            if verbose {
                print("  ... stored in \(output.path)")
            }
            n += 1
        } else {
            try FileHandle.standardOutput.write(contentsOf: r.data)
            n += 1
        }
    } catch {
        print("Error saving \(src.path): \(error.localizedDescription)", to: &standardError)
        exit(1)
    }
}
