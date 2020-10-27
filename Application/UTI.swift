//
//  UTI.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 15/11/2019.
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

class UTI: Equatable {
    static func == (lhs: UTI, rhs: UTI) -> Bool {
        return lhs.UTI == rhs.UTI
    }
    
    let UTI: String
    
    lazy var description: String = {
        let type = self.UTI as CFString
        
        if let desc = UTTypeCopyDescription(type)?.takeRetainedValue() as String? {
            return desc.prefix(1).uppercased() + desc.dropFirst()
        } else {
            return self.UTI
        }
    }()
    
    lazy var extensions: [String] = {
        guard let tags = UTTypeCopyAllTagsWithClass(self.UTI as CFString, kUTTagClassFilenameExtension as CFString)?.takeRetainedValue() else {
            return []
        }
        
        return tags as NSArray as? [String] ?? []
    }()
    
    lazy var conformsTo: [String] = {
        if let info = UTTypeCopyDeclaration(UTI as CFString)?.takeRetainedValue() as? [String: AnyObject] {
            if let c = info[kUTTypeConformsToKey as String] as? String {
                return [c]
            } else if let c = info[kUTTypeConformsToKey as String] as? [String] {
                return c
            }
        }
        return []
    }()
    
    lazy var mimeTypes: [String] = {
        guard let tags = UTTypeCopyAllTagsWithClass(self.UTI as CFString, kUTTagClassMIMEType as CFString)?.takeRetainedValue() else {
            return []
        }
        
        return tags as NSArray as? [String] ?? []
    }()
    
    lazy var icon: NSImage? = {
        return NSWorkspace.shared.icon(forFileType: self.UTI)
    }()
    
    lazy var isDynamic: Bool = {
        return UTTypeIsDynamic(UTI as CFString)
    }()
    
    init(_ UTI: String) {
        self.UTI = UTI
    }
    
    convenience init?(URL url: URL) {
        if let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier {
            self.init(uti)
        } else {
            return nil
        }
    }
}

