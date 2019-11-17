//
//  Data+Ext.swift
//  SyntaxHighlight
//
//  Created by sbarex on 21/10/2019.
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

extension Data {
    /// Decode the data returning a string.
    /// - parameters:
    ///   - lossySubstitutionChar: Character used to represent a non-decodable character.
    func decodeToString(lossySubstitutionChar: Character = "\u{FFFD}") -> String {
        var lossy = false
        return self.decodeToString(lossy: &lossy, lossySubstitutionChar: lossySubstitutionChar)
    }
    
    /// Decode the data returning a string.
    /// - parameters:
    ///   - lossy: Is set to true if some characters are omitted because they cannot be decoded.
    ///   - lossySubstitutionChar: Character used to represent a non-decodable character.
    func decodeToString(lossy: inout Bool, lossySubstitutionChar: Character = "\u{FFFD}") -> String {
        lossy = false
        if let t = String(data: self, encoding: String.Encoding.utf8) {
            return t
        } else {
            var encodedString = ""
            var decoder = UTF8()
            var iterator = self.makeIterator()
            var finished: Bool = false
            repeat {
                let decodingResult = decoder.decode(&iterator)
                switch decodingResult {
                case .scalarValue(let char):
                    encodedString.append(String(char))
                case .emptyInput:
                    finished = true
                case .error:
                    lossy = true
                    encodedString.append(lossySubstitutionChar)
                }
            } while (!finished)
            
            return encodedString
        }
    }
}
