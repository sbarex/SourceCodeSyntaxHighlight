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
import UniformTypeIdentifiers

class UTI: Equatable {
    typealias SuppressedExtension = (ext: String, uti: String)
    
    static func == (lhs: UTI, rhs: UTI) -> Bool {
        return lhs.UTI == rhs.UTI
    }
    
    let UTI: String
    
    lazy var description: String = {
        let type = self.UTI as CFString
        
        if #available(macOS 11.0, *) {
            if let desc = UTType(self.UTI)?.description, !desc.isEmpty {
                return desc.prefix(1).uppercased() + desc.dropFirst()
            } else {
                return self.UTI
            }
        } else {
            if let desc = UTTypeCopyDescription(type)?.takeRetainedValue() as String?, !desc.isEmpty {
                return desc.prefix(1).uppercased() + desc.dropFirst()
            } else {
                return self.UTI
            }
            // Fallback on earlier versions
        }
    }()
    
    /// Full description with supported extensions.
    lazy var fullDescription: String = {
        var label: String = self.description
        let exts = self.extensions
        if exts.count > 0 {
            label += " (." + exts.joined(separator: ", .") + ")"
        }
        return label
    }()
    
    lazy var extensions: [String] = {
        if #available(macOS 11.0, *) {
            return UTType(self.UTI)?.tags[UTTagClass.filenameExtension] ?? []
        } else {
            guard let tags = UTTypeCopyAllTagsWithClass(self.UTI as CFString, kUTTagClassFilenameExtension as CFString)?.takeRetainedValue() else {
                return []
            }
            return tags as NSArray as? [String] ?? []
        }
    }()
    
    lazy var suppressedExtensions: [SuppressedExtension] = {
        var e: [SuppressedExtension] = []
        for ext in extensions {
            if #available(macOS 11.0, *) {
                if let u = UTType(filenameExtension: ext) {
                    if u.identifier != self.UTI {
                        e.append((ext: ext, uti: u.identifier as String))
                    }
                }
            } else {
                if let u = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() {
                    if u as String != self.UTI {
                        e.append((ext: ext, uti: u as String))
                    }
                }
            }
        }
        return e
    }()
    
    var isSuppressed: Bool {
        return self.extensions.count > 0 && self.suppressedExtensions.count == self.extensions.count
    }
    
    lazy var conformsTo: [String] = {
        if #available(macOS 12.0, *) {
            return UTType(UTI)?.supertypes.map { $0.identifier } ?? []
        } else {
            if let info = UTTypeCopyDeclaration(UTI as CFString)?.takeRetainedValue() as? [String: AnyObject] {
                if let c = info[kUTTypeConformsToKey as String] as? String {
                    return [c]
                } else if let c = info[kUTTypeConformsToKey as String] as? [String] {
                    return c
                }
            }
            return []
        }
    }()
    
    lazy var mimeTypes: [String] = {
        if #available(macOS 12.0, *) {
            if let t = UTType(self.UTI) {
                return t.tags[.mimeType] ?? []
            } else {
                return []
            }
        } else {
            guard let tags = UTTypeCopyAllTagsWithClass(self.UTI as CFString, kUTTagClassMIMEType as CFString)?.takeRetainedValue() else {
                return []
            }
            
            return tags as NSArray as? [String] ?? []
        }
    }()
    
    fileprivate var _image_fetched = false
    fileprivate var _image: NSImage?
    
    var isImageFetched: Bool {
        return _image_fetched
    }
    
    var image: NSImage? {
        return _image
    }
    
    func fetchIcon(async: Bool = true) {
        if #available(macOS 11.0, *) {
            guard !_image_fetched, let uti = UTType(self.UTI) else {
                return
            }
            if async {
                DispatchQueue.global(qos: .userInitiated).async() {
                    self._image = NSWorkspace.shared.icon(for: uti)
                    self._image_fetched = true
                }
            } else {
                _image = NSWorkspace.shared.icon(for: uti)
                _image_fetched = true
            }
        } else {
            // FIXME: On Catalina NSWorkspace.shared.icon freeze the app!
        }
    }
    
    lazy var isDynamic: Bool = {
        if #available(macOS 12.0, *) {
            if let u = UTType(UTI) {
                return u.isDynamic
            } else {
                return false
            }
        } else {
            return UTTypeIsDynamic(UTI as CFString)
        }
    }()
    
    /// Return if the system know the file extensions or mime types for the UTI.
    lazy var isValid: Bool = {
        if UTI.hasPrefix("public.") {
            return true
        }
        return mimeTypes.count > 0 || extensions.count > 0
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
    
    func getSuppressedExtensions(handledUti: [String]) -> [(suppress: SuppressedExtension, handled: Bool)] {
        var e: [(suppress: SuppressedExtension, handled: Bool)] = []
        for suppress in suppressedExtensions {
            e.append((suppress: suppress, handled: handledUti.contains(suppress.uti)))
        }
        return e
    }
    
    func initLazyVars(async: Bool = true) {
        let initVars = { () in
            _ = self.description
            _ = self.fullDescription
            _ = self.extensions
            _ = self.suppressedExtensions
            _ = self.isDynamic
            _ = self.isValid
        }
        
        if async {
            DispatchQueue.global(qos: .userInitiated).async() {
                initVars()
            }
        } else {
            initVars()
        }
    }
}

