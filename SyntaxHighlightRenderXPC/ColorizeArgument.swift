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
            env["HIGHLIGHT_DATADIR"] = dataDir
            hlArguments.arguments.append("--data-dir=\(dataDir)")
        }
        
        if custom_settings.themeLua.isEmpty {
            if hlArguments.theme.hasPrefix("!") {
                // Custom theme.
                hlArguments.theme.remove(at: hlArguments.theme.startIndex)
                if let theme_url = SCSHBaseXPCService.getCustomThemesUrl(createIfMissing: false)?.appendingPathComponent(hlArguments.theme).appendingPathExtension("theme") {
                    hlArguments.arguments.append("--style=\(theme_url.path)")
                }
            } else if let dataDir = dataDir {
                hlArguments.arguments.append("--style=\(dataDir)/themes/\(hlArguments.theme).theme")
            } else {
                hlArguments.arguments.append("--style=\(hlArguments.theme)")
            }
        }
        
        if custom_settings.isVCS && !custom_settings.vcsDiff.isEmpty {
            // Set the env used by the vcs plugin.
            env["VCS_DIFF"] = custom_settings.vcsDiff.joined(separator: " ")
            
            let isOSThemeLight = custom_settings.isOSThemeLight()
            
            env["VCS_ADD"] = isOSThemeLight ? custom_settings.vcsAddLightColor : custom_settings.vcsAddDarkColor
            env["VCS_EDIT"] = isOSThemeLight ? custom_settings.vcsEditLightColor : custom_settings.vcsEditDarkColor
            env["VCS_DEL"] = isOSThemeLight ? custom_settings.vcsDelLightColor : custom_settings.vcsDelDarkColor
            hlArguments.arguments.append("--plug-in=vcs")
        }
        
        var cssCode: String?
        if custom_settings.format == .html {
            cssCode = ""
            if custom_settings.isCSSDefined && !custom_settings.css.isEmpty {
                // Passing a css value in the settings prevent the embed of styles saved on disk.
                cssCode! += "\(custom_settings.css)\n"
            } else {
                // Import global css style.
                if let css_url = SCSHBaseXPCService.getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("global.css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
                
                // Import per file css style.
                if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier, let css_url = SCSHBaseXPCService.getCustomStylesUrl(createIfMissing: false)?.appendingPathComponent("\(uti).css"), FileManager.default.fileExists(atPath: css_url.path), let s = try? String(contentsOf: css_url, encoding: .utf8) {
                    cssCode! += "\(s)\n"
                }
            }
            
            // Embed the custom standard style.
            if let style = extraCss, FileManager.default.fileExists(atPath: style.path) {
                if !cssCode!.isEmpty {
                    cssCode! += "\n"
                }
                do {
                    cssCode! += try String(contentsOf: style)
                } catch {
                    try? "Unable to append code to `\(style.path)` CSS file!".append(to: custom_settings.logFile)
                    cssCode! += "/* Error: unable to append `\(style.path)` CSS file! */\n";
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
        
        self.init(highlight: highlightPath, env: env, theme: hlArguments.theme, backgroundColor: hlArguments.backgroundColor, css: cssCode, inlineTheme: custom_settings.themeLua, arguments: hlArguments.arguments)
    }
}
