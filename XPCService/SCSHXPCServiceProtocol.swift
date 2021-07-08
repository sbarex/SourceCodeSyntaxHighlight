//
//  SCSHXPCServiceProtocol.swift
//  SCSHXPCService
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

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
import Foundation

@objc public protocol SCSHXPCServiceProtocol {
    /// Get settings.
    func getSettings(withReply reply: @escaping (NSDictionary) -> Void)
    /// Set and store the settings.
    func setSettings(_ settings: NSDictionary, reply: @escaping (Bool) -> Void)
    
    func getSettingsURL(reply: @escaping (URL?)->Void)
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    func colorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Settings to use, is nil uses the current settings.
    ///   - data: Data returned by highlight.
    ///   - error: Error returned by the colorize process.
    func colorize(url: URL, settings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    
    /// Colorize a source file returning a formatted html code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    ///   - html: The html output code.l
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func htmlColorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (String, NSDictionary, Error?) -> Void)
    
    /// Colorize a source file returning a formatted html code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Render settings.
    ///   - html: The html output code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func htmlColorize(url: URL,settings: NSDictionary?, withReply reply: @escaping (String, NSDictionary, Error?) -> Void)
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - overrideSettings: List of settings that override the current preferences. Only elements defined inside the dict are overridden.
    ///   - rtfData: Data with the rtf code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func rtfColorize(url: URL, overrideSettings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    
    /// Colorize a source file returning a formatted rtf code.
    /// - parameters:
    ///   - url: Url of source file to format.
    ///   - settings: Render settings.
    ///   - rtfData: Data with the rtf code.
    ///   - settings: Render settings.
    ///   - error: Error returned by the colorize process.
    func rtfColorize(url: URL, settings: NSDictionary?, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
    
    /// Return the url of the themes support folde.
    func getCustomThemesFolder(createIfMissing: Bool, reply: @escaping (URL?)->Void)
    
    /// Update the settings after a theme is deleted.
    /// Any references of deleted theme in the settings are replaced with a default theme.
    /// - parameters:
    ///   - name:
    ///   - reply:
    ///   - changed: True if the settings are changed.
    func updateSettingsAfterThemeDeleted(name: String, withReply reply: @escaping (_ changed: Bool) -> Void)
    func updateSettingsAfterThemeBGChanged(name: String, background: String, withReply reply: @escaping (_ changed: Bool) -> Void)
    /// Return the url of the application support folder that contains themes and custom css styles.
    func getApplicationSupport(reply: @escaping (URL?)->Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

    let connection = NSXPCConnection(serviceName: "org.sbarex.SourceCodeSyntaxHighlight.XPCService")
    connection.remoteObjectInterface = NSXPCInterface(with: SCSHXPCServiceProtocol.self)
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
