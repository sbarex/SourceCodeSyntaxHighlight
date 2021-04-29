//
//  SCSHTheme.swift
//  SCSHXPCService
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

typealias NotificationThemeSavedData = (theme: SCSHTheme, oldName: String)
typealias NotificationThemeDeletedData = (String)

public protocol SCSHThemeDelegate: NSObjectProtocol {
    /// Notify the delegate that a property is changed.
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHTheme.PropertyBase)
    
    /// Notify the delegate that the categories are changed.
    func themeDidChangeCategories(_ theme: SCSHTheme)
    /// Notify the delegate that the name is changed.
    func themeDidChangeName(_ theme: SCSHTheme)
    /// Notify the delpublic egate that the description is changed.
    func themeDidChangeDescription(_ theme: SCSHTheme)
    
    /// Notify the delegate that the dirty status is changed.
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme)
    /// Notify the delegate that a new keyword is added.
    func themeDidAddKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property)
    /// Notify the delegate that a keyword is removed.
    func themeDidRemoveKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property)
}

extension SCSHThemeDelegate {
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHTheme.PropertyBase) {}
    
    func themeDidChangeCategories(_ theme: SCSHTheme) {}
    func themeDidChangeName(_ theme: SCSHTheme) {}
    func themeDidChangeDescription(_ theme: SCSHTheme) {}
    
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme) {}
    
    func themeDidAddKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {}
    func themeDidRemoveKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property) {}
}

public class SCSHTheme: NSObject, Sequence {
    public static func == (lhs: SCSHTheme, rhs: SCSHTheme) -> Bool {
        return lhs.name == rhs.name && lhs.isStandalone == rhs.isStandalone
    }
    
    // MARK: - Theme Properties
    
    public enum PropertyName: Hashable, CaseIterable {
        case plain
        case canvas
        case number
        case string
        case escape
        case preProcessor
        case stringPreProc
        case blockComment
        case lineComment
        case lineNum
        case `operator`
        case interpolation
        
        case lspHover // LSP Hover elements
        case lspError // LSP syntax errors
        case lspErrorMessage // LSP error descriptions
        
        case lspType
        case lspClass
        case lspStruct
        case lspInterface
        case lspParameter
        case lspVariable
        case lspEnumMember
        case lspFunction
        case lspMethod
        case lspKeyword
        case lspNumber
        case lspRegexp
        case lspOperator
        
        case keyword(index: Int)
        
        public static var allCases: [PropertyName] {
            return [
                .plain,
                .canvas,
                .number,
                .string,
                .escape,
                .preProcessor,
                .stringPreProc,
                .blockComment,
                .lineComment,
                .lineNum,
                .operator,
                .interpolation,
                
                .lspHover,
                .lspError,
                .lspErrorMessage,
                
                .lspType,
                .lspClass,
                .lspStruct,
                .lspInterface,
                .lspParameter,
                .lspVariable,
                .lspEnumMember,
                .lspFunction,
                .lspMethod,
                .lspKeyword,
                .lspNumber,
                .lspRegexp,
                .lspOperator,

                .keyword(index: 0),
                .keyword(index: 1),
                .keyword(index: 2),
                .keyword(index: 3),
                .keyword(index: 4),
                .keyword(index: 5),
                .keyword(index: 6),
                .keyword(index: 7),
                .keyword(index: 8),
                .keyword(index: 9),
                .keyword(index: 10),
                .keyword(index: 11),
                .keyword(index: 12),
                .keyword(index: 13),
                .keyword(index: 14),
                .keyword(index: 15),
                .keyword(index: 16),
                .keyword(index: 17),
                .keyword(index: 18),
                .keyword(index: 19),
                .keyword(index: 20),
                .keyword(index: 21),
                .keyword(index: 22),
                .keyword(index: 23),
                .keyword(index: 24),
                .keyword(index: 25),
            ]
        }
        
        public static let numberOfStandardCases: Int = {
            return SCSHTheme.PropertyName.allCases.filter({ !$0.isKeyword && !$0.isLSP }).count
        }()
        public static let numberOfLSPCases: Int = {
            return SCSHTheme.PropertyName.allCases.filter({ $0.isLSP }).count
        }()
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)
        }
        
        var name: String {
            switch self {
            case .plain: return "Default"
            case .canvas: return "Background"
            case .number: return "Number"
            case .string: return "String"
            case .escape: return "Escape"
            case .preProcessor: return "Preprocessor"
            case .stringPreProc: return "String preprocessor"
            case .blockComment: return "Block comment"
            case .lineComment: return "Line comment"
            case .lineNum: return "Line number"
            case .operator: return "Operator"
            case .interpolation: return "Interpolation"
            
            case .keyword(let index): return "Keyword \(index+1)"
                
            case .lspHover: return "LS Hover elements"
            case .lspError: return "LS Syntax errors"
            case .lspErrorMessage: return "LS Error message"
                
            case .lspType: return "LS Type"
            case .lspClass: return "LS Class"
            case .lspStruct: return "LS Struct"
            case .lspInterface: return "LS Interface"
            case .lspParameter: return "LS Parameter"
            case .lspVariable: return "LS Variable"
            case .lspEnumMember: return "LS Enum member"
            case .lspFunction: return "LS Function"
            case .lspMethod: return "LS Method"
            case .lspKeyword: return "LS Keyword"
            case .lspNumber: return "LS Number"
            case .lspRegexp: return "LS Regular expression"
            case .lspOperator: return "LS Operator"
            }
        }
        
        var luaName: String {
            switch self {
            case .plain: return "Default"
            case .canvas: return "Canvas"
            case .number: return "Number"
            case .string: return "String"
            case .escape: return "Escape"
            case .preProcessor: return "PreProcessor"
            case .stringPreProc: return "StringPreProc"
            case .blockComment: return "BlockComment"
            case .lineComment: return "LineComment"
            case .lineNum: return "LineNum"
            case .operator: return "Operator"
            case .interpolation: return "Interpolation"
            case .lspHover: return "Hover"
            case .lspError: return "Error"
            case .lspErrorMessage: return "ErrorMessage"
                
            case .keyword(let index): return "Keyword \(index+1)"
                
            case .lspType: return "type"
            case .lspClass: return "class"
            case .lspStruct: return "struct"
            case .lspInterface: return "interface"
            case .lspParameter: return "parameter"
            case .lspVariable: return "variable"
            case .lspEnumMember: return "enumMember"
            case .lspFunction: return "function"
            case .lspMethod: return "method"
            case .lspKeyword: return "keyword"
            case .lspNumber: return "number"
            case .lspRegexp: return "regexp"
            case .lspOperator: return "operator"
            }
        }
        
        /// CSS class used to render the token.
        var cssClasses: [String] {
            switch self {
            case .plain: return ["hl"]
            case .canvas: return ["hl"]
            case .number: return ["hl", "num"]
            case .escape: return ["hl", "esc"]
            case .string: return ["hl", "sng"]
            case .preProcessor: return ["hl", "ppc"]
            case .stringPreProc: return ["hl", "pps"]
            case .blockComment: return ["hl", "com"]
            case .lineComment: return ["hl", "slc"]
            case .lineNum: return ["hl", "lin"]
            case .operator:
                return ["hl", "opt"]
            case .interpolation:
                return ["hl", "ipl"]
                
            case .keyword(let index):
                return ["hl", "kw" + String(UnicodeScalar(UInt8(97 + index)))]
                
            case .lspHover: return ["hl", "hvr"]
            case .lspError: return ["hl", "err"]
            case .lspErrorMessage: return ["hl", "erm"]
            case .lspType: return ["hl", "sta"]
            case .lspClass: return ["hl", "stb"]
            case .lspStruct: return ["hl", "stc"]
            case .lspInterface: return ["hl", "std"]
            case .lspParameter: return ["hl", "ste"]
            case .lspVariable:  return ["hl", "stf"]
            case .lspEnumMember: return ["hl", "stg"]
            case .lspFunction: return ["hl", "sth"]
            case .lspMethod: return ["hl", "sti"]
            case .lspKeyword: return ["hl", "stj"]
            case .lspNumber: return ["hl", "stk"]
            case .lspRegexp: return ["hl", "stl"]
            case .lspOperator: return ["hl", "stm"]
                
            }
        }
         
        /// Returns the property name based of the associated CSS class.
        init?(className: String) {
            switch className {
            case "hl":
                self = .plain // .canvas
            case "num":
                self = .number
            case "esc":
                self = .escape
            case "sng":
                self = .string
            case "ppc":
                self = .preProcessor
            case "pps":
                self = .stringPreProc
            case "com":
                self = .blockComment
            case "slc":
                self = .lineComment
            case "lin":
                self = .lineNum
            case "opt":
                self = .operator
            case "ipl":
                self = .interpolation
                
            case "sta":
                self = .lspType
            case "stb":
                self = .lspClass
            case "stc":
                self = .lspStruct
            case "std":
                self = .lspInterface
            case "ste":
                self = .lspParameter
            case "stf":
                self = .lspVariable
            case "stg":
                self = .lspEnumMember
            case "sth":
                self = .lspFunction
            case "sti":
                self = .lspMethod
            case "stj":
                self = .lspKeyword
            case "stk":
                self = .lspNumber
            case "stl":
                self = .lspRegexp
            case "stm":
                self = .lspOperator
            default:
                if className.hasPrefix("kw") {
                    if let n = className.last?.asciiValue {
                        self = .keyword(index: Int(n - 97))
                        return
                    }
                }
                return nil
            }
        }
        
        /// Returns the property name at index (zero based).
        init?(index: Int) {
            if index >= 0 && index < Self.allCases.count {
                self = Self.allCases[index]
            } else {
                return nil
            }
        }
        
        var index: Int {
            return Self.allCases.firstIndex(of: self) ?? -1
        }
        
        var isStandard: Bool {
            return !isKeyword && !isLSP
        }
        
        var isKeyword: Bool {
            switch self {
            case .keyword(_):
                return true
            default:
                return false
            }
        }
        
        var keywordIndex: Int? {
            switch self {
            case .keyword(let index):
                return index
            default:
                return nil
            }
        }
        
        var isLSP: Bool {
            switch self {
            case .lspHover,
                 .lspError,
                 .lspErrorMessage,
                 
                 .lspType,
                 .lspClass,
                 .lspStruct,
                 .lspInterface,
                 .lspParameter,
                 .lspVariable,
                 .lspEnumMember,
                 .lspFunction,
                 .lspMethod,
                 .lspKeyword,
                 .lspNumber,
                 .lspRegexp,
                 .lspOperator:
                return true
            default:
                return false
            }
        }
        
        /// Returns the next property name.
        public var next: PropertyName? {
            let index = PropertyName.allCases.firstIndex(of: self)!
            if index < PropertyName.allCases.count - 1 {
                return PropertyName.allCases[index + 1]
            } else {
                return nil
            }
        }
        
        /// Returns the previous property name.
        public var prev: PropertyName? {
            let index = PropertyName.allCases.firstIndex(of: self)!
            if index > 1 {
                return PropertyName.allCases[index - 1]
            } else {
                return nil
            }
        }
    }
    
    public typealias PropertyCustomStyle = (style: String, override: Bool)
    
    public class PropertyBase {
        internal weak var theme: SCSHTheme?
        internal var customStyles: [String: PropertyCustomStyle]
        
        public var color: String {
            didSet {
                if oldValue != color {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
        
        required public init(color: String) {
            self.color = color
            self.customStyles = [:]
        }
        
        public required init?(dict: [String: Any]?) {
            self.color = dict?["color"] as? String ?? ""
            self.customStyles = [:]
            if let custom = dict?["custom"] as? [String: [String: AnyHashable]] {
                var styles: [String: PropertyCustomStyle] = [:]
                for style in custom {
                    if let v = style.value["style"] as? String, let override = style.value["override"] as? Bool {
                        styles[style.key] = (style: v, override: override)
                    }
                }
                self.customStyles = styles
            }
        }
        
        public func toDictionary() -> [String: AnyHashable] {
            var dict: [String: AnyHashable] = [
                "color": color,
            ]
            if !self.customStyles.isEmpty {
                var styles: [String: [String: AnyHashable]] = [:]
                for style in self.customStyles {
                    guard !style.value.style.isEmpty else { continue }
                    styles[style.key] = ["style": style.value.style, "override": style.value.override]
                }
                dict["custom"] = styles
            }
            return dict
        }
        
        /// Get CSS inline style attribute for the property.
        public func getCSSStyle() -> String {
            var s = "    background-color: \(color); \n"
            if let style = customStyles["html"], !style.style.isEmpty {
                if style.override {
                    s = ""
                }
                s += style.style + ";"
            }
            return s
        }
        
        public func output() -> String {
            var s = "{ Colour=\"\(color)\""
            
            if !customStyles.isEmpty {
                s += ", " + self.exportCustomStylesToLua()
            }
            
            s += " }"
            return s
        }
        
        internal func exportCustomStylesToLua() -> String {
            var s = ""
            if !customStyles.isEmpty {
                s += "Custom = { "
                for (format, style) in customStyles {
                    s += "{ Format = \"\(format)\", Style = \"\(style.style.escapingForLua())\", Override = \(style.override ? "true" : "false") }, "
                }
                s = String(s.dropLast(2)) + " }"
            }
            return s
        }
        
        public func getCustomStyle(for format: String) -> PropertyCustomStyle? {
            return self.customStyles[format]
        }
        
        public func setCustomStyle(for format: String, style: PropertyCustomStyle) {
            let oldValue = getCustomStyle(for: format)
            if style.style.isEmpty {
                self.customStyles.removeValue(forKey: format)
                if oldValue != nil {
                    self.theme?.onPropertyDidChange(self)
                }
            } else {
                self.customStyles[format] = style
                if oldValue == nil || oldValue! != style  {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
    }
    
    public class CanvasProperty: PropertyBase {
        
    }
    
    public class Property: PropertyBase {
        public var isBold: Bool {
            didSet {
                if oldValue != isBold {
                   self.theme?.onPropertyDidChange(self)
                }
            }
        }
        public var isItalic: Bool {
            didSet {
                if oldValue != isItalic {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
        public var isUnderline: Bool {
            didSet {
                if oldValue != isUnderline {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
        
        public convenience init() {
            self.init(color: "", isBold: false, isItalic: false, isUnderline: false)
        }
        
        required public init(color: String) {
            self.isBold = false
            self.isItalic = false
            self.isUnderline = false
            super.init(color: color)
        }
        
        public init(color: String, isBold: Bool = false, isItalic: Bool = false, isUnderline: Bool = false) {
            self.isBold = isBold
            self.isItalic = isItalic
            self.isUnderline = isUnderline
            
            super.init(color: color)
        }
        
        required public convenience init?(dict: [String: Any]?) {
            self.init(color: dict?["color"] as? String ?? "", isBold: dict?["bold"] as? Bool ?? false, isItalic:  dict?["italic"] as? Bool ?? false, isUnderline: dict?["underline"] as? Bool ?? false)
            if let custom = dict?["custom"] as? [String: [String: AnyHashable]] {
                var styles: [String: PropertyCustomStyle] = [:]
                for style in custom {
                    if let v = style.value["style"] as? String, let override = style.value["override"] as? Bool {
                        styles[style.key] = (style: v, override: override)
                    }
                }
                self.customStyles = styles
            }
        }
        
        override public func toDictionary() -> [String: AnyHashable] {
            var dict = super.toDictionary()
            if isBold {
                dict["bold"] = true
            }
            if isItalic {
                dict["italic"] = true
            }
            if isUnderline {
                dict["underline"] = true
            }
            
            return dict
        }
        
        /// Get CSS inline style attribute for the property.
        override public func getCSSStyle() -> String {
            var style = ""
            if color != "" {
                style += "    color: \(color);\n"
            }
            if isBold {
                style += "    font-weight: bold;\n"
            }
            if isItalic {
                style += "    font-style: italic;\n"
            }
            if isUnderline {
                style += "    text-decoration: underline;\n"
            }
            if let css = getCustomStyle(for: "html"), !css.style.isEmpty {
                if css.override {
                    style = ""
                }
                style += css.style + ";\n"
            }
            return style
        }
        
        override public func output() -> String {
            var s = "{ "
            let override = customStyles.first(where: { $1.override }) != nil
            if !override {
                s += "Colour=\"\(color)\""
                if isBold {
                    s += ", Bold=true"
                }
                if isItalic {
                    s += ", Italic=true"
                }
                if isUnderline {
                    s += ", Underline=true"
                }
            }
            
            if !customStyles.isEmpty {
                s += (override ? ", " : "") + self.exportCustomStylesToLua()
            }
            s += " }"
            return s
        }
        
        func getAttributedString(name: SCSHTheme.PropertyName, withFont font: NSFont, attributes extra_attributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
            let backgroundColor: NSColor
            if let c = theme?.backgroundColor, let col = NSColor(fromHexString: c) {
                backgroundColor = col
            } else {
                backgroundColor = .clear
            }
            var attributes = extra_attributes
            attributes[.font] = font
            attributes[.backgroundColor] = backgroundColor
            
            let style = self.getCustomStyle(for: "html")
            if style == nil || !style!.override {
                if name == .canvas || name == .lspHover, let c = theme?.foregroundColor {
                    attributes[.foregroundColor] = NSColor(fromHexString: c) ?? NSColor.black
                } else {
                    attributes[.foregroundColor] = NSColor(fromHexString: self.color) ?? NSColor.black
                }
                
                if self.isUnderline {
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                var fontTraits: NSFontTraitMask = []
                if self.isBold {
                    fontTraits.insert(.boldFontMask)
                }
                if self.isItalic {
                    fontTraits.insert(.italicFontMask)
                }
                if !fontTraits.isEmpty, let f = NSFontManager.shared.font(withFamily: font.familyName ?? font.fontName, traits: fontTraits, weight: 0, size: font.pointSize) {
                    attributes[.font] = f
                }
            }
            return NSAttributedString(string: name.name, attributes: attributes)
        }
    }
    
    // MARK: - Theme Properties Iterator
    public struct PropertiesIterator: IteratorProtocol {
        let theme: SCSHTheme
        private var index: PropertyName?

        init(_ theme: SCSHTheme) {
            self.theme = theme
        }

        mutating public func next() -> PropertyBase? {
            if index == nil {
                index = .canvas
            } else {
                index = index!.next
                if index == nil {
                    return nil
                }
            }
            return theme[index!]
        }
    }
    
    // MARK: -
    enum ThemeError: Error {
        case missingProperty(name: PropertyName)
        case missingProperties
        case missingUrl
    }
    
    // MARK: -
    weak var delegate: SCSHThemeDelegate?
    
    fileprivate var refreshLock = 0
    @objc dynamic fileprivate(set) var needRefresh: Bool = false
    
    func lockRefresh() {
        refreshLock += 1
    }
    func unlockRefresh() {
        refreshLock -= 1
        if refreshLock == 0 {
            setNeedRefresh()
        }
    }
    func setNeedRefresh() {
        if refreshLock == 0 {
            doRefresh()
        }
    }
    internal func doRefresh() {
        needRefresh = true
        NotificationCenter.default.post(name: .ThemeNeedRefresh, object: self)
    }
    
    public var name: String {
        didSet {
            if oldValue != name {
                delegate?.themeDidChangeName(self)
                if !self.isDirty {
                    self.isDirty = true
                }
                setNeedRefresh()
            }
        }
    }
    
    static func processThemeName(_ name: String) -> (name: String, isStandalone: Bool) {
        if name.hasPrefix("!") {
            var n = name
            n.removeFirst()
            return (name: n, isStandalone: false)
        } else {
            return (name: name, isStandalone: true)
        }
    }
    
    static func convertThemeName(_ name: String, isStandalone: Bool) -> String {
        if !isStandalone && !name.hasPrefix("!") {
            return "!\(name)"
        } else if isStandalone && name.hasPrefix("!") {
            return String(name.dropFirst())
        } else {
            return name
        }
    }
    
    public var nameForSettings: String {
        return Self.convertThemeName(name, isStandalone: self.isStandalone)
    }
    
    public var desc: String {
        didSet {
            if oldValue != desc {
                delegate?.themeDidChangeDescription(self)
                if !self.isDirty {
                    self.isDirty = true
                }
                setNeedRefresh()
            }
        }
    }
    
    public var categories: Set<String> {
        didSet {
            if oldValue != categories {
                delegate?.themeDidChangeCategories(self)
                if !self.isDirty {
                    self.isDirty = true
                }
                setNeedRefresh()
            }
        }
    }
        
    /// Indicate if the theme is a standard provided by highlight.
    /// Set to false to allow the customization.
    public var isStandalone: Bool = true
    
    public var foregroundColor: String {
        return self.plain.color
    }
    public var backgroundColor: String {
        return self.canvas.color
    }
    
    var isLight: Bool {
        get {
            return categories.contains("light")
        }
        set {
            var c: Set<String> = Set<String>.init(categories)
            if newValue {
                c.remove("dark")
                c.insert("light")
            } else {
                c.remove("light")
                c.insert("dark")
            }
            categories = c
        }
    }
    
    var isDark: Bool {
        get {
            return categories.contains("dark")
        }
        set {
            isLight = !newValue
        }
    }
    
    /// Full description with the categories.
    public var fullDesc: String {
        var s = desc
        if categories.count > 0 {
            s += " [" + categories.joined(separator: " ") + "]"
        }
        return s
    }
    
    var numberOfProperties: Int {
        var n = 0
        PropertyName.allCases.forEach({ if !$0.isKeyword { n += 1 }})
        
        return n + keywords.count
    }

    subscript(name: PropertyName) -> PropertyBase? {
        switch name {
        case .canvas:
            return self.canvas
        case .plain:
            return self.plain
        case .number:
            return self.number
        case .escape:
            return self.escape
        case .string:
            return self.string
        case .preProcessor:
            return self.preProcessor
        case .stringPreProc:
            return self.stringPreProc
        case .blockComment:
            return self.blockComment
        case .lineComment:
            return self.lineComment
        case .lineNum:
            return self.lineNum
        case .operator:
            return self.operatorProp
        case .interpolation:
            return self.interpolation
                
        case .lspHover:
            return self.lspHover
        case .lspError:
            return self.lspError
        case .lspErrorMessage:
            return self.lspErrorMessage
        case .lspType:
            return self.lspType
        case .lspClass:
            return self.lspClass
        case .lspStruct:
            return self.lspStruct
        case .lspInterface:
            return self.lspInterface
        case .lspParameter:
            return self.lspParameter
        case .lspVariable:
            return self.lspVariable
        case .lspEnumMember:
            return self.lspEnumMember
        case .lspFunction:
            return self.lspFunction
        case .lspMethod:
            return self.lspMethod
        case .lspKeyword:
            return self.lspKeyword
        case .lspNumber:
            return self.lspNumber
        case .lspRegexp:
            return self.lspRegexp
        case .lspOperator:
            return self.lspOperator

        case .keyword(let index):
            if index >= 0 && index < keywords.count {
                return keywords[index]
            } else {
                return nil
            }
        }
    }
    
    let plain: Property
    let canvas: CanvasProperty
    let number: Property
    let string: Property
    let escape: Property
    let preProcessor: Property
    let stringPreProc: Property
    let blockComment: Property
    let lineComment: Property
    let lineNum: Property
    let operatorProp: Property
    let interpolation: Property
    
    let lspHover: Property
    let lspError: Property
    let lspErrorMessage: Property
    
    let lspType: Property
    let lspClass: Property
    let lspStruct: Property
    let lspInterface: Property
    let lspParameter: Property
    let lspVariable: Property
    let lspEnumMember: Property
    let lspFunction: Property
    let lspMethod: Property
    let lspKeyword: Property
    let lspNumber: Property
    let lspRegexp: Property
    let lspOperator: Property
    
    var path: String
    var exists: Bool {
        if !self.path.isEmpty {
            return FileManager.default.isReadableFile(atPath: self.path)
        } else {
            return false
        }
    }
    
    private(set) var keywords: [Property] = []
    
    @objc dynamic var isDirty: Bool = false {
        didSet {
            if oldValue != isDirty {
                delegate?.themeDidChangeDirtyStatus(self)
                NotificationCenter.default.post(name: .ThemeIsDirty, object: self)
            }
        }
    }
    
    public init(name: String, desc: String, categories: Set<String>, plain: Property, canvas: CanvasProperty, number: Property, string: Property, escape: Property, preProcessor: Property, stringPreProc: Property, blockComment: Property, lineComment: Property, lineNum: Property, operatorProp: Property, interpolation: Property, hover: Property, error: Property, errorMessage: Property, lspType: Property, lspClass: Property, lspStruct: Property, lspInterface: Property, lspParameter: Property, lspVariable: Property, lspEnumMember: Property, lspFunction: Property, lspMethod: Property, lspKeyword: Property, lspNumber: Property, lspRegexp: Property, lspOperator: Property, keywords: [Property]) {
        self.name = name
        self.desc = desc
        self.categories = categories
        
        self.canvas = canvas
        self.plain = plain
        self.number = number
        self.string = string
        self.escape = escape
        self.preProcessor = preProcessor
        self.stringPreProc = stringPreProc
        self.blockComment = blockComment
        self.lineComment = lineComment
        self.lineNum = lineNum
        self.operatorProp = operatorProp
        self.interpolation = interpolation
        
        self.lspHover = hover
        self.lspError = error
        self.lspErrorMessage = errorMessage
        self.lspType = lspType
        self.lspClass = lspClass
        self.lspStruct = lspStruct
        self.lspInterface = lspInterface
        self.lspParameter = lspParameter
        self.lspVariable = lspVariable
        self.lspEnumMember = lspEnumMember
        self.lspFunction = lspFunction
        self.lspMethod = lspMethod
        self.lspKeyword = lspKeyword
        self.lspNumber = lspNumber
        self.lspRegexp = lspRegexp
        self.lspOperator = lspOperator
        
        self.keywords = keywords
        self.path = ""
        
        super.init()
        
        self.plain.theme = self
        self.canvas.theme = self
        self.number.theme = self
        self.string.theme = self
        self.escape.theme = self
        self.preProcessor.theme = self
        self.stringPreProc.theme = self
        self.blockComment.theme = self
        self.lineComment.theme = self
        self.lineNum.theme = self
        self.operatorProp.theme = self
        self.interpolation.theme = self
        
        self.lspHover.theme = self
        self.lspError.theme = self
        self.lspErrorMessage.theme = self
        self.lspType.theme = self
        self.lspClass.theme = self
        self.lspStruct.theme = self
        self.lspInterface.theme = self
        self.lspParameter.theme = self
        self.lspVariable.theme = self
        self.lspEnumMember.theme = self
        self.lspFunction.theme = self
        self.lspMethod.theme = self
        self.lspKeyword.theme = self
        self.lspNumber.theme = self
        self.lspRegexp.theme = self
        self.lspOperator.theme = self
        
        self.keywords.forEach({$0.theme = self})
        
        self.isDirty = true
    }
    
    convenience public init(name: String) {
        self.init(name: name, desc: "", categories: ["light"], plain: Property(color: "#000000"), canvas: CanvasProperty(color: "#ffffff"), number: Property(), string: Property(), escape: Property(), preProcessor: Property(), stringPreProc: Property(), blockComment: Property(), lineComment: Property(), lineNum: Property(), operatorProp: Property(), interpolation: Property(), hover: Property(), error: Property(), errorMessage: Property(), lspType: Property(), lspClass: Property(), lspStruct: Property(), lspInterface: Property(), lspParameter: Property(), lspVariable: Property(), lspEnumMember: Property(), lspFunction: Property(), lspMethod: Property(), lspKeyword: Property(), lspNumber: Property(), lspRegexp: Property(), lspOperator: Property(), keywords: [])
    }
    
    convenience public init?(dict dictionary: [String: Any]?) {
        guard let dict = dictionary else {
            return nil
        }
        let name = dict["name"] as? String ?? ""
        let desc = dict["desc"] as? String ?? ""
        let categories = dict["categories"] as? Set<String> ?? []
        
        guard let plain = Property(dict: dict[PropertyName.plain.name] as? [String: Any]) else {
            return nil
        }
        guard let canvas = CanvasProperty(dict: dict[PropertyName.canvas.name] as? [String: Any]) else {
            return nil
        }
        guard let number = Property(dict: dict[PropertyName.number.name] as? [String: Any]) else {
            return nil
        }
        guard let string = Property(dict: dict[PropertyName.string.name] as? [String: Any]) else {
            return nil
        }
        guard let escape = Property(dict: dict[PropertyName.escape.name] as? [String: Any]) else {
            return nil
        }
        guard let preProcessor = Property(dict: dict[PropertyName.preProcessor.name] as? [String: Any]) else {
            return nil
        }
        guard let stringPreProc = Property(dict: dict[PropertyName.stringPreProc.name] as? [String: Any]) else {
            return nil
        }
        guard let blockComment = Property(dict: dict[PropertyName.blockComment.name] as? [String: Any]) else {
            return nil
        }
        guard let lineComment = Property(dict: dict[PropertyName.lineComment.name] as? [String: Any]) else {
            return nil
        }
        guard let lineNum = Property(dict: dict[PropertyName.lineNum.name] as? [String: Any]) else {
            return nil
        }
        guard let operatorProp = Property(dict: dict[PropertyName.operator.name] as? [String: Any]) else {
            return nil
        }
        guard let interpolation = Property(dict: dict[PropertyName.interpolation.name] as? [String: Any]) else {
            return nil
        }
        
        guard let lspHover = Property(dict: dict[PropertyName.lspHover.name] as? [String: Any]) else {
            return nil
        }
        guard let lspError = Property(dict: dict[PropertyName.lspError.name] as? [String: Any]) else {
            return nil
        }
        guard let lspErrorMessage = Property(dict: dict[PropertyName.lspErrorMessage.name] as? [String: Any]) else {
            return nil
        }
        
        guard let lspType = Property(dict: dict[PropertyName.lspType.name] as? [String: Any]) else {
            return nil
        }
        guard let lspClass = Property(dict: dict[PropertyName.lspClass.name] as? [String: Any]) else {
            return nil
        }
        guard let lspStruct = Property(dict: dict[PropertyName.lspStruct.name] as? [String: Any]) else {
            return nil
        }
        guard let lspInterface = Property(dict: dict[PropertyName.lspInterface.name] as? [String: Any]) else {
            return nil
        }
        guard let lspParameter = Property(dict: dict[PropertyName.lspParameter.name] as? [String: Any]) else {
            return nil
        }
        guard let lspVariable = Property(dict: dict[PropertyName.lspVariable.name] as? [String: Any]) else {
            return nil
        }
        guard let lspEnumMember = Property(dict: dict[PropertyName.lspEnumMember.name] as? [String: Any]) else {
            return nil
        }
        guard let lspFunction = Property(dict: dict[PropertyName.lspFunction.name] as? [String: Any]) else {
            return nil
        }
        guard let lspMethod = Property(dict: dict[PropertyName.lspMethod.name] as? [String: Any]) else {
            return nil
        }
        guard let lspKeyword = Property(dict: dict[PropertyName.lspKeyword.name] as? [String: Any]) else {
            return nil
        }
        guard let lspNumber = Property(dict: dict[PropertyName.lspNumber.name] as? [String: Any]) else {
            return nil
        }
        guard let lspRegexp = Property(dict: dict[PropertyName.lspRegexp.name] as? [String: Any]) else {
            return nil
        }
        guard let lspOperator = Property(dict: dict[PropertyName.lspOperator.name] as? [String: Any]) else {
            return nil
        }
        
        var keywords: [Property] = []
        if let kk = dict["keywords"] as? [[String: Any]] {
            for k in kk {
                if let keyword = Property(dict: k) {
                    keywords.append(keyword)
                }
            }
        }
        
        self.init(name: name, desc: desc, categories: categories, plain: plain, canvas: canvas, number: number, string: string, escape: escape, preProcessor: preProcessor, stringPreProc: stringPreProc, blockComment: blockComment, lineComment: lineComment, lineNum: lineNum, operatorProp: operatorProp, interpolation: interpolation, hover: lspHover, error: lspError, errorMessage: lspErrorMessage, lspType: lspType, lspClass: lspClass, lspStruct: lspStruct, lspInterface: lspInterface, lspParameter: lspParameter, lspVariable: lspVariable, lspEnumMember: lspEnumMember, lspFunction: lspFunction, lspMethod: lspMethod, lspKeyword: lspKeyword, lspNumber: lspNumber, lspRegexp: lspRegexp, lspOperator: lspOperator, keywords: keywords)
        
        self.path = dict["path"] as? String ?? ""
        self.isDirty = false
        if let standalone = dict["standalone"] as? Bool {
            self.isStandalone = standalone
        }
    }
    
    public func toDictionary() -> [String: AnyHashable] {
        let dict: [String: AnyHashable] = [
            "name": name,
            "desc": desc,
            "categories": categories,
            "path": path,
            
            PropertyName.plain.name: plain.toDictionary(),
            PropertyName.canvas.name: canvas.toDictionary(),
            PropertyName.number.name: number.toDictionary(),
            PropertyName.string.name: string.toDictionary(),
            PropertyName.escape.name: escape.toDictionary(),
            PropertyName.preProcessor.name: preProcessor.toDictionary(),
            PropertyName.stringPreProc.name: stringPreProc.toDictionary(),
            PropertyName.blockComment.name: blockComment.toDictionary(),
            PropertyName.lineComment.name: lineComment.toDictionary(),
            PropertyName.lineNum.name: lineNum.toDictionary(),
            PropertyName.operator.name: operatorProp.toDictionary(),
            PropertyName.interpolation.name: interpolation.toDictionary(),
            
            PropertyName.lspHover.name: lspHover.toDictionary(),
            PropertyName.lspError.name: lspError.toDictionary(),
            PropertyName.lspErrorMessage.name: lspErrorMessage.toDictionary(),
            PropertyName.lspType.name: lspType.toDictionary(),
            PropertyName.lspClass.name: lspClass.toDictionary(),
            PropertyName.lspStruct.name: lspStruct.toDictionary(),
            PropertyName.lspInterface.name: lspInterface.toDictionary(),
            PropertyName.lspParameter.name: lspParameter.toDictionary(),
            PropertyName.lspVariable.name: lspVariable.toDictionary(),
            PropertyName.lspEnumMember.name: lspEnumMember.toDictionary(),
            PropertyName.lspFunction.name: lspFunction.toDictionary(),
            PropertyName.lspMethod.name: lspMethod.toDictionary(),
            PropertyName.lspKeyword.name: lspKeyword.toDictionary(),
            PropertyName.lspNumber.name: lspNumber.toDictionary(),
            PropertyName.lspRegexp.name: lspRegexp.toDictionary(),
            PropertyName.lspOperator.name: lspOperator.toDictionary(),
        
            "keywords": keywords.map({ $0.toDictionary() }),
            
            "standalone": isStandalone,
        ]
        
        return dict
    }
    
    func save() throws {
        guard !self.path.isEmpty else {
            return
        }
        
        let url = URL(fileURLWithPath: self.path)
        
        let dir = url.deletingLastPathComponent()
        
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        try save(to: url)
    }
    
    /// Save the lua code of the theme to the url.
    func save(to url: URL) throws {
        let s = getLua()
        do {
            try s.write(to: url, atomically: true, encoding: .utf8)
            name = url.deletingPathExtension().lastPathComponent
            isDirty = false
        } catch {
            throw error
        }
    }
    
    /// Get the lua code of the theme.
    func getLua() -> String {
        var s = "Description=\"\(desc.escapingForLua())\"\n\n"
        s += "Categories = {" + categories.map({ "\"" + $0.escapingForLua() + "\"" }).joined(separator: ", ") + "}\n\n"
        
        s += PropertyName.plain.luaName + " = " + plain.output() + "\n"
        s += PropertyName.canvas.luaName + " = " + canvas.output() + "\n"
        s += PropertyName.number.luaName + " = " + number.output() + "\n"
        s += PropertyName.string.luaName + " = " + string.output() + "\n"
        s += PropertyName.escape.luaName + " = " + escape.output() + "\n"
        s += PropertyName.preProcessor.luaName + " = " + preProcessor.output() + "\n"
        s += PropertyName.stringPreProc.luaName + " = " + stringPreProc.output() + "\n"
        s += PropertyName.blockComment.luaName + " = " + blockComment.output() + "\n"
        s += PropertyName.lineComment.luaName + " = " + lineComment.output() + "\n"
        s += PropertyName.lineNum.luaName + " = " + lineNum.output() + "\n"
        s += PropertyName.operator.luaName + " = " + operatorProp.output() + "\n"
        s += PropertyName.interpolation.luaName + " = " + interpolation.output() + "\n"
        
        s += PropertyName.lspHover.luaName + " = " + lspHover.output() + "\n"
        s += PropertyName.lspError.luaName + " = " + lspError.output() + "\n"
        s += PropertyName.lspErrorMessage.luaName + " = " + lspErrorMessage.output() + "\n"
        
        s += "\nKeywords = {\n\t" +
            keywords.map({ $0.output() }).joined(separator: ", \n\t") +
            "\n}\n\n"
        
        s += "\nSemanticTokenTypes = {\n"
        s += "\t{ Type = 'keyword', Style = "+lspKeyword.output()+" },\n"
        s += "\t{ Type = 'type', Style = "+lspType.output()+" },\n"
        s += "\t{ Type = 'function', Style = "+lspFunction.output()+" },\n"
        s += "\t{ Type = 'method', Style = "+lspMethod.output()+" },\n"
        s += "\t{ Type = 'class', Style = "+lspClass.output()+" },\n"
        s += "\t{ Type = 'struct', Style = "+lspStruct.output()+" },\n"
        s += "\t{ Type = 'parameter', Style = "+lspParameter.output()+" },\n"
        s += "\t{ Type = 'variable', Style = "+lspVariable.output()+" },\n"
        s += "\t{ Type = 'number', Style = "+lspNumber.output()+" },\n"
        s += "\t{ Type = 'regexp', Style = "+lspRegexp.output()+" },\n"
        s += "\t{ Type = 'operator', Style = "+lspOperator.output()+" },\n"
        s += "}\n"
        
        return s
    }
    
    func getCSSStyle() -> String {
        let formatPropertyCss = { (name: PropertyName, property: PropertyBase) -> String in
            var css = "." + name.cssClasses.joined(separator: ".") + " {\n"
            css += property.getCSSStyle()
            css += "}\n"
            return css
        }
        
        var css = ""
        
        css += "body { background-color: \(self.canvas.color); }\n"
        css += "body { color: \(self.plain.color); }\n"
        
        css += formatPropertyCss(.canvas, self.canvas)
        css += formatPropertyCss(.plain, self.plain)
        css += formatPropertyCss(.number, self.number)
        css += formatPropertyCss(.string, self.string)
        css += formatPropertyCss(.escape, self.escape)
        css += formatPropertyCss(.preProcessor, self.preProcessor)
        css += formatPropertyCss(.stringPreProc, self.stringPreProc)
        css += formatPropertyCss(.blockComment, self.blockComment)
        css += formatPropertyCss(.lineComment, self.lineComment)
        css += formatPropertyCss(.lineNum, self.lineNum)
        css += formatPropertyCss(.operator, self.operatorProp)
        css += formatPropertyCss(.interpolation, self.interpolation)
        
        for (i, keyword) in self.keywords.enumerated() {
            css += formatPropertyCss(.keyword(index: i), keyword)
        }
        
        css += formatPropertyCss(.lspHover, self.lspHover)
        css += formatPropertyCss(.lspError, self.lspError)
        css += formatPropertyCss(.lspErrorMessage, self.lspErrorMessage)
        css += formatPropertyCss(.lspType, self.lspType)
        css += formatPropertyCss(.lspClass, self.lspClass)
        css += formatPropertyCss(.lspStruct, self.lspStruct)
        css += formatPropertyCss(.lspInterface, self.lspInterface)
        css += formatPropertyCss(.lspParameter, self.lspParameter)
        css += formatPropertyCss(.lspVariable, self.lspVariable)
        css += formatPropertyCss(.lspEnumMember, self.lspEnumMember)
        css += formatPropertyCss(.lspFunction, self.lspFunction)
        css += formatPropertyCss(.lspMethod, self.lspMethod)
        css += formatPropertyCss(.lspKeyword, self.lspKeyword)
        css += formatPropertyCss(.lspNumber, self.lspNumber)
        css += formatPropertyCss(.lspRegexp, self.lspRegexp)
        css += formatPropertyCss(.lspOperator, self.lspOperator)
        
        return css
    }
    
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(font: NSFont, showColorCodes: Bool = true, extraCSS css: String = "", showLSPTokens: Bool = false) -> String {
        return getHtmlExample(fontName: font.fontName, fontSize: font.pointSize, showColorCodes: showColorCodes, extraCSS: css, showLSPTokens: showLSPTokens)
    }
    
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(fontName: String = "-", fontSize: CGFloat = NSFont.systemFontSize, showColorCodes: Bool = true, extraCSS css: String = "", showLSPTokens: Bool = false) -> String {
        var cssFont = ""
        if fontName != "" {
            cssFont = "    font-family: \(fontName != "-" ? fontName : "ui-monospace");\n    font-size: \(fontSize)pt;\n"
        }
        
        let exportProperty = { (name: PropertyName, property: PropertyBase)->String in
            return "." + name.cssClasses.joined(separator: ".") + " {\n" + property.getCSSStyle() + cssFont + " } \n"
        }
        var style = ""
        
        for name in PropertyName.allCases {
            guard name != .lspHover, !name.isKeyword, let prop = self[name] else {
                continue
            }
            if !showLSPTokens && name.isLSP {
                continue
            }
            
            style += exportProperty(name, prop)
        }
        
        for (i, keyword) in keywords.enumerated() {
            style += exportProperty(PropertyName.keyword(index: i), keyword)
        }
        
        let textColor = plain.getCSSStyle()
        var s = """
<html>
<head>
<title>\(self.name).theme :: \(self.desc)</title>
<style>
* {
    box-sizing: border-box;
}
html, body {
    background-color: \(self.canvas.color);
\(cssFont)
    user-select: none;
    -webkit-user-select: none;
    margin: 0;
    height: 100%;
}
body {
    padding: 12px;
}
.color_code {
\(cssFont)
\(textColor)
    display: \(showColorCodes ? "initial" : "none");
    text-align: right;
    font-size: .8rem;
}
table {
    border-collapse: collapse;
}
td {
    padding: 2px;
    background-color: \(self.canvas.color);
}
        
\(style)
        
\(css)
</style>
</head>
<body class="hl">
<pre class="hl">
    <table cellpadding="2" cellspacing="0">
"""
        
        let formatProp: ((PropertyName, PropertyBase)->String) = { (name, prop) in
            return """
        <tr>
            <td class="\(name.cssClasses.joined(separator: " "))">\(name.name)</td>
            <td class="color_code">\(prop.color)</td>
        </tr>
"""
        }
        
        for name in PropertyName.allCases  {
            guard name != .canvas, name != .lspHover, !name.isLSP, !name.isKeyword, let prop = self[name] else {
                continue
            }
            s += formatProp(name, prop)
        }
        
        if showLSPTokens {
            s += "<tr><td style='font-size: .5rem'>&nbsp;</td><td></td></tr>\n"
            for name in PropertyName.allCases  {
                guard name.isLSP, name != .lspHover, let prop = self[name] else {
                    continue
                }
                s += formatProp(name, prop)
            }
        }
        
        s += "<tr><td style='font-size: .5rem'>&nbsp;</td><td></td></tr>\n"
        for name in PropertyName.allCases  {
            guard name.isKeyword, let prop = self[name] else {
                continue
            }
            s += formatProp(name, prop)
        }
        
        s += """
    </table>
</pre>
</body>
</html>
"""
        return s
    }
    
    /// Get a NSAttributedString for preview the theme settings.
    public func getAttributedExample(font: NSFont, showColorCodes: Bool = true, extraCSS css: String = "", showLSPTokens: Bool = false) -> NSAttributedString {
        return getAttributedExample(fontName: font.fontName, fontSize: font.pointSize, showColorCodes: showColorCodes, extraCSS: css, showLSPTokens: showLSPTokens)
    }
    
    /// Get a NSAttributedString for preview the theme settings.
    public func getAttributedExample(fontName: String = "-", fontSize: CGFloat = NSFont.systemFontSize, showColorCodes: Bool = true, extraCSS css: String = "", showLSPTokens: Bool = false) -> NSAttributedString {
        let html = getHtmlExample(fontName: fontName, fontSize: fontSize, showColorCodes: showColorCodes, extraCSS: css, showLSPTokens: showLSPTokens)
        if let r = NSAttributedString(html: html.data(using: .utf8)!, options: [:], documentAttributes: nil) {
            return r
        } else {
            return NSAttributedString(string: "error")
        }
    }
    
    /// Get a NSAttributedString for preview the theme settings in the icon.
    /// This code don't call internally the getHtmlExample and is more (about 6x)  fast!
    internal func getAttributedExampleForIcon(font: NSFont) -> NSAttributedString {
        let s = NSMutableAttributedString()
        for name in PropertyName.allCases {
            guard !name.isLSP, let prop = self[name] as? Property else {
                continue
            }
            let prop_s = prop.getAttributedString(name: name, withFont: font)
            s.append(prop_s)
            s.append(NSAttributedString(string: "\n"))
        }
        
        return s
    }
    
    /// Get an image preview of the theme.
    /// - parameters:
    ///   - size: Image size.
    ///   - fontSize: Size of system monospaced font.
    func getImage(size: CGSize, fontSize: CGFloat) -> NSImage? {
        return self.getImage(size: size, font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular))
    }
    
    /// Get an image preview of the theme.
    /// - parameters:
    ///   - size: Image size.
    ///   - font: Font.
    func getImage(size: CGSize, font: NSFont) -> NSImage? {
        let format = getAttributedExampleForIcon(font: font)
        
        let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        if let context = CGContext(
            data: nil,
            width: Int(rect.width * scale),
            height: Int(rect.height * scale),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
            context.scaleBy(x: scale, y: scale)
            
            if let c = NSColor(fromHexString: backgroundColor) {
                context.setFillColor(c.cgColor)
                context.fill(rect)
            }
            
            let c = NSGraphicsContext.current
            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            format.draw(in: rect.insetBy(dx: 4, dy: 4))
            
            // Restore the context.
            NSGraphicsContext.current = c
            
            if !isStandalone {
                // Fill a corner to notify that this is a custom theme.
                let side = Int(Swift.min(size.height / 6, size.width / 6))
                
                context.setLineWidth(0)
                context.setFillColor(NSColor.controlAccentColor.cgColor)
                context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX - CGFloat(side), y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + CGFloat(side)))
                context.fillPath()
            }
            if let image = context.makeImage() {
                return NSImage(cgImage: image, size: CGSize(width: Int(CGFloat(context.width) / scale), height: Int(CGFloat(context.height) / scale)))
            }
        }
        
        return nil
    }
    
    public func makeIterator() -> PropertiesIterator {
        return PropertiesIterator(self)
    }
    
    @discardableResult
    public func appendKeyword(_ keyword: Property) -> PropertyName {
        return insertKeyword(keyword, at: -1)
    }
    
    @discardableResult
    public func insertKeyword(_ keyword: Property, at index: Int) -> PropertyName {
        keyword.theme = self
        let r: PropertyName
        if index >= 0 {
            keywords.insert(keyword, at: index)
            r = .keyword(index: index)
        } else {
            keywords.append(keyword)
            r = .keyword(index: keywords.count - 1)
        }
        delegate?.themeDidAddKeyword(self, keyword: keyword)
        isDirty = true
        setNeedRefresh()
        return r
    }
    
    @discardableResult
    public func removeKeyword(at index: Int) -> Property? {
        if index < 0 || index >= keywords.count {
            return nil
        }
        let keyword = keywords.remove(at: index)
        keyword.theme = nil
        
        delegate?.themeDidRemoveKeyword(self, keyword: keyword)
        isDirty = true
        setNeedRefresh()
        
        return keyword
    }
    
    func isRequireHTMLEngine(ignoringLSTokens: Bool = false) -> Bool {
        for prop_name in PropertyName.allCases {
            if ignoringLSTokens && prop_name.isLSP {
                continue
            }
            guard prop_name != .lspHover && prop_name != .lspErrorMessage else {
                continue
            }
            if let style = self[prop_name]?.getCustomStyle(for: "html"), !style.style.isEmpty {
                return true
            }
        }
        return false
    }
    
    internal func onPropertyDidChange(_ property: PropertyBase) {
        delegate?.themeDidChangeProperty(self, property: property)
        
        if !self.isDirty {
            isDirty = true
        }
        setNeedRefresh()
    }
}

extension String {
    func escapingForLua() -> String {
        var s = self.replacingOccurrences(of: "\\", with: "\\\\")
        s = s.replacingOccurrences(of: "\"", with: "\\\"")
        return s
    }
}
