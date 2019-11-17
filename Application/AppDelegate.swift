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
    
    private var firstAppear = false
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        firstAppear = true
        
        // Debug constraints.
        // UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        // Or put -NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints YES on the launch arguments
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        self.connection.invalidate()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if firstAppear && NSApplication.shared.windows.count == 0, let menu = NSApp.menu?.item(at: 0)?.submenu?.item(withTag: 100), let a = menu.action {
            NSApp.sendAction(a, to: menu.target, from: menu)
        }
        firstAppear = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
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
                print("Ignoring \(type) uti.")
            }
        }
        
        // Sort alphabetically.
        fileTypes.sort { (a, b) -> Bool in
            return a.description < b.description
        }
        
        return fileTypes
    }
}

