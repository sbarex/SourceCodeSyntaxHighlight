//
//  XPCServiceProtocol.swift
//  XPCService
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of QLExt.
//  QLExt is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  QLExt is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with QLExt. If not, see <http://www.gnu.org/licenses/>.

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
import Foundation

@objc public protocol XPCServiceProtocol {
    var XPCDomain: String { get }
    
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void)
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void)
    
    func colorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    func htmlColorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (String, NSDictionary, Error?) -> Void)
    func rtfColorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    
    func getThemes(withReply reply: @escaping ([NSDictionary], Error?) -> Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

    let connection = NSXPCConnection(serviceName: "sbarex.XPCService")
    connection.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
    connection.resume()

Once you have a connection to the service, you can use it like this:

    service = connection.remoteObjectProxyWithErrorHandler({ error in
        print("Received error:", error)
    }) as? XPCServiceProtocol
    service?.upperCaseString("hello") { aString in
        // We have received a response. Update our text field, but do it on the main thread.
        print("Result string was: \(aString)")
    }

 And, when you are finished with the service, clean up the connection like this:

     connection.invalidate()
*/
