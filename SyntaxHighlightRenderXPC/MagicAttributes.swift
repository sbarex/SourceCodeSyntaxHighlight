//
//  MagicAttributes.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 13/10/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

// MARK: -
class MagicAttributes {
    /// Detected file encoding.
    let fileEncoding: CFStringEncoding
    /// Detected mime type.
    let mimeType: String
    
    /// Return if the parsed file is textual.
    lazy var isTextual: Bool = {
        let components = self.mimeType.split(separator: "/")
        if components.count != 2 {
            return false
        } else if components.first?.contains("text") ?? false {
            return true
        } else {
            if let UType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, kUTTypeData)?.takeRetainedValue() {
                return UTTypeConformsTo(UType, kUTTypeText)
            } else {
                return false
            }
        }
    }()
    
    func checkMime(conformTo uttype: CFString) -> Bool {
        if let UType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, kUTTypeData)?.takeRetainedValue() {
            return UTTypeConformsTo(UType, uttype)
        } else {
            return false
        }
    }
    
    /// Return if the parsed file is an image.
    lazy var isImage: Bool = {
        if self.mimeType.hasPrefix("image/") {
            return true
        } else {
            return checkMime(conformTo: kUTTypeImage)
        }
    }()
    /// Return if the parsed file is an image.
    var isPDF: Bool {
        if self.mimeType == "application/pdf" {
            return true
        } else {
            return checkMime(conformTo: kUTTypePDF)
        }
    }
    var isMovie: Bool {
        if self.mimeType.hasPrefix("video/") {
            return true
        } else {
            return checkMime(conformTo: kUTTypeVideo)
        }
    }
    var isAudio: Bool {
        if self.mimeType.hasPrefix("audio/") {
            return true
        } else {
            return checkMime(conformTo: kUTTypeAudio)
        }
    }
    
    init?(url: URL) {
        if url.lastPathComponent == ".DS_Store" {
            // print("Ignore the .DS_Store file.")
            return nil
        }
        
        var magicString = MagicAttributes.getMagicString(forItemAt: url, usingLcALL: "en_US.UTF-8")
        if magicString == nil {
            magicString = MagicAttributes.getMagicString(forItemAt: url, usingLcALL: "C")
        }
        guard let magicString = magicString else {
            return nil
        }
        
        guard let regex = try? NSRegularExpression(pattern: "(\\S+/\\S+); charset=(\\S+)", options: []) else {
            return nil
        }
        
        guard let match = regex.firstMatch(in: magicString, options: [], range: NSRange(magicString.startIndex..., in: magicString)) else {
            return nil
        }
        
        self.mimeType = String(magicString[Range(match.range(at: 1), in: magicString)!])
        
        let charset = String(magicString[Range(match.range(at: 2), in: magicString)!])
        self.fileEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
    }
    
    internal class func getMagicString(forItemAt url: URL, usingLcALL lcALL: String) -> String? {
        let path = url.path
        guard !path.isEmpty else {
            return nil
        }
        var environment = ProcessInfo.processInfo.environment
        environment["LC_ALL"] = lcALL
        
        do {
            let result = try ShellTask.runTask(command: "/usr/bin/file", arguments: ["--mime", "--brief", path], env: environment)
            guard result.exitCode == 0, let stringOutput = result.output() else {
                return nil
            }
            return stringOutput.trimmingCharacters(in: .whitespaces)
        } catch {
            return nil
        }
    }
}
