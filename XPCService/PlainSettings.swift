//
//  PlainSettings.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 06/11/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

struct PlainSettings {
    let patternFile: String
    let patternMime: String
    let isRegExp: Bool
    let isCaseSensitive: Bool
    let UTI: String
    let syntax: String
    
    var fileRegExp: NSRegularExpression? {
        guard isRegExp, !self.patternFile.isEmpty else {
            return nil
        }
        var options: NSRegularExpression.Options = []
        if !self.isCaseSensitive {
            options.insert(.caseInsensitive)
        }
        return try? NSRegularExpression(pattern: self.patternFile, options: options)
    }
    var mimeRegExp: NSRegularExpression? {
        guard isRegExp, !self.patternMime.isEmpty else {
            return nil
        }
        var options: NSRegularExpression.Options = []
        if !self.isCaseSensitive {
            options.insert(.caseInsensitive)
        }
        return try? NSRegularExpression(pattern: self.patternMime, options: options)
    }
    
    init(patternFile: String, patternMime: String, isRegExp: Bool, isCaseInsensitive: Bool, UTI: String, syntax: String) {
        self.patternFile = patternFile
        self.patternMime = patternMime
        self.isRegExp = isRegExp
        self.isCaseSensitive = !isCaseInsensitive
        self.UTI = UTI
        self.syntax = syntax
    }
    
    init?(settings dict: [String: AnyHashable]) {
        guard let patternFile = dict["pattern"] as? String, let uti = dict["uti"] as? String, let syntax = dict["syntax"] as? String, let re = dict["re"] as? Int, let cs = dict["cs"] as? Int else {
            return nil
        }
        self.patternFile = patternFile
        self.patternMime = dict["mime"] as? String ?? ""
        self.UTI = uti
        self.syntax = syntax
        self.isRegExp = re == 1
        self.isCaseSensitive = cs == 1
    }
    
    func toDictionary(forSaving: Bool) -> [String: AnyHashable] {
        return [
            "pattern": self.patternFile,
            "mime": self.patternMime,
            "uti": self.UTI,
            "syntax": self.syntax,
            "re": self.isRegExp ? 1 : 0,
            "cs": self.isCaseSensitive ? 1 : 0
        ]
    }
    
    func test(filename: String, mimeType: String?) -> Bool {
        var valid = false
        if self.isRegExp {
            if !self.patternFile.isEmpty {
                guard let regex = self.fileRegExp else {
                    return false
                }
                guard regex.firstMatch(in: filename, options: [], range: NSRange(filename.startIndex..., in: filename)) != nil else {
                    return false
                }
                valid = true
            }
            if let mimeType = mimeType, !self.patternMime.isEmpty {
                guard let regex = self.mimeRegExp else {
                    return false
                }
                guard regex.firstMatch(in: mimeType, options: [], range: NSRange(filename.startIndex..., in: filename)) != nil else {
                    return false
                }
                valid = true
            }
        } else {
            let filename = self.isCaseSensitive ? filename : filename.lowercased()
            let patternFile = self.isCaseSensitive ? self.patternFile : self.patternFile.lowercased()
            let patternMime = self.isCaseSensitive ? self.patternMime : self.patternMime.lowercased()
            
            if !patternFile.isEmpty && filename != patternFile {
                return false
            }
            guard !patternMime.isEmpty, let mime = self.isCaseSensitive ? mimeType?.lowercased() : mimeType, mime == patternMime else {
                return false
            }
            valid = true
        }
        return valid
    }
}

extension PlainSettings: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return
            lhs.patternFile == rhs.patternFile &&
            lhs.patternMime == rhs.patternMime &&
            lhs.UTI == rhs.UTI &&
            lhs.syntax == rhs.syntax &&
            lhs.isRegExp == rhs.isRegExp &&
            lhs.isCaseSensitive == rhs.isCaseSensitive
    }
}
