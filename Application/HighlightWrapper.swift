//
//  HighlightWrapper.swift
//  Syntax Highlight XPC Service
//
//  Created by Sbarex on 08/01/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Service


enum HighlightWrapperError: Error {
    case themeExists(path: URL)
}

class HighlightWrapper {
    struct Language {
        let desc: String
        let extensions: [String]
        init (desc: String, extensions: [String]) {
            self.desc = desc
            self.extensions = extensions
        }
    }
    
    struct Plugin {
        let name: String
        let desc: String
        let path: String
    }
    
    static let shared = HighlightWrapper()
    
    fileprivate(set) var themesDir: URL?
    
    private init() {
        SCSHWrapper.service?.getCustomThemesFolder(createIfMissing: false, reply: { url in
            self.themesDir = url
        })
    }
    
    /// Get the path of the `highlight` share folder.
    func getSupportFolder() -> String {
        return  Bundle.main.url(forResource: "highlight", withExtension: nil)!.appendingPathComponent("share").path
    }
    
    /// Initialize the highlight engine.
    internal func initHighlight() {
        if highlight_is_initialized() == 0 {
            let path = self.getSupportFolder()
            highlight_init(path.cString(using: .utf8))
        }
    }
    
    // MARK: - Themes
    /// List of all available themes (standalone and custom).
    lazy fileprivate(set) var themes: [SCSHThemePreview] = {
        return self.getThemes()
    }()
    
    func reloadThemes() {
        themes = self.getThemes()
    }
    
    func getThemes() -> [SCSHThemePreview] {
        self.initHighlight()
        
        class Themes {
            var themes: [SCSHThemePreview] = []
            
            static let callback: ResultThemeCallback = { (context, p_theme, exit_code) in
                guard exit_code == EXIT_SUCCESS, let c_theme = p_theme?.pointee else {
                    return
                }
                let themes = Unmanaged<Themes>.fromOpaque(context!).takeUnretainedValue()
                let theme = SCSHThemePreview(cTheme: c_theme)
                themes.themes.append(theme)
            }
        }
        let themes = Themes()
        
        let raw = Unmanaged.passUnretained(themes).toOpaque()
        
        // Get default themes.
        highlight_list_themes(raw) { (context, p_themes, n, exit_code) in
            guard exit_code == EXIT_SUCCESS, let c_themes = p_themes else {
                return
            }
            
            for i in 0 ..< Int(n) {
                guard let t = c_themes.advanced(by: i).pointee?.pointee else {
                    continue
                }
                
                highlight_get_theme(t.path, context, Themes.callback)
            }
        }
        
        // Get custom themes.
        if let themesDir = self.themesDir {
            do {
                for file in try FileManager.default.contentsOfDirectory(atPath: themesDir.path) {
                    let t = themesDir.appendingPathComponent(file).path
                    highlight_get_theme(t.cString(using: .utf8), raw, Themes.callback)
                }
            } catch {
                print("error \(error)")
            }
        }
        
        return themes.themes
    }
    
    func getTheme(name: String) -> SCSHThemePreview? {
        if !name.hasPrefix("!") {
            return getTheme(name: name, isStandalone: true)
        } else {
            var n = name
            n.removeFirst()
            return getTheme(name: n, isStandalone: false)
        }
    }
    
    func getTheme(name: String, isStandalone: Bool) -> SCSHThemePreview? {
        return themes.first(where: { (isStandalone ? $0.isStandalone : !$0.isStandalone) && $0.name == name })
    }
    
    /// Add a custom theme to the list.
    internal func addCustomTheme(_ theme: SCSHThemePreview) {
        theme.isStandalone = false
        self.themes.append(theme)
        NotificationCenter.default.post(name: NSNotification.Name.CustomThemeAdded, object: theme)
        SCSHWrapper.shared.settings?.isDirty = true
    }
    
    /// Remove a custom theme.
    /// - parameters:
    ///   - theme: theme to remove.
    @discardableResult
    func removeCustomTheme(_ theme: SCSHTheme) throws -> Bool {
        guard !theme.isStandalone else {
            return false
        }
        guard let i = self.themes.firstIndex(where: {$0.name == theme.name}) else {
            return false
        }
        
        if theme.exists {
            try FileManager.default.removeItem(atPath: theme.path)
        }
        
        self.themes.remove(at: i)
        NotificationCenter.default.post(name: .CustomThemeRemoved, object: theme)
        return true
    }
    
    func removeCustomTheme(_ theme: SCSHTheme, withAsk: Bool, sheetWindow window: NSWindow?, withErrorMessage: Bool, onComplete: @escaping (Bool, Error?)->Void) {
        guard !theme.isStandalone else {
            onComplete(false, nil)
            return
        }
        
        let showErrorMessage = { (error: Error) in
            let alert = NSAlert()
            alert.messageText = "Unable to delete the theme at \(theme.path)!"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "Close").keyEquivalent = "\r"
            
            alert.alertStyle = .critical
            alert.runModal()
        }
        
        if withAsk {
            let alert = NSAlert()
            alert.messageText = "Are you sure to delete this custom theme?"
            let used = SCSHWrapper.shared.isThemeUsed(name: theme.nameForSettings)
            if used {
                alert.informativeText = "This theme is used by some formats. If it will be deleted, the relative settings will be reset."
            }
            if used || theme.exists {
                alert.informativeText = (alert.informativeText.isEmpty ? "" : alert.informativeText + "\n\n") + "This operation cannot be undone."
            }
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
            alert.alertStyle = .critical
            
            if let win = window {
                alert.beginSheetModal(for: win) { (response) in
                    guard response == .alertFirstButtonReturn else {
                        onComplete(false, nil)
                        return
                    }
                    
                    do {
                        let r = try self.removeCustomTheme(theme)
                        onComplete(r, nil)
                    } catch {
                        if withErrorMessage {
                            showErrorMessage(error)
                        }
                        onComplete(false, error)
                    }
                }
            } else {
                guard alert.runModal() == .alertFirstButtonReturn else {
                    onComplete(false, nil)
                    return
                }
                do {
                    let r = try self.removeCustomTheme(theme)
                    onComplete(r, nil)
                } catch {
                    if withErrorMessage {
                        showErrorMessage(error)
                    }
                    onComplete(false, error)
                }
            }
        } else {
            do {
                let r = try self.removeCustomTheme(theme)
                onComplete(r, nil)
            } catch {
                if withErrorMessage {
                    showErrorMessage(error)
                }
                
                onComplete(false, error)
            }
        }
    }
    
    /// Import a custom theme in the shared folder and in the list.
    /// - parameters:
    ///   - theme: Theme to import.
    ///   - overwrite: Flag to overwrite an already exists file.
    func importCustomTheme(_ theme: SCSHThemePreview, overwrite: Bool) throws -> Bool {
        guard let themesDir = self.themesDir else {
            return false
        }
                
        if !FileManager.default.fileExists(atPath: themesDir.path) {
            try FileManager.default.createDirectory(at: themesDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let dst = themesDir.appendingPathComponent(theme.name).appendingPathExtension("theme")
        if FileManager.default.fileExists(atPath: dst.path) && !overwrite {
            throw HighlightWrapperError.themeExists(path: dst)
        }
        // Search for a customized theme with the same path.
        let old_theme = self.themes.first { (t) -> Bool in
            return !t.isStandalone && t.path == dst.path
        }
        if let old_theme = old_theme {
            try self.removeCustomTheme(old_theme)
        }
        do {
            try theme.save(to: dst)
            if let old_theme = old_theme {
                self.addCustomTheme(old_theme)
            }
        } catch {
            throw error
        }
        self.addCustomTheme(theme)
    
        return true
    }
    
    func browseToImportCustomTheme() -> SCSHThemePreview? {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.showsTagField = false
        openPanel.allowedFileTypes = ["theme"]
        openPanel.isExtensionHidden = false
        openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = openPanel.runModal()
        
        guard result == .OK, let src = openPanel.url else {
            return nil
        }
        
        var theme: SCSHThemePreview?
        _ = withUnsafeMutablePointer(to: &theme) { (ptr) in
            highlight_get_theme(src.path, ptr) { (context, theme, exit_code) in
                if exit_code == EXIT_SUCCESS, let theme = theme {
                    let t = context?.assumingMemoryBound(to: SCSHTheme.self)
                    t?.pointee = SCSHThemePreview(cTheme: theme.pointee)
                }
            }
        }
        guard theme != nil else {
            let alert = NSAlert()
            alert.messageText = "Invalid file"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return nil
        }
        
        var r = false
        do {
            r = try self.importCustomTheme(theme!, overwrite: false)
        } catch {
            if let e = error as? HighlightWrapperError {
                switch e {
                case .themeExists(let path):
                    let alert = NSAlert()
                    alert.messageText = "A theme already exists with the same file name. \nDo you want to overwrite?"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "No").keyEquivalent = "\u{1b}"
                    alert.addButton(withTitle: "Yes")
                    if alert.runModal() == .alertSecondButtonReturn {
                        do {
                            try FileManager.default.removeItem(at: path)
                            r = try self.importCustomTheme(theme!, overwrite: true)
                        } catch {
                            
                        }
                    } else {
                        return nil
                    }
                }
            }
        }
        guard r else {
            let alert = NSAlert()
            alert.messageText = "Unable to import the theme!"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return nil
        }
        return theme
    }
    
    /// Add a new empty theme.
    /// - Returns: The new empty (unsaved) theme.
    func addNewEmptyTheme() -> SCSHThemePreview? {
        guard let path = self.themesDir else {
            return nil
        }
        
        let customThemes = self.themes.filter { !$0.isStandalone }
        
        let newTheme = SCSHThemePreview(name: UUID().uuidString)
        newTheme.desc = "My custom theme".duplicate(format: "%@ %d", suffixPattern: #" (?<n>\d+)"#, list: customThemes.map({ $0.desc }))
        
        // Add some keywords.
        newTheme.appendKeyword(SCSHTheme.Property())
        newTheme.appendKeyword(SCSHTheme.Property())
        newTheme.appendKeyword(SCSHTheme.Property())
        
        newTheme.path = path.appendingPathComponent(newTheme.name).appendingPathExtension("theme").path
        
        self.addCustomTheme(newTheme)
        return newTheme
    }
    
    /// Duplicate an exists theme.
    /// - parameters:
    ///   - theme: Original theme to doplicate.
    /// - Returns: The duplicated (unsaved) theme.
    func duplicateTheme(theme: SCSHTheme) -> SCSHThemePreview? {
        guard let path = self.themesDir, let newTheme = SCSHThemePreview(dict: theme.toDictionary()) else {
            return nil
        }
        
        // List of current customized theme descriptions.
        var names = self.themes.filter({ !$0.isStandalone}).map({ $0.desc })
        if theme.isStandalone {
            names.append(theme.desc)
        }
        
        newTheme.name = UUID().uuidString
        newTheme.path = path.appendingPathComponent(newTheme.name).appendingPathExtension("theme").path
        newTheme.desc = theme.desc.duplicate(format: "%@ copy %d", suffixPattern: #" +copy +(?<n>\d+)"#, list: names)
        
        self.addCustomTheme(newTheme)
        return newTheme
    }
    
    func saveThemes() throws {
        for theme in themes {
            guard !theme.isStandalone && theme.isDirty else {
                continue
            }
            try theme.save()
            NotificationCenter.default.post(name: .ThemeNeedRefresh, object: theme)
        }
    }
    
    // MARK: -
    
    /// List of all standalone `highlight` plugins.
    lazy fileprivate(set) var plugins: [Plugin] = {
        self.initHighlight()
        
        class Plugins {
            var plugins: [Plugin] = []
        }
        let plugins = Plugins()
        
        let raw = Unmanaged.passUnretained(plugins).toOpaque()
        
        highlight_list_plugins(raw) { (context, p_plugins, n, exit_code) in
            guard exit_code == EXIT_SUCCESS, let c_plugins = p_plugins else {
                return
            }
            let plugins = Unmanaged<Plugins>.fromOpaque(context!).takeUnretainedValue()
            
            for i in 0 ..< Int(n) {
                guard let p = c_plugins.advanced(by: i).pointee?.pointee else {
                    continue
                }
                plugins.plugins.append(Plugin(name: String(cString: p.name), desc: String(cString: p.desc), path: String(cString: p.path)))
            }
        }
        
        return plugins.plugins
    }()
        
    // MARK: -
    fileprivate var _languages: [String: Language]?
    /// List of all `highlight` supported languages.
    lazy fileprivate(set) var languages: [String: Language] = {
        if _languages != nil {
            return _languages!
        }
        
        self.initHighlight()
        
        class Languages {
            var languages: [String: Language] = [:]
        }
        
        let languages = Languages()
        
        let raw = Unmanaged.passUnretained(languages).toOpaque()
        
        highlight_get_supported_languages(raw) { (context, n, lang) in
            let expat = Unmanaged<Languages>.fromOpaque(context!).takeUnretainedValue()
            
            var exts: [String] = []
            for i in 0..<Int(lang.n) {
                if let c_ext = lang.extensions.advanced(by: i).pointee {
                    let ext = String(cString: c_ext)
                    exts.append(ext)
                }
            }
            let l = Language(desc: String(cString: lang.name), extensions: exts)
            expat.languages[l.desc] = l
        }
        
        self._languages = languages.languages
        return languages.languages
    }()
    
    // MARK: -
    /// Check if some extensions are supported by `highlight`.
    /// - parameters:
    ///   - extensions: list of the extensions (without dot prefix).
    /// - returns: The recognized language by `highlight` or `nil`.
    func areSomeSyntaxSupported(extensions: [String]) -> String? {
        for `extension` in extensions {
            if let r = highlight_is_extension_supported(`extension`) {
                defer {
                    r.deallocate()
                }
                return String(cString: r)
            }
        }
        return nil
    }
    
    // MARK: -
    /// Return info about `highlight`.
    func getHighlightInfo() -> String {
        var s = "<h2>Highlight</h2>\n"
        if let about_hl = get_highlight_about() {
            s += String(cString: about_hl).replacingOccurrences(of: "<", with: "&lt;", options: .caseInsensitive, range: nil).replacingOccurrences(of: "\n", with: "<br />\n", options: .caseInsensitive, range: nil)
            about_hl.deallocate()
        }
        s += "<h3>Support folder</h3>\n" + self.getSupportFolder() + "<br />\n"
        
        s += "<h3>Languages</h3>\n"
        s += "<table>\n"
        let languages = self.languages
        let keys = languages.keys.sorted()
        for key in keys {
            let language = languages[key]!
            s += "<tr><td>" + language.desc + "</td><td>." + language.extensions.joined(separator: ", .") + "</td></tr>\n"
        }
        s += "</table>\n"
        
        s += "<h3>Themes</h3>\n"
        s += "<table>\n"
        let themes = self.themes
        for theme in themes {
            s += "<tr><td>" + theme.name + "</td><td>" + theme.desc + "</td></tr>\n"
        }
        s += "</table>\n"
        
        s += "<h3>Plugins</h3>\n"
        s += "<table>\n"
        let plugins = self.plugins
        for plugin in plugins {
            s += "<tr><td>" + plugin.name + "</td><td>" + plugin.desc + "</td></tr>\n"
        }
        s += "</table>\n"
        
        
        s += "<h2>Lua</h2>\n"
        if let about_lua = get_lua_info() {
            s += String(cString: about_lua) + "<br />\n"
        }
        
        return s
    }
}
