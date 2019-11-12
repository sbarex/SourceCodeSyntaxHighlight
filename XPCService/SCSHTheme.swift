//
//  SCSHTheme.swift
//  SCSHXPCService
//
//  Created by sbarex on 18/10/2019.
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

import Foundation

public class SCSHTheme {
    public struct ThemeProperty {
        public let color: String
        public let isBold: Bool
        public let isItalic: Bool
        
        public init() {
            self.init(color: "", isBold: false, isItalic: false)
        }
        
        public init(color: String, isBold: Bool, isItalic: Bool) {
            self.color = color
            self.isBold = isBold
            self.isItalic = isItalic
        }
        
        public init(dict: NSDictionary?) {
            self.init(color: dict?["color"] as? String ?? "", isBold: dict?["bold"] as? Bool ?? false, isItalic:  dict?["italic"] as? Bool ?? false)
        }
        
        public func toDictionary() -> NSDictionary {
            return [
                "color": color,
                "bold": isBold,
                "italic": isItalic
            ]
        }
        
        /// Get CSS inline style attribute for the property.
        func toCssStyle() -> String {
            var css = ""
            if color != "" {
                css += "color: \(color); "
            }
            css += "font-weight: \(isBold ? "bold" : "normal"); "
            css += "font-style: \(isItalic ? "italic" : "normal"); "
            
            return css
        }
    }
    
    public struct ThemeProperties {
        public let defaultProp: ThemeProperty
        public let canvas: ThemeProperty
        public let number: ThemeProperty
        public let escape: ThemeProperty
        public let string: ThemeProperty
        public let blockComment: ThemeProperty
        public let lineComment: ThemeProperty
        
        public let stringPreProc: ThemeProperty
        public let operatorProp: ThemeProperty
        public let lineNum: ThemeProperty
        public let preProcessor: ThemeProperty
        public let interpolation: ThemeProperty

        public let keywords: [ThemeProperty]
        
        public init() {
            self.defaultProp = ThemeProperty()
            self.canvas = ThemeProperty()
            self.number = ThemeProperty()
            self.escape = ThemeProperty()
            self.string = ThemeProperty()
            self.blockComment = ThemeProperty()
            self.lineComment = ThemeProperty()
            self.stringPreProc = ThemeProperty()
            self.operatorProp = ThemeProperty()
            self.lineNum = ThemeProperty()
            self.preProcessor = ThemeProperty()
            self.interpolation = ThemeProperty()
            
            self.keywords = []
        }
        
        public init(defaultProp: ThemeProperty, canvas: ThemeProperty, number: ThemeProperty, escape: ThemeProperty, string: ThemeProperty, blockComment: ThemeProperty, lineComment: ThemeProperty, stringPreProc: ThemeProperty, operatorProp: ThemeProperty, lineNum: ThemeProperty, preProcessor: ThemeProperty, interpolation: ThemeProperty, keywords: [ThemeProperty]) {
            self.defaultProp = defaultProp
            self.canvas = canvas
            self.number = number
            self.escape = escape
            self.string = string
            self.blockComment = blockComment
            self.lineComment = lineComment
            self.stringPreProc = stringPreProc
            self.operatorProp = operatorProp
            self.lineNum = lineNum
            self.preProcessor = preProcessor
            self.interpolation = interpolation
            
            self.keywords = keywords
        }
        
        public init(dict: NSDictionary) {
            self.defaultProp = ThemeProperty(dict: dict["defaultProp"] as? NSDictionary)
            self.canvas = ThemeProperty(dict: dict["canvas"] as? NSDictionary)
            
            self.number = ThemeProperty(dict: dict["number"] as? NSDictionary)
            self.escape = ThemeProperty(dict: dict["escape"] as? NSDictionary)
            self.string = ThemeProperty(dict: dict["string"] as? NSDictionary)
            self.stringPreProc = ThemeProperty(dict: dict["stringPreProc"] as? NSDictionary)
            
            self.blockComment = ThemeProperty(dict: dict["blockComment"] as? NSDictionary)
            self.lineComment = ThemeProperty(dict: dict["lineComment"] as? NSDictionary)
            
            self.operatorProp = ThemeProperty(dict: dict["operatorProp"] as? NSDictionary)
            self.lineNum = ThemeProperty(dict: dict["lineNum"] as? NSDictionary)
            
            self.preProcessor = ThemeProperty(dict: dict["preProcessor"] as? NSDictionary)
            self.interpolation = ThemeProperty(dict: dict["interpolation"] as? NSDictionary)
            
            if let k = dict["keywords"] as? [NSDictionary] {
                self.keywords = k.map({ ThemeProperty(dict: $0) })
            } else {
                self.keywords = []
            }
        }
        
        public func toDictionary() -> NSDictionary {
            return [
                "defaultProp": defaultProp.toDictionary(),
                "canvas": canvas.toDictionary(),
                
                "number": number.toDictionary(),
                "escape": escape.toDictionary(),
                "string": string.toDictionary(),
                "stringPreProc": stringPreProc.toDictionary(),
                
                "blockComment": blockComment.toDictionary(),
                "lineComment": lineComment.toDictionary(),
                
                "operatorProp": operatorProp.toDictionary(),
                "lineNum": lineNum.toDictionary(),
                
                "preProcessor": preProcessor.toDictionary(),
                "interpolation": interpolation.toDictionary(),
                
                "keywords": keywords.map({ $0.toDictionary() })
            ]
        }
    }
    
    public let name: String
    
    public let desc: String
    public let categories: [String]
    public var backgroundColor: String {
        return self.properties.canvas.color
    }
    public let isBase16: Bool
    public let properties: ThemeProperties
    
    /// Full description with the categories.
    public var fullDesc: String {
        var s = desc
        if categories.count > 0 {
            s += " [" + categories.joined(separator: " ") + "]"
        }
        return s
    }
    
    public init(name: String, desc: String, categories: [String], isBase16: Bool, properties: ThemeProperties) {
        self.name = name
        self.desc = desc
        self.categories = categories
        self.isBase16 = isBase16
        self.properties = properties
    }
    
    public init(dict: NSDictionary) {
        name = dict["name"] as? String ?? ""
        desc = dict["desc"] as? String ?? ""
        categories = dict["categories"] as? [String] ?? []
        isBase16 = dict["isBase16"] as? Bool ?? false
        if let p = dict["properties"] as? NSDictionary {
            properties = ThemeProperties(dict: p)
        } else {
            properties = ThemeProperties()
        }
    }
    
    public func toDictionary() -> NSDictionary {
        return [
            "name": name,
            "desc": desc,
            "categories": categories,
            "isBase16": isBase16,
            "properties": properties.toDictionary()
        ]
    }
    
    public func getHtmlExample() -> String {
        return getHtmlExample(fontName: "Menlo", fontSize: 12)
    }
    
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(fontName: String, fontSize: Float) -> String {
        var cssFont = ""
        if fontName != "" {
            cssFont = "font-family: \(fontName); font-size: \(fontSize)pt; "
        }
        
        var keywords = ""
        var i = 1
        for k in self.properties.keywords {
            keywords += "<tr><td colspan='2' style='\(cssFont)\(k.toCssStyle())'>keyword \(i)</td></tr>"
            i += 1
        }
        
        let textColor = properties.defaultProp.toCssStyle()
        return """
<html>
<head>
<style>
html, body {
    background-color: \(self.properties.canvas.color);
    \(cssFont)
    user-select: none;
}
</style>
</head>
<body>
        <table>
        <tr>
            <td style="\(self.properties.defaultProp.toCssStyle())\(cssFont)">standard color</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.defaultProp.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.number.toCssStyle())\(cssFont)">number</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.number.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.string.toCssStyle())\(cssFont)">string</td>
            <td style="\(textColor)\(cssFont)">\(self.properties.string.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.stringPreProc.toCssStyle())\(cssFont)">string pre proc</td>
            <td style="\(textColor)\(cssFont)">\(self.properties.stringPreProc.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.operatorProp.toCssStyle())\(cssFont)">operators</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.operatorProp.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.blockComment.toCssStyle())\(cssFont)">block comment</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.blockComment.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.lineComment.toCssStyle())\(cssFont)">inline comment</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.lineComment.color)</td>
        </tr>
        
        <tr>
            <td style="\(self.properties.escape.toCssStyle())\(cssFont)">escape</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.escape.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.preProcessor.toCssStyle())\(cssFont)">pre processor</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.preProcessor.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.interpolation.toCssStyle())\(cssFont)">interpolation</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.interpolation.color)</td>
        </tr>
        <tr>
            <td style="\(self.properties.lineNum.toCssStyle())\(cssFont)">line number</td>
            <td style="\(cssFont)\(textColor)">\(self.properties.lineNum.color)</td>
        </tr>
        
        \(keywords)
        </table>
</body>
</html>
"""
    }
    
    /// Get a NSAttributedString for preview the theme settings.
    public func getAttributedExample(fontName: String, fontSize: Float) -> NSAttributedString {
        return NSAttributedString(html: getHtmlExample(fontName: fontName, fontSize: fontSize).data(using: .utf8)!, options: [:], documentAttributes: nil)!
    }
}
