//
//  String+ext.swift
//  Syntax Highlight XPC Service
//
//  Created by Sbarex on 21/11/2019.
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

extension String {
    /// Return a duplicate of the value with a suffix.
    /// - parameters:
    ///   - format: Template to output the duplicated values. Must contain _%s_ placeholder for he value, and a _%d_ for the number of copy.
    ///   - suffixPattern: Pattern used to extract the suffix and number from item in list. Must be contain a capture group named _n_ for extract the number of the copy.
    ///   - list: List of values.
    func duplicate(format: String = "%@ copy %d", suffixPattern: String = #"\s+copy\s+(?<n>\d+)"#, list: [String]) -> String {
        let string: String
        
        let regex1 = try! NSRegularExpression(pattern: #"(?<base>.+)\#(suffixPattern)$"#, options: [.caseInsensitive])
        let nsrange = NSRange(self.startIndex..<self.endIndex, in: self)
        if let match = regex1.firstMatch(in: self, options: [], range: nsrange) {
            let firstCaptureRange = Range(match.range(withName: "base"), in: self)!
            string = String(self[firstCaptureRange])
        } else {
            string = self
        }
        
        var n = 0
        let regex = try! NSRegularExpression(pattern: "^\(string)\(suffixPattern)$", options: [.caseInsensitive])
        list.forEach { (s) in
            let nsrange = NSRange(s.startIndex..<s.endIndex, in: s)
            if let match = regex.firstMatch(in: s, options: [], range: nsrange) {
                let nn: Int
                if let firstCaptureRange = Range(match.range(withName: "n"), in: s), let n1 = Int(s[firstCaptureRange]) {
                    nn = n1
                } else {
                    nn = 1
                }
                n = max(n, nn)
            }
        }
        
        let s = String(format: format, string, n+1)
        return s
    }
}
