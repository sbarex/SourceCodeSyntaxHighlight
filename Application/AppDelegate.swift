//
//  AppDelegate.swift
//  SyntaxHighlight
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

import Cocoa
import Sparkle
import Syntax_Highlight_XPC_Service

typealias ExampleItem = (url: URL, title: String, uti: String, standalone: Bool)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    @IBOutlet weak var advancedSettingsMenu: NSMenuItem!
    
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?
    
    var isAdvancedSettingsVisible: Bool = false {
        didSet {
            advancedSettingsMenu.state = isAdvancedSettingsVisible ? .on : .off
            
            guard oldValue != isAdvancedSettingsVisible else {
                return
            }
            UserDefaults.standard.setValue(isAdvancedSettingsVisible, forKey: "advanced-settings")
            NotificationCenter.default.post(name: .AdvancedSettings, object: isAdvancedSettingsVisible)
        }
    }
    
    @IBAction func handleAdvancedSettings(_ sender: Any) {
        isAdvancedSettingsVisible = !isAdvancedSettingsVisible
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return SCSHWrapper.shared.applicationShouldTerminate()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let utis = handledUTIs
        DispatchQueue.global(qos: .userInitiated).async() {
            for uti in utis {
                uti.initLazyVars(async: false)
                uti.fetchIcon(async: false)
            }
        }
        
        // Insert code here to initialize your application
        if #available(macOS 10.12.2, *) {
            NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
        
        if let state = UserDefaults.standard.object(forKey: "advanced-settings") as? Bool {
            isAdvancedSettingsVisible = state
        } else {
            isAdvancedSettingsVisible = false
        }
        
        let hostBundle = Bundle.main
        let applicationBundle = hostBundle;
        
        self.userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        self.updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: applicationBundle, userDriver: self.userDriver!, delegate: nil)
        
        do {
            try self.updater!.start()
        } catch {
            print("Failed to start updater with error: \(error)")
            
            let alert = NSAlert()
            alert.messageText = "Updater Error"
            alert.informativeText = "The Updater failed to start. For detailed error information, check the Console.app log."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func checkForUpdates(_ sender: Any)
    {
        self.updater?.checkForUpdates()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.action == #selector(self.checkForUpdates(_:)) {
            return self.updater?.canCheckForUpdates ?? false
        }
        if menuItem.identifier?.rawValue == "revert", let settings = SCSHWrapper.shared.settings {
            return settings.isDirty
        }
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        SCSHWrapper.connection.invalidate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    /// Get the url of the quicklook extension.
    func getQLAppexUrl() -> URL? {
        guard let base_url = Bundle.main.builtInPlugInsURL else {
            return nil
        }
        do {
            for url in try FileManager.default.contentsOfDirectory(at: base_url, includingPropertiesForKeys: nil, options: []) {
                // Suppose only one appex on the plugin dir.
                if url.pathExtension == "appex" {
                    return url
                }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    lazy var handledUTIs: [UTI] = {
        // Get the list of all uti supported by the quicklook extension.
        guard let url = getQLAppexUrl(), let bundle = Bundle(url: url), let extensionInfo = bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any], let attributes = extensionInfo["NSExtensionAttributes"] as? [String: Any], let supportedTypes = attributes["QLSupportedContentTypes"] as? [String] else {
            return []
        }
        
        var fileTypes: [UTI] = []
        for type in supportedTypes {
            guard !Settings.plainUTIs.contains(type) else {
                continue
            }
            let uti = UTI(type)
            if uti.isValid {
                fileTypes.append(uti)
            } else {
                print("Ignoring `\(type)` uti because it has no mime or file extension associated.")
            }
        }
        
        // Sort alphabetically.
        fileTypes.sort { (a, b) -> Bool in
            return a.description.lowercased() < b.description.lowercased()
        }
        
        return fileTypes
    }()
    
    fileprivate var allExamples: [ExampleItem]?
    /// Get the list of available source file example.
    func getAvailableExamples() -> [ExampleItem] {
        if let allExamples = self.allExamples {
            return allExamples
        }
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
        self.allExamples = examples
        return examples
    }
    
    @IBAction func openApplicationSupportFolder(_ sender: Any) {
        SCSHWrapper.service?.getApplicationSupport(reply: { (url) in
            if let u = url, FileManager.default.fileExists(atPath: u.path) {
                // Open the Finder to the application support folder.
                NSWorkspace.shared.activateFileViewerSelecting([u])
            } else {
                let alert = NSAlert()
                alert.window.title = "Attention"
                alert.messageText = "Application support folder does not exist"
                alert.informativeText = "You probably haven't created any custom themes or style sheets yet."
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .informational
                
                alert.runModal()
            }
        })
    }
    
    @IBAction func selectSettingsFile(_ sender: Any) {
        SCSHWrapper.service?.getSettingsURL(reply: { (url) in
            if let u = url, FileManager.default.fileExists(atPath: u.path) {
                // Open the Finder to the settings file.
                NSWorkspace.shared.activateFileViewerSelecting([u])
            } else {
                let alert = NSAlert()
                alert.window.title = "Attention"
                alert.messageText = "Settings not found"
                alert.informativeText = "You probably haven't customize the standard settings."
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .informational
                
                alert.runModal()
            }
        })
    }
    
    class func initSyntaxPopup(_ popupButton: NSPopUpButton?, availableSyntax: [String: HighlightWrapper.Language], extraItems extra: [String] = []) {
        guard let popupButton = popupButton else {
            return
        }
        popupButton.removeAllItems()
        for item in extra {
            popupButton.addItem(withTitle: item)
        }
        
        guard availableSyntax.count > 0 else {
            return
        }
        if !extra.isEmpty {
            popupButton.menu?.addItem(NSMenuItem.separator())
        }
        let keys = availableSyntax.keys.sorted{$0.compare($1, options: .caseInsensitive) == .orderedAscending }
        for desc in keys {
            let m = NSMenuItem(title: desc, action: nil, keyEquivalent: "")
            m.toolTip = desc
            if let lang = availableSyntax[desc] {
                m.toolTip! += " [." + lang.extensions.joined(separator: ", .") + "]"
            }
            popupButton.menu?.addItem(m)
        }
    }
    
    @IBAction func installCLITool(_ sender: Any) {
        guard let app = Bundle.main.url(forResource: "syntax_highlight_cli", withExtension: nil) else {
            return
        }
        let alert = NSAlert()
        let path = "/usr/local/bin/syntax_highlight_cli"
        if FileManager.default.fileExists(atPath: path) {
            alert.messageText = "The Command line tool already exists on the `/usr/local/bin/` folder."
            alert.alertStyle = .informational
        } else {
            do {
                try FileManager.default.createSymbolicLink(at: URL(fileURLWithPath: path), withDestinationURL: app)
                alert.messageText = "Command line tool installed on `\(path)`"
                alert.alertStyle = .informational
            } catch {
                alert.messageText = "Unable to link the command line tool link into `\(path)`!"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
            }
        }
        alert.runModal()
    }
    
    @IBAction func revealCLITool(_ sender: Any) {
        let u = URL(fileURLWithPath: "/usr/local/bin/syntax_highlight_cli")
        if FileManager.default.fileExists(atPath: u.path) {
            // Open the Finder to the settings file.
            NSWorkspace.shared.activateFileViewerSelecting([u])
        } else {
            let alert = NSAlert()
            alert.messageText = "The command line tool is not installed!"
            alert.alertStyle = .informational
            
            alert.runModal()
        }
    }
}

