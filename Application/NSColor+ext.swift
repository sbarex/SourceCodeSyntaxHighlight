//
//  NSColor+ext.swift
//  SyntaxHighlight
//
//  Created by sbarex on 18/10/2019.
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

extension NSColor {
    convenience init? (fromHexString hex: String, alpha: CGFloat = 1)  {
        // Handle two types of literals: 0x and # prefixed
        var cleanedString = hex
        if hex.hasPrefix("0x") {
            cleanedString.removeFirst(2)
            cleanedString = String(hex[hex.index(hex.startIndex, offsetBy: 2)...hex.endIndex])
        } else if hex.hasPrefix("#") {
            cleanedString.removeFirst()
        }
        // Ensure it only contains valid hex characters 0
        let validHexPattern = "[a-fA-F0-9]+"
        if cleanedString.range(of: validHexPattern, options: String.CompareOptions.regularExpression) != nil {
            var theInt: UInt64 = 0
            let scanner = Scanner(string: cleanedString)
            scanner.scanHexInt64(&theInt)
            let red = CGFloat((theInt & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((theInt & 0xFF00) >> 8) / 255.0
            let blue = CGFloat((theInt & 0xFF)) / 255.0
            self.init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
        } else {
            return nil
        }
    }
    
    func toHexString() -> String {
        // Force the conversion su device RGB color.
        // For NSColor created by named color you cannot test .colorSpace property (cause an uncatchable exception!)
        return self.usingColorSpace(.deviceRGB)?._toHexString() ?? "#000000"
    }
    
    fileprivate func _toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
    
    class func random() -> NSColor {
        let red =   CGFloat.random(in: 0...255)
        let green = CGFloat.random(in: 0...255)
        let blue =  CGFloat.random(in: 0...255)
        
        let color = NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
        return color
    }
}
