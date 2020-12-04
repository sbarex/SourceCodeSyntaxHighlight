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
import Syntax_Highlight_XPC_Service

typealias ExampleItem = (url: URL, title: String, uti: String)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: SCSHXPCServiceProtocol.self)
        connection.resume()
        return connection
    }()
    
    lazy var service: SCSHXPCServiceProtocol? = {
        let service = self.connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? SCSHXPCServiceProtocol
        
        return service
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if #available(OSX 10.12.2, *) {
            NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        self.connection.invalidate()
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
    
    /// Get all handled UTIs.
    func fetchHandledUTIs() -> [UTIDesc] {
        // Get the list of all uti supported by the quicklook extension.
        guard let url = getQLAppexUrl(), let bundle = Bundle(url: url), let extensionInfo = bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any], let attributes = extensionInfo["NSExtensionAttributes"] as? [String: Any], let supportedTypes = attributes["QLSupportedContentTypes"] as? [String] else {
            return []
        }
        
        var fileTypes: [UTIDesc] = []
        for type in supportedTypes {
            let uti = UTIDesc(UTI: type)
            if uti.isValid {
                fileTypes.append(uti)
            } else {
                print("Ignoring `\(type)` uti because it has no mime or file extension associated.")
            }
        }
        
        // Sort alphabetically.
        fileTypes.sort { (a, b) -> Bool in
            return a.description < b.description
        }
        
        return fileTypes
    }
    
    /// Get the list of available source file example.
    func getAvailableExamples() -> [ExampleItem] {
        // Populate the example files list.
        var examples: [ExampleItem] = []
        if let examplesDirURL = Bundle.main.url(forResource: "examples", withExtension: nil) {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(at: examplesDirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for file in files {
                    let title: String
                    if let uti = UTI(URL: file) {
                        title = uti.description + " (." + file.pathExtension + ")"
                        examples.append((url: file, title: title, uti: uti.UTI))
                    } else {
                        title = file.lastPathComponent
                        examples.append((url: file, title: title, uti: ""))
                    }
                    
                }
                examples.sort { (a, b) -> Bool in
                    a.title < b.title
                }
            }
        }
        return examples
    }
    
    @IBAction func openApplicationSupportFolder(_ sender: Any) {
        service?.getApplicationSupport(reply: { (url) in
            if let u = url, FileManager.default.fileExists(atPath: u.path) {
                // Open the Finder to the application support folder.
                NSWorkspace.shared.activateFileViewerSelecting([u])
            } else {
                let alert = NSAlert()
                alert.window.title = "Attention"
                alert.messageText = "The application support folder don't exists."
                alert.addButton(withTitle: "Close")
                alert.alertStyle = .informational
                
                alert.runModal()
            }
        })
    }
}

