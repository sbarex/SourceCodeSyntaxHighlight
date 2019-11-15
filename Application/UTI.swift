//
//  UTI.swift
//  Syntax Highlight
//
//  Created by Sbarex on 15/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Cocoa

class UTI: Equatable {
    static func == (lhs: UTI, rhs: UTI) -> Bool {
        return lhs.UTI == rhs.UTI
    }
    
    let UTI: String
    
    lazy var description: String = {
        let type = self.UTI as CFString
        
        if let desc = UTTypeCopyDescription(type)?.takeRetainedValue() {
            return (desc as String).prefix(1).uppercased() + (desc as String).dropFirst()
        } else {
            return ""
        }
    }()
    
    lazy var extensions: [String] = {
        let type = self.UTI as CFString
        
        if let info = UTTypeCopyDeclaration(type)?.takeRetainedValue() as? [String: AnyObject], let specifications = info["UTTypeTagSpecification"] as? [String: AnyObject], let extensions = specifications["public.filename-extension"] {
            if let ext = extensions as? String {
                return [ext]
            } else if let exts = extensions as? [String] {
                return exts
            }
        }
        
        return []
    }()
    
    lazy var mimeTypes: [String] = {
        let type = self.UTI as CFString
        if let info = UTTypeCopyDeclaration(type)?.takeRetainedValue() as? [String: AnyObject], let specifications = info["UTTypeTagSpecification"] as? [String: AnyObject], let mimes = specifications["public.mime-type"] {
            if let m = mimes as? String {
                return [m]
            } else if let m = mimes as? [String] {
                return m
            }
        }
        
        return []
    }()
    
    lazy var icon: NSImage? = {
        return NSWorkspace.shared.icon(forFileType: self.UTI)
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

