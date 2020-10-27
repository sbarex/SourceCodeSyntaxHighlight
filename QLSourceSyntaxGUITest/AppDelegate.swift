//
//  AppDelegate.swift
//  QLSourceSyntaxGUITest
//
//  Created by Sbarex on 23/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import Syntax_Highlight_XPC_Render
import Syntax_Highlight_XPC_Render
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCService")
        connection.remoteObjectInterface = NSXPCInterface(with: SCSHXPCServiceProtocol.self)
        connection.resume()
        return connection
    }()
    
    lazy var service: XPCLightRenderService? = {
        let service = self.connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? SCSHXPCServiceProtocol
        
        return service
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

