//
//  ColorizeArgument.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 07/11/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

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
    
    /// Initialize the highlight arguments
    /// - parameters:
    ///   - highlight: Path of the highlight executable.
    ///   - dataDir: Url of the highlight data dir.
    ///   - url: Url of the file to highlight.
    ///   - custom_settings:
    ///   - extraCss: Url of an exgra style sheet.
    init (highlight highlightPath: String, dataDir: String?, url: URL, custom_settings: SettingsRendering, extraCss: URL?) throws  {
        // Set environment variables.
        // All values on env are automatically quoted escaped.
        var env = ProcessInfo.processInfo.environment
        
        var hlArguments = try custom_settings.getHighlightArguments()
        if let dataDir = dataDir {
            try? "Highlight dataDir: \(dataDir)".appendLine(to: custom_settings.logFile)
            env["HIGHLIGHT_DATADIR"] = dataDir
            hlArguments.arguments.append("--data-dir=\(dataDir)")
        }
        
        if custom_settings.themeLua.isEmpty {
            if hlArguments.theme.hasPrefix("!") {
                // Custom theme.
                hlArguments.theme.remove(at: hlArguments.theme.startIndex)
                if let theme_url = SCSHBaseXPCService.getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent(hlArguments.theme).appendingPathExtension("theme") {
                    try? "Highlight theme: \(theme_url.path)".appendLine(to: custom_settings.logFile)
                    hlArguments.arguments.append("--style=\(theme_url.path)")
                }
            } else if let dataDir = dataDir {
                try? "Highlight theme: \(dataDir)/themes/\(hlArguments.theme)".appendLine(to: custom_settings.logFile)
                hlArguments.arguments.append("--style=\(dataDir)/themes/\(hlArguments.theme).theme")
            } else {
                try? "Highlight theme: \(hlArguments.theme)".appendLine(to: custom_settings.logFile)
                hlArguments.arguments.append("--style=\(hlArguments.theme)")
            }
        }
        
        if custom_settings.isAboutVisible {
            env["SH_VERSION"] = custom_settings.app_version
            hlArguments.arguments.append("--plug-in=about")
            try? "Highlight plugin: about.lua".appendLine(to: custom_settings.logFile)
        }
        
        if custom_settings.isVCS && !custom_settings.vcsDiff.isEmpty {
            // Set the env used by the vcs plugin.
            env["VCS_DIFF"] = custom_settings.vcsDiff.joined(separator: " ")
            
            let isOSThemeLight = custom_settings.isOSThemeLight()
            
            env["VCS_ADD"] = isOSThemeLight ? custom_settings.vcsAddLightColor : custom_settings.vcsAddDarkColor
            env["VCS_EDIT"] = isOSThemeLight ? custom_settings.vcsEditLightColor : custom_settings.vcsEditDarkColor
            env["VCS_DEL"] = isOSThemeLight ? custom_settings.vcsDelLightColor : custom_settings.vcsDelDarkColor
            hlArguments.arguments.append("--plug-in=vcs")
            try? "Highlight plugin: vsc.lua".appendLine(to: custom_settings.logFile)
        }
        
        var cssCode: String = ""
        if custom_settings.format == .html {
            let baseCSSFolder = SCSHBaseXPCService.getCustomStylesUrl(createIfMissing: false)
            
            let importCSS = {(path_component: String)->String in
                guard let css_url = baseCSSFolder?.appendingPathComponent(path_component) else {
                    return ""
                }
                guard FileManager.default.fileExists(atPath: css_url.path) else {
                    // try? "CSS: missing \(css_url.path)".appendLine(to: custom_settings.logFile)
                    return ""
                }
                guard let s = try? String(contentsOf: css_url, encoding: .utf8) else {
                    try? "ERROR: unable to read the css file \(css_url.path)".appendLine(to: custom_settings.logFile)
                    return ""
                }
                try? "CSS: \(css_url.path)".appendLine(to: custom_settings.logFile)
                return "\(s)\n"
            }
            
            // Import global css style.
            cssCode += importCSS("global.css")
            
            // Import per file css style.
            if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
                cssCode += importCSS("\(uti).css")
            }
            
            if custom_settings.isCSSDefined && !custom_settings.css.isEmpty {
                // Passing a css value in the settings prevent the embed of styles saved on disk.
                cssCode += "\(custom_settings.css)\n"
            }
            
            // Embed the custom standard style.
            if let style = extraCss, FileManager.default.fileExists(atPath: style.path) {
                if !cssCode.isEmpty {
                    cssCode += "\n"
                }
                do {
                    var enc: String.Encoding = .utf8
                    cssCode += try String(contentsOf: style, usedEncoding: &enc)
                    try? "CSS: \(style.path)".appendLine(to: custom_settings.logFile)
                } catch {
                    try? "ERROR: unable to read the CSS file `\(style.path)`".appendLine(to: custom_settings.logFile)
                    cssCode += "/* Error: unable to append `\(style.path)` CSS file! */\n";
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
            "logHL": custom_settings.logFile?.path ?? "",
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
            try? "Max data: \(maxData)".appendLine(to: custom_settings.logFile)
            try? "EOL conversion: \(custom_settings.convertEOL ? "on" : "off")".appendLine(to: custom_settings.logFile)
            if custom_settings.isPreprocessorDefined {
                let preprocessor = custom_settings.preprocessor.trimmingCharacters(in: CharacterSet.whitespaces)
                if !preprocessor.isEmpty {
                    env["preprocessorHL"] = preprocessor
                    try? "Preprocessor: \(preprocessor)".appendLine(to: custom_settings.logFile)
                } else {
                    env.removeValue(forKey: "preprocessorHL")
                }
            } else {
                env.removeValue(forKey: "preprocessorHL")
            }
        }
        
        if custom_settings.isSyntaxDefined && !custom_settings.syntax.isEmpty {
            env["syntaxHL"] = custom_settings.syntax
            try? "Highlight syntax: \(custom_settings.syntax)".appendLine(to: custom_settings.logFile)
        }
        
        self.init(highlight: highlightPath, env: env, theme: hlArguments.theme, backgroundColor: hlArguments.backgroundColor, css: custom_settings.format == .rtf ? nil : cssCode, inlineTheme: custom_settings.themeLua, arguments: hlArguments.arguments)
    }
}
