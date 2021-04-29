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

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.

class XPCLightRenderService: SCSHBaseXPCService, XPCLightRenderServiceProtocol {
    func reloadSettings() {
        self.settings = type(of: self).initSettings()
    }
    
    func colorize(url: URL, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void) {
        let custom_settings: SettingsRendering
        
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            let utiSettings = self.settings.utiSettings[uti] ?? self.settings.createSettings(forUTI: uti)
            
            if !utiSettings.isSpecialSettingsPopulated {
                utiSettings.populateSpecialSettings(supportFolder: type(of: self).applicationSupportUrl, serviceBundle: type(of: self).serviceBundle)
            }
            if !utiSettings.isCSSPopulated, let dir = type(of: self).getCustomStylesUrl(createIfMissing: false) {
                utiSettings.populateCSS(fromFolder: dir)
            }
            
            custom_settings = SettingsRendering(globalSettings: self.settings, format: utiSettings)
        } else {
            custom_settings = SettingsRendering(globalSettings: self.settings, format: nil)
        }
        
        do {
            let result = try doColorize(url: url, custom_settings: custom_settings)
            reply(result.result.data, result.settings as NSDictionary, nil)
        } catch {
            reply(error.localizedDescription.data(using: String.Encoding.utf8)!, custom_settings.toDictionary() as NSDictionary, error)
        }
    }
}
