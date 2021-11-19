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

import Cocoa

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
    
    // MARK: -
    /// Format the string.
    /// - parameters:
    ///    - format: Output format.
    ///    - fgColor: Text color.
    ///    - bgColor: Background color.
    ///    - font: Font name.
    ///    - fontSize: Font size.
    /// - returns: The formatted data.
    func toData(format: Settings.Format, fgColor: String? = nil, bgColor: String? = nil, font: String? = nil, fontSize: CGFloat? = nil, css: String = "") -> Data {
        return String.stringToFormattedData(self, format: format, fgColor: fgColor, bgColor: bgColor, font: font, fontSize: fontSize, css: css)
    }
    func toData(settings: SettingsRendering, cssFile: URL? = nil) -> Data {
        let colors = settings.getTheme()
        var css = settings.css
        if let file = cssFile, let s = try? String(contentsOf: file) {
            css = s + css
        }
        return String.stringToFormattedData(self, format: settings.format, fgColor: colors.foreground, bgColor: colors.background, font: settings.fontName, fontSize: settings.fontSize, css: css)
    }
    
    func toHTML(fgColor: String? = nil, bgColor: String? = nil, font: String? = nil, fontSize: CGFloat? = nil, css: String = "") -> String {
        let data = self.toData(format: .html, fgColor: fgColor, bgColor: bgColor, font: font, fontSize: fontSize, css: css)
        return String(data: data, encoding: .utf8)!
    }
    func toHTML(settings: SettingsRendering, cssFile: URL? = nil) -> String {
        let colors = settings.getTheme()
        var css = settings.css
        if let file = cssFile, let s = try? String(contentsOf: file) {
            css = s + css
        }
        return toHTML(fgColor: colors.foreground, bgColor: colors.background, font: settings.fontName, fontSize: settings.fontSize, css: css)
    }
    
    func toRTF(fgColor: String? = nil, bgColor: String? = nil, font: String? = nil, fontSize: CGFloat? = nil) -> Data {
        let data = String.stringToFormattedData(self, format: .rtf, fgColor: fgColor, bgColor: bgColor, font: font, fontSize: fontSize)
        return data
    }
    func toRTF(fgColor: String? = nil, bgColor: String? = nil, font: String? = nil, fontSize: CGFloat? = nil) -> NSAttributedString? {
        let data = String.stringToFormattedData(self, format: .rtf, fgColor: fgColor, bgColor: bgColor, font: font, fontSize: fontSize)
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    func toRTF(settings: SettingsRendering) -> Data {
        let colors = settings.getTheme()
        return self.toRTF(fgColor: colors.foreground, bgColor: colors.background, font: settings.fontName, fontSize: settings.fontSize)
    }
    func toRTF(settings: SettingsRendering) -> NSAttributedString? {
        let data: Data = self.toRTF(settings: settings)
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    static func stringToFormattedData(_ string: String, format: Settings.Format, fgColor: String? = nil, bgColor: String? = nil, font: String? = nil, fontSize: CGFloat? = nil, css: String = "") -> Data {
        let labelColor: NSColor?
        if let s = fgColor, let c = NSColor(fromHexString: s) {
            labelColor = c
        } else {
            labelColor = nil
        }
        let backgroundColor: NSColor?
        if let s = bgColor, let c = NSColor(fromHexString: s) {
            backgroundColor = c
        } else {
            backgroundColor = nil
        }
        let font1: NSFont?
        if let f = font {
            if f == "-" {
                font1 = NSFont.monospacedSystemFont(ofSize: fontSize ?? NSFont.systemFontSize, weight: .regular)
            } else {
                font1 = NSFont(name: f, size: fontSize ?? NSFont.systemFontSize)
            }
        } else {
            font1 = nil
        }
        return stringToFormattedData(string, format: format, fgColor: labelColor, bgColor: backgroundColor, font: font1, css: css)
    }
    
    static func stringToFormattedData(_ string: String, settings: SettingsRendering, cssFile: URL? = nil) -> Data {
        let colors = settings.getTheme()
        var css = settings.css
        if let file = cssFile, let s = try? String(contentsOf: file) {
            css = s + css
        }
        return stringToFormattedData(string, format: settings.format, fgColor: colors.foreground, bgColor: colors.background, font: settings.fontName, fontSize: settings.fontSize, css: css)
    }
    
    static func stringToFormattedData(_ string: String, format: Settings.Format, fgColor: NSColor? = nil, bgColor: NSColor? = nil, font: NSFont? = nil, css: String = "") -> Data {
        let labelColor: NSColor
        if let c = fgColor {
            labelColor = c
        } else {
            labelColor = NSColor.labelColor
        }
        let backgroundColor: NSColor
        if let c = bgColor {
            backgroundColor = c
        } else {
            backgroundColor = NSColor.controlBackgroundColor
        }
        let font1 = font ?? NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        switch format {
        case .rtf:
            let s = NSAttributedString(string: string, attributes: [.foregroundColor: labelColor, .backgroundColor: backgroundColor, .font: font1])
            if let data = try? s.data(from: NSRange(location: 0, length: s.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8, .backgroundColor: backgroundColor]) {
                return data
            } else {
                return string.data(using: .utf8)!
            }
        case .html:
            let fg_color = labelColor.toHexString() ?? "#333"
            let bg_color = backgroundColor.toHexString() ?? "#fff"
            let s = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Syntax Highlight</title>
<style>
body {
    height: 100%;
    border: 0;
    margin: 0;
    padding: 0;
    text-align: left;
    background-color: \(bg_color);
    color: \(fg_color);
    font: \(font1.pointSize)pt \(font1.fontName);
}
\(css)
</style>
</head>
<body class="hl">
<pre class="hl">
\(string)
</pre>
</body>
</html>
"""
            return s.data(using: .utf8)!
        }
    }
    
    func htmlEntitites() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#039;")
            // .replacingOccurrences(of: "\n", with: "<br />")
    }
}
