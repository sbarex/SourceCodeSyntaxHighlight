//
//  AppDelegate.swift
//  QLExt
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

import Cocoa
import XPCService

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "sbarex.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
        connection.resume()
        return connection
    }()
    
    lazy var service: XPCServiceProtocol? = {
        let service = self.connection.remoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? XPCServiceProtocol
        
        return service
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        self.connection.invalidate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

