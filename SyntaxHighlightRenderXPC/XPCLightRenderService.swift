//
//  XPCLightRenderServiceProtocol.swift
//  SyntaxHighlightRenderXPC
//
//  Created by Sbarex on 26/11/2019.
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

import Foundation
import OSLog
import AppKit

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.

class XPCLightRenderService: SCSHBaseXPCService, XPCLightRenderServiceProtocol {
    lazy var highlightLanguages: [String: [String]] = {
        guard let file = Bundle.main.url(forResource: "languages", withExtension: "json") else {
            print("missing file")
            return [:]
        }
        return (try? type(of: self).parseHighlightLanguages(file: file)) ?? [:]
    }()
    
    func reloadSettings() {
        self.settings = type(of: self).initSettings()
    }
    
    func colorize(url: URL, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        let logFile = self.settings.isDebug ? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop/colorize.log") : URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("colorize.log")
        
        defer {
            if !self.settings.isDebug {
                // Remove the temporary log file.
                try? FileManager.default.removeItem(at: logFile)
            }
        }
        
        do {
            let r = try type(of: self).colorize(url: url, settings: self.settings, highlightBin: self.getEmbeddedHighlight(), dataDir: self.dataDir, rsrcEsc: self.rsrcEsc, dos2unixBin: self.bundle.path(forResource: "dos2unix", ofType: nil), highlightLanguages: self.highlightLanguages, extraCss: self.getGlobalCSS(), overridingSettings: nil, logFile: logFile, logOs: self.log)
            reply(r.data, r.settings.toDictionary() as NSDictionary, nil)
        } catch {
            let custom_settings = SettingsRendering(globalSettings: self.settings, format: nil)
            custom_settings.isError = true
            
            var s = ""
            if settings.format == .html {
                s += "<pre>" + error.localizedDescription + "</pre>\n"
            } else {
                s += error.localizedDescription + "\n"
            }
            if let log = try? String(contentsOf: logFile) {
                if settings.format == .html {
                    s += "<hr />log dump: \n<pre>\(log)</pre>\n"
                } else {
                    s += "\nlog dump: \n\(log)\n"
                }
            }
            
            reply(s.toData(settings: custom_settings), custom_settings.toDictionary() as NSDictionary, nil /* error */)
        }
    }
}
