//
//  SCSHWrapper.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 05/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Service

public class SCSHWrapper: NSObject {
    static let connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: SCSHXPCServiceProtocol.self)
        connection.resume()
        return connection
    }()
    
    static let service: SCSHXPCServiceProtocol? = {
        let service = SCSHWrapper.connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? SCSHXPCServiceProtocol
        
        return service
    }()
    
    static let shared = SCSHWrapper()
    
    /// Global settings.
    fileprivate(set) var settings: Settings?
    
    dynamic var isSettingsLoaded: Bool {
        return self.settings != nil
    }
    
    var isDirty: Bool {
        return settings?.isDirty ?? false
    }
    
    /// Get the list of available source file example.
    var examples: [ExampleItem] {
        get {
            // Populate the example files list.
            var examples: [ExampleItem] = []
            if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                    for file in files {
                        let title: String
                        if let uti = UTI(URL: file) {
                            title = uti.description + " (." + file.pathExtension + ")"
                            examples.append((url: file, title: title, uti: uti.UTI, standalone: true))
                        } else {
                            title = file.lastPathComponent
                            examples.append((url: file, title: title, uti: "", standalone: true))
                        }
                        
                    }
                    examples.sort { (a, b) -> Bool in
                        a.title < b.title
                    }
                }
            }
            return examples
        }
    }
    
    private override init() {
        super.init()
        
        self.reloadSettings(handler: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(afterThemeDeleted(_:)), name: .CustomThemeRemoved, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .CustomThemeRemoved, object: nil)
    }
    
    fileprivate (set) var isSaving = false
    
    func saveSettings(handler: ((Bool)->Void)?) {
        guard let service = SCSHWrapper.service, let settings = self.settings else {
            handler?(false)
            return
        }
        
        isSaving = true
        let s = settings.toDictionary(forSaving: true)
        
        service.setSettings(s as NSDictionary) { state in
            if state {
                self.settings?.isDirty = false
                self.settings?.utiSettings.forEach { (_, format) in
                    format.isDirty = false
                }
            }
            
            self.isSaving = false
            handler?(state)
        }
    }
    
    func reloadSettings(handler: ((SCSHWrapper, Bool) -> Void)?) {
        guard let service = SCSHWrapper.service else {
            handler?(self, false)
            return
        }
        
        service.getSettings() {
            if let s = $0 as? [String: AnyHashable] {
                self.initSettings(from: s)
                handler?(self, true)
            } else {
                handler?(self, false)
            }
        }
    }
    
    internal func initSettings(from settings: [String: AnyHashable]) {
        self.willChangeValue(forKey: "isSettingsLoaded")
        self.settings = Settings(settings: settings)
        
        self.didChangeValue(forKey: "isSettingsLoaded");
        
        print("Settings loaded")
        NotificationCenter.default.post(name: .SettingsAvailable, object: self.settings, userInfo: nil)
    }
    
    func hasCustomizedSettings(forUTI uti: String) -> Bool {
        return self.settings?.hasCustomizedSettings(forUTI: uti) ?? false
    }
    
    func createSettings(forUTI uti: String) -> SettingsFormat? {
        return self.settings?.createSettings(forUTI: uti)
    }
    
    func isThemeUsed(name: String) -> Bool {
        if settings?.lightThemeName == name || settings?.darkThemeName == name {
            return true
        }
        if let _ = settings?.utiSettings.first(where: { ($1.isLightThemeNameDefined && $1.lightThemeName == name) || ($1.isDarkThemeNameDefined && $1.darkThemeName == name) }) {
            return true
        } else {
            return false
        }
    }
    
    func isAdvancedSettingsUsed() -> Bool {
        guard let settings = self.settings else {
            return false
        }
        if settings.hasAdvancedSettings {
            return true
        }
        if let _ = settings.utiSettings.first(where: {$0.value.hasAdvancedSettings}) {
            return true
        }
        
        return false
    }
    
    func render(url: URL, settings: Settings, callback: @escaping ((_ result: Data, _ extra: NSDictionary, _ error: Error?)->Void)) {
        if settings.format == .html {
            SCSHWrapper.service?.htmlColorize(url: url, settings: settings.toDictionary() as NSDictionary) { (html, extra, error) in
                callback(html.data(using: .utf8)!, extra, error)
            }
        } else {
            SCSHWrapper.service?.rtfColorize(url: url, settings: settings.toDictionary() as NSDictionary, withReply: { (data, extra, error) in
                callback(data, extra, error)
            })
        }
    }
    
    
    @objc internal func afterThemeDeleted(_ notification: Notification) {
        guard let theme = notification.object as? SCSHTheme else { return }
        SCSHWrapper.service?.updateSettingsAfterThemeDeleted(name: theme.name) { changed in
            
        }
        
        let name = theme.nameForSettings
        if self.settings?.lightThemeName == name {
            self.settings?.lightThemeName = "edit-xcode"
        }
        if self.settings?.darkThemeName == name {
            self.settings?.lightThemeName = "neon"
        }
        
        self.settings?.utiSettings.forEach({
            if $0.value.lightThemeName == name {
                $0.value.isLightThemeNameDefined = false
                $0.value.lightThemeName = "edit-xcode"
            }
            if $0.value.darkThemeName == name {
                $0.value.isDarkThemeNameDefined = false
                $0.value.lightThemeName = "neon"
            }
        })
    }
    
    func applicationShouldTerminate(notifyTerminate: Bool = true) -> NSApplication.TerminateReply {
        guard !isSaving else {
            return .terminateLater
        }
        guard self.isDirty else {
            return .terminateNow
        }
        let alert = NSAlert()
        alert.messageText = "Save the settings before closing?"
        alert.addButton(withTitle: "Save").keyEquivalent = "\r"
        alert.addButton(withTitle: "Don't Save").keyEquivalent = "d"
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            self.saveSettings(handler: { state in
                if state && notifyTerminate {
                    NSApplication.shared.reply(toApplicationShouldTerminate: state)
                }
            })
            return .terminateLater
        case .alertSecondButtonReturn:
            return .terminateNow
        case .alertThirdButtonReturn:
            return .terminateCancel
        default:
            return .terminateCancel
        }
    }
}
