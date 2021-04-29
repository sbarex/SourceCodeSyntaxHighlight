//
//  SCSHTheme+C.swift
//  Syntax Highlight XPC Service
//
//  Created by Sbarex on 08/01/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension SCSHTheme.Property {
    convenience init(cProperty property: HThemeProperty) {
        self.init(color: property.color != nil ? String(cString: property.color) : "#000000", isBold: property.bold > 0, isItalic: property.italic > 0, isUnderline: property.underline > 0)
        if property.numberOfCustomStyles > 0, property.formats != nil, property.styles != nil {
            var custom: [String: SCSHTheme.PropertyCustomStyle] = [:]
            for i in 0..<Int(property.numberOfCustomStyles) {
                guard let format = property.formats.pointee?.advanced(by: i), let style = property.styles.pointee?.advanced(by: i) else {
                    continue
                }
                let override = property.override.pointee.advanced(by: i)
                custom[String(cString: format)] = (style: String(cString: style), override: override != 0)
            }
            self.customStyles = custom
        }
    }
}

extension SCSHTheme.CanvasProperty {
    convenience init(cProperty property: HThemeProperty) {
        self.init(color: String(cString: property.color))
    }
}

extension SCSHTheme {
    convenience init(cTheme theme: HTheme) {
        let name = String(cString: theme.name)
        let desc = String(cString: theme.desc)
    
        let categories: Set<String>
        switch theme.appearance.rawValue {
        case 1:
            categories = ["light"]
        case 2:
            categories = ["dark"]
        default:
            categories = []
        }
        
        var keywords: [Property] = []
        for i in 0..<Int(theme.keyword_count) {
            if let k = theme.keywords.advanced(by: i).pointee?.pointee {
                let keyword = Property(cProperty: k)
                keywords.append(keyword)
            }
        }
        
        let lspType: Property
        if theme.lspType == nil {
            lspType = Property(dict: keywords.count >= 2 ? keywords[1].toDictionary() : [:]) ?? Property()
        } else {
            lspType = Property(cProperty: theme.lspType.pointee)
        }
        let lspClass: Property
        if theme.lspClass == nil {
            lspClass = Property(dict: !keywords.isEmpty ? keywords[0].toDictionary() : [:]) ?? Property()
        } else {
            lspClass = Property(cProperty: theme.lspClass.pointee)
        }
        let lspStruct: Property
        if theme.lspStruct == nil {
            lspStruct = Property(dict: keywords.count > 3 ? keywords[3].toDictionary() : [:]) ?? Property()
        } else {
            lspStruct = Property(cProperty: theme.lspStruct.pointee)
        }
        let lspInterface: Property
        if theme.lspInterface == nil {
            lspInterface = Property(dict: keywords.count > 0 ? keywords[1].toDictionary() : [:]) ?? Property()
        } else {
            lspInterface = Property(cProperty: theme.lspInterface.pointee)
        }
        let lspParameter: Property
        if theme.lspParameter == nil {
            lspParameter = Property(dict: keywords.count > 5 ? keywords[5].toDictionary() : [:]) ?? Property()
        } else {
            lspParameter = Property(cProperty: theme.lspParameter.pointee)
        }
        let lspVariable: Property
        if theme.lspVariable == nil {
            lspVariable = Property(dict: keywords.count > 4 ? keywords[4].toDictionary() : [:]) ?? Property()
        } else {
            lspVariable = Property(cProperty: theme.lspVariable.pointee)
        }
        let lspEnumMember: Property
        if theme.lspEnumMember == nil {
            lspEnumMember = Property(dict: keywords.count > 4 ? keywords[4].toDictionary() : [:]) ?? Property()
        } else {
            lspEnumMember = Property(cProperty: theme.lspEnumMember.pointee)
        }
        let lspFunction: Property
        if theme.lspFunction == nil {
            lspFunction = Property(dict: keywords.count > 3 ? keywords[3].toDictionary() : [:]) ?? Property()
        } else {
            lspFunction = Property(cProperty: theme.lspFunction.pointee)
        }
        let lspMethod: Property
        if theme.lspMethod == nil {
            lspMethod = Property(dict: keywords.count > 3 ? keywords[3].toDictionary() : [:]) ?? Property()
        } else {
            lspMethod = Property(cProperty: theme.lspMethod.pointee)
        }
        let lspKeyword: Property
        if theme.lspKeyword == nil {
            lspKeyword = Property(dict: keywords.count > 0 ? keywords[0].toDictionary() : [:]) ?? Property()
        } else {
            lspKeyword = Property(cProperty: theme.lspKeyword.pointee)
        }
        let lspNumber: Property
        if theme.lspNumber == nil {
            lspNumber = Property(cProperty: theme.number.pointee)
        } else {
            lspNumber = Property(cProperty: theme.lspNumber.pointee)
        }
        let lspRegexp: Property
        if theme.lspRegexp == nil {
            lspRegexp = Property(cProperty: theme.string.pointee)
        } else {
            lspRegexp = Property(cProperty: theme.lspRegexp.pointee)
        }
        let lspOperator: Property
        if theme.lspOperator == nil {
            lspOperator = Property(cProperty: theme.operatorProp.pointee)
        } else {
            lspOperator = Property(cProperty: theme.lspOperator.pointee)
        }
        
        let lspHover: Property
        if theme.hover != nil {
            lspHover = Property(cProperty: theme.hover.pointee)
        } else {
            lspHover = Property()
        }
        
        let lspError: Property
        if theme.error != nil {
            lspError = Property(cProperty: theme.error.pointee)
        } else {
            lspError = Property()
        }
        
        let lspErrorMessage: Property
        if theme.errorMessage != nil {
            lspErrorMessage = Property(cProperty: theme.errorMessage.pointee)
        } else {
            lspErrorMessage = Property()
        }
        
        self.init(
            name: (theme.base16 > 0 ? "base16/" : "") + name,
            desc: desc,
            categories: categories,
            plain: Property(cProperty: theme.plain.pointee),
            canvas: CanvasProperty(cProperty: theme.canvas.pointee),
            number: Property(cProperty: theme.number.pointee),
            string: Property(cProperty: theme.string.pointee),
            escape: Property(cProperty: theme.escape.pointee),
            preProcessor: Property(cProperty: theme.preProcessor.pointee),
            stringPreProc: Property(cProperty: theme.stringPreProc.pointee),
            blockComment: Property(cProperty: theme.blockComment.pointee),
            lineComment: Property(cProperty: theme.lineComment.pointee),
            lineNum: Property(cProperty: theme.lineNum.pointee),
            operatorProp: Property(cProperty: theme.operatorProp.pointee),
            interpolation: Property(cProperty: theme.interpolation.pointee),
            
            hover: lspHover,
            error: lspError,
            errorMessage: lspErrorMessage,
            
            lspType: lspType,
            lspClass: lspClass,
            lspStruct: lspStruct,
            lspInterface: lspInterface,
            lspParameter: lspParameter,
            lspVariable: lspVariable,
            lspEnumMember: lspEnumMember,
            lspFunction: lspFunction,
            lspMethod: lspMethod,
            lspKeyword: lspKeyword,
            lspNumber: lspNumber,
            lspRegexp: lspRegexp,
            lspOperator: lspOperator,
            
            keywords: keywords
        )
        
        
        self.isStandalone = theme.standalone != 0
        self.path = String(cString: theme.path)
        
        if theme.error?.pointee.color == nil {
            self.lspError.color = "#ff0000"
        }
        if theme.errorMessage?.pointee.color == nil {
            self.lspErrorMessage.color = "#ff0000"
        }
        
        if self.lspErrorMessage.getCustomStyle(for: "html")?.style.isEmpty ?? true {
            self.lspErrorMessage.setCustomStyle(for: "html", style: (style: "border:solid 1px red; margin-left: 3em;", override: false))
        }
        if self.lspHover.getCustomStyle(for: "html")?.style.isEmpty ?? true {
            self.lspHover.setCustomStyle(for: "html", style: (style: "cursor:help;", override: false))
        }
        
        self.isDirty = false
    }
}
