//
//  PlainSettings.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 06/11/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

struct PlainSettings {
    let pattern: String
    let isRegExp: Bool
    let isCaseSensitive: Bool
    let UTI: String
    let syntax: String
    
    init(pattern: String, isRegExp: Bool, isCaseInsensitive: Bool, UTI: String, syntax: String) {
        self.pattern = pattern
        self.isRegExp = isRegExp
        self.isCaseSensitive = !isCaseInsensitive
        self.UTI = UTI
        self.syntax = syntax
    }
    
    init?(settings dict: [String: AnyHashable]) {
        guard let pattern = dict["pattern"] as? String, let uti = dict["uti"] as? String, let syntax = dict["syntax"] as? String, let re = dict["re"] as? Int, let cs = dict["cs"] as? Int else {
            return nil
        }
        self.pattern = pattern
        self.UTI = uti
        self.syntax = syntax
        self.isRegExp = re == 1
        self.isCaseSensitive = cs == 1
    }
    
    func toDictionary(forSaving: Bool) -> [String: AnyHashable] {
        return [
            "pattern": self.pattern,
            "uti": self.UTI,
            "syntax": self.syntax,
            "re": self.isRegExp ? 1 : 0,
            "cs": self.isCaseSensitive ? 1 : 0
        ]
    }
    
    func test(filename: String) -> Bool {
        let n1 = self.isCaseSensitive ? filename : filename.lowercased()
        let pattern = self.isCaseSensitive ? self.pattern : self.pattern.lowercased()
        if self.isRegExp {
            var options: NSRegularExpression.Options = []
            if !self.isCaseSensitive {
                options.insert(.caseInsensitive)
            }
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                return false
            }
            return regex.firstMatch(in: n1, options: [], range: NSRange(n1.startIndex..., in: n1)) != nil
        } else {
            return n1 == pattern
        }
    }
}

extension PlainSettings: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return
            lhs.pattern == rhs.pattern &&
            lhs.UTI == rhs.UTI &&
            lhs.syntax == rhs.syntax &&
            lhs.isRegExp == rhs.isRegExp &&
            lhs.isCaseSensitive == rhs.isCaseSensitive
    }
}
