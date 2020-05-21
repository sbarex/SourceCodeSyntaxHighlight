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
    
    /// Get the list of available themes.
    /// - parameters:
    ///   - themes: Array of themes exported as a dictionary [String: Any].
    ///   - error: Error during the extraction of the themes.
    func getThemes(withReply reply: @escaping ([NSDictionary], Error?) -> Void)
    
    /// Get the list of available themes.
    /// - parameters:
    ///   - highlightPath: Path of highlight. If empty or "-" use the embedded highlight.
    ///   - reply: Callback.
    ///   - themes: Array of themes exported as a dictionary [String: Any].
    ///   - error: Error during the extraction of the themes.
    func getThemes(highlight path: String, withReply reply: @escaping ([NSDictionary], Error?) -> Void)
    
    /// Save a custom theme to a file.
    /// The file is located inside the application support directory, with the name of the theme.
    /// If the theme had previously been saved with a different name, it is registered with the new name and the old file deleted.
    /// An existing file will be overwritten.
    /// When renaming a theme will be search if the old name is used in the settings and then updated.
    /// - parameters:
    ///   - theme: Theme exported as dictionary.
    ///   - success: True if the theme is correctly saved.
    ///   - error: Error on saving operation.
    func saveTheme(_ theme: NSDictionary, withReply reply: @escaping (Bool, Error?) -> Void)
    
    /// Delete a custom theme.
    /// Any references of deleted theme in the settings are replaced with a default theme.
    /// - parameters:
    ///   - name: Name of the theme. Is equal to the file name.
    ///   - success: True if the theme is correctly deleted.
    ///   - error: Error on deleting operation.
    func deleteTheme(name: String, withReply reply: @escaping (Bool, Error?) -> Void)
    
    /// Get a custom CSS style for a UTI.
    /// - parameters:
    ///   - uti: UTI associated to the style. Il empty is search the global style for all files.
    ///   - style: Custom CSS style.
    ///   - error: Error on saving file.
    func getCustomStyleForUTI(uti: String, reply: @escaping (String, Error?) -> Void)
    
    /// Save a custom style for a uti to a file.
    /// - parameters:
    ///   - style: CSS style.
    ///   - uti: UTI associated to the style. Il empty is used for all files.
    ///   - success: True if file is saved correctly.
    ///   - error: Error on saving file.
    func setCustomStyle(_ style: String, forUTI uti: String, reply: @escaping (Bool, Error?) -> Void)
    
    /// Return the url of the application support folder that contains themes and custom css styles.
    func getApplicationSupport(reply: @escaping (URL?)->Void)
    
    func locateHighlight(reply: @escaping ([[Any]]) -> Void)
    /// Return info about highlight.
    /// - parameters:
    ///   - highlight: Path of highlight. Empty or "-" for use the embedded version.
    func highlightInfo(highlight: String, reply: @escaping (String) -> Void)
    func highlightInfo(reply: @escaping (String) -> Void)
    
    /// Get all syntax format supported by highlight.
    /// Returns a dictionary, with on the keys the description of the syntax format, and on values an array of recognized extensions.
    /// - parameters:
    ///   - highlight: Path of highlight. Empty or "-" for use the embedded version.
    func highlightAvailableSyntax(highlight: String, reply: @escaping (NSDictionary) -> Void)
    func highlightAvailableSyntax(reply: @escaping (NSDictionary) -> Void)
    
    /// Check if a file extension is handled by highlight.
    func isSyntaxSupported(_ syntax: String, overrideSettings: NSDictionary?, reply: @escaping (Bool) -> Void)
    
    /// Check if some of specified file extensions are handled by highlight.
    func areSomeSyntaxSupported(_ syntax: [String], overrideSettings: NSDictionary?, reply: @escaping (Bool) ->Void)
    
    func getXPCPath(replay: @escaping (URL)->Void)
    
    // func registerUTI(_ uti: String, result: @escaping (Bool)->Void )
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
