//
//  NSColor+ext.swift
//  QLExt
//
//  Created by sbarex on 18/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

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
            var theInt: UInt32 = 0
            let scanner = Scanner(string: cleanedString)
            scanner.scanHexInt32(&theInt)
            let red = CGFloat((theInt & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((theInt & 0xFF00) >> 8) / 255.0
            let blue = CGFloat((theInt & 0xFF)) / 255.0
            self.init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
        } else {
            return nil
        }
    }
    
    func toHexString() -> String {
        if self.colorSpace.numberOfColorComponents != 3 {
            return self.usingColorSpace(.deviceRGB)?.toHexString() ?? "#000000"
        }
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}
