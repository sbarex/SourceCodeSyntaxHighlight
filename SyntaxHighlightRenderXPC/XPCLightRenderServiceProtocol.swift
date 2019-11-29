//
//  SyntaxHighlightRenderXPCProtocol.swift
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

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
import Foundation

@objc public protocol XPCLightRenderServiceProtocol {
    func colorize(url: URL, withReply reply: @escaping (Data, NSDictionary, Error?) -> Void)
}
