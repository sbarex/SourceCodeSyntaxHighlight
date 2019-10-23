//
//  Theme.swift
//  XPCService
//
//  Created by sbarex on 18/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of QLExt.
//  QLExt is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  QLExt is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with QLExt. If not, see <http://www.gnu.org/licenses/>.

import Foundation

class Theme {
    let name: String
    
    let desc: String
    let categories: [String]
    let backgroundColor: String
    let isBase16: Bool
    
    init (url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        
        var categories: [String] = []
        var bgcolor: String = "#ffffff"
        var desc = ""
        var base16 = false
        
        if let data = try? String(contentsOfFile: url.path, encoding: .utf8) {
            let lines = data.components(separatedBy: .newlines)
            var desc_found = false
            var categories_found = false
            var bg_found = false
            
            let regex_categories = try! NSRegularExpression(pattern: #"^Categories\s*=\s*\{(.+)\}"#, options: [])
            let regex_desc = try! NSRegularExpression(pattern: #"^Description\s*=\s*"([^"]+)""#, options: [])
            let regex_bg1 = try! NSRegularExpression(pattern: #"^Canvas\s*=\s*\{\s*Colour\s*=\s*"(#[0-9a-fA-F]{6})"\s*\}"#, options: [])
            let regex_bg2 = try! NSRegularExpression(pattern: #"^base00\s*=\s*"(#[0-9a-fA-F]{6})""#, options: [])
            
            for line in lines {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if !categories_found, let match = regex_categories.firstMatch(in: line, options: [], range: range) {
                    let firstCaptureRange = Range(match.range(at: 1), in: line)!
                    categories = line[firstCaptureRange].components(separatedBy: ", ").map({ $0.trimmingCharacters(in: CharacterSet(charactersIn: "\""))})
                    categories_found = true
                } else if !desc_found, let match = regex_desc.firstMatch(in: line, options: [], range: range) {
                    let firstCaptureRange = Range(match.range(at: 1), in: line)!
                    desc = String(line[firstCaptureRange])
                    desc_found = true
                } else if !bg_found, let match = regex_bg1.firstMatch(in: line, options: [], range: range) {
                    let firstCaptureRange = Range(match.range(at: 1), in: line)!
                    bgcolor = String(line[firstCaptureRange])
                    bg_found = true
                    base16 = false
                } else if !bg_found, let match = regex_bg2.firstMatch(in: line, options: [], range: range) {
                    let firstCaptureRange = Range(match.range(at: 1), in: line)!
                    bgcolor = String(line[firstCaptureRange])
                    bg_found = true
                    base16 = true
                }
                if categories_found && bg_found && desc_found {
                    break;
                }
            }
            /*
            if !bg_found {
                print("err")
            }
            */
        }
        
        self.desc = desc
        self.categories = categories
        self.backgroundColor = bgcolor
        self.isBase16 = base16
    }
}
