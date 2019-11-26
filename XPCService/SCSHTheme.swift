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

extension Notification.Name {
    static let themeDidSaved = Notification.Name("themeDidSaved")
    static let themeDidDeleted = Notification.Name("themeDidDeleted")
}

typealias NotificationThemeSavedData = (theme: SCSHTheme, oldName: String)
typealias NotificationThemeDeletedData = (String)

public protocol SCSHThemePropertyProtocol: class {
    var color: String { get set }
    func toCSSStyle() -> String
    func output() -> String
    func toDictionary() -> [String: Any]
    
    init(color: String)
    init?(dict: [String: Any]?)
}

public protocol SCSHThemeDelegate: NSObjectProtocol {
    /// Notify the delegate that a property is changed.
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHThemePropertyProtocol)
    
    /// Notify the delegate that the categories are changed.
    func themeDidChangeCategories(_ theme: SCSHTheme)
    /// Notify the delegate that the name is changed.
    func themeDidChangeName(_ theme: SCSHTheme)
    /// Notify the delegate that the description is changed.
    func themeDidChangeDescription(_ theme: SCSHTheme)
    
    /// Notify the delegate that the dirty status is changed.
    func themeDidChangeDirtyStatus(_ theme: SCSHTheme)
    /// Notify the delegate that a new keyword is added.
    func themeDidAddKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property)
    /// Notify the delegate that a keyword is removed.
    func themeDidRemoveKeyword(_ theme: SCSHTheme, keyword: SCSHTheme.Property)
}

extension SCSHThemeDelegate {
    func themeDidChangeProperty(_ theme: SCSHTheme, property: SCSHThemePropertyProtocol) {}
    
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
    
    // MARK: - Theme Property
    public class CanvasProperty: SCSHThemePropertyProtocol {
        internal weak var theme: SCSHTheme?
        public var color: String {
            didSet {
                if oldValue != color {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
        
        required public init(color: String) {
            self.color = color
        }
        
        public required init?(dict: [String: Any]?) {
            self.color = dict?["color"] as? String ?? ""
        }
        
        public func toDictionary() -> [String: Any] {
            return [
                "color": color,
            ]
        }
        
        /// Get CSS inline style attribute for the property.
        public func toCSSStyle() -> String {
            return "    background-color: \(color); \n"
        }
        
        public func output() -> String {
            return "{ Colour=\"\(color)\" }"
        }
    }
    
    public class Property: SCSHThemePropertyProtocol {
        public enum Name: String {
            case plain = "Default"
            case canvas = "Canvas"
            case number = "Number"
            case escape = "Escape"
            case string = "String"
            case preProcessor = "PreProcessor"
            case stringPreProc = "StringPreProc"
            case blockComment = "BlockComment"
            case lineComment = "LineComment"
            case lineNum = "LineNum"
            case operatorProp = "Operator"
            case interpolation = "Interpolation"
            
            case keyword1 = "Keyword 1"
            case keyword2 = "Keyword 2"
            case keyword3 = "Keyword 3"
            case keyword4 = "Keyword 4"
            case keyword5 = "Keyword 5"
            case keyword6 = "Keyword 6"
            case keyword7 = "Keyword 7"
            case keyword8 = "Keyword 8"
            case keyword9 = "Keyword 9"
            case keyword10 = "Keyword 10"
            case keyword11 = "Keyword 11"
            case keyword12 = "Keyword 12"
            case keyword13 = "Keyword 13"
            case keyword14 = "Keyword 14"
            case keyword15 = "Keyword 15"
            case keyword16 = "Keyword 16"
            case keyword17 = "Keyword 17"
            case keyword18 = "Keyword 18"
            case keyword19 = "Keyword 19"
            case keyword20 = "Keyword 20"
            case keyword21 = "Keyword 21"
            case keyword22 = "Keyword 22"
            case keyword23 = "Keyword 23"
            case keyword24 = "Keyword 24"
            case keyword25 = "Keyword 25"
            case keyword26 = "Keyword 26"
            
            static let first: Name = standardProperties.first!
            static let last: Name = .keyword26
            
            static let standardProperties: [Name] = [.canvas, .plain, .number, .string, .operatorProp, .blockComment, .lineComment, .lineNum, .escape, .preProcessor, .stringPreProc, .interpolation]
            
            /// Returns a progressive index (zero based) of a keyword property name.
            /// Returns nil if the name is not a keyword.
            public static func indexOfKeyword(_ name: Name) -> Int? {
                switch name {
                case .keyword1:
                    return 0
                case .keyword2:
                    return 1
                case .keyword3:
                    return 2
                case .keyword4:
                    return 3
                case .keyword5:
                    return 4
                case .keyword6:
                    return 5
                case .keyword7:
                    return 6
                case .keyword8:
                    return 7
                case .keyword9:
                    return 8
                case .keyword10:
                    return 9
                case .keyword11:
                    return 10
                case .keyword12:
                    return 11
                case .keyword13:
                    return 12
                case .keyword14:
                    return 13
                case .keyword15:
                    return 14
                case .keyword16:
                    return 15
                case .keyword17:
                    return 16
                case .keyword18:
                    return 17
                case .keyword19:
                    return 18
                case .keyword20:
                    return 19
                case .keyword21:
                    return 20
                case .keyword22:
                    return 21
                case .keyword23:
                    return 22
                case .keyword24:
                    return 23
                case .keyword25:
                    return 24
                case .keyword26:
                    return 25
                    
                default:
                    return nil
                }
            }
            
            /// Returns the keyword name at index (zero based) specified.
            /// Returns nil if the index is out of bounds.
            public static func keywordAtIndex(_ index: Int) -> Name? {
                switch index {
                case 0:
                    return .keyword1
                case 1:
                    return .keyword2
                case 2:
                    return .keyword3
                case 3:
                    return .keyword4
                case 4:
                    return .keyword5
                case 5:
                    return .keyword6
                case 6:
                    return .keyword7
                case 7:
                    return .keyword8
                case 8:
                    return .keyword9
                case 9:
                    return .keyword10
                case 10:
                    return .keyword11
                case 11:
                    return .keyword12
                case 12:
                    return .keyword13
                case 13:
                    return .keyword14
                case 14:
                    return .keyword15
                case 15:
                    return .keyword16
                case 16:
                    return .keyword17
                case 17:
                    return .keyword18
                case 18:
                    return .keyword19
                case 19:
                    return .keyword20
                case 20:
                    return .keyword21
                case 21:
                    return .keyword22
                case 22:
                    return .keyword23
                case 23:
                    return .keyword24
                case 24:
                    return .keyword25
                case 25:
                    return .keyword26
                    
                default:
                    return nil
                }
            }
            
            /// Returns the property name at index (zero based).
            public static func nameAtIndex(_ index: Int) -> Name? {
                if index < standardProperties.count {
                    return standardProperties[index]
                } else {
                    if let keyword = Name.keywordAtIndex(index - Name.standardProperties.count) {
                        return keyword
                    } else {
                        return nil
                    }
                }
            }
            
            /// Returns the property name based of the associated CSS class.
            public static func nameForCSSClass(_ className: String) -> Name? {
                switch className {
                case "hl":
                    return .plain // .canvas
                case "num":
                    return .number
                case "esc":
                    return .escape
                case "str":
                    return .string
                case "ppc":
                    return .preProcessor
                case "pps":
                    return .stringPreProc
                case "com":
                    return .blockComment
                case "slc":
                    return .lineComment
                case "lin":
                    return .lineNum
                case "opt":
                    return .operatorProp
                case "ipl":
                    return .interpolation
                default:
                    if className.hasPrefix("kw") {
                        if let n = className.last?.asciiValue {
                            return Name.keywordAtIndex(Int(n - 97))
                        }
                    }
                    return nil
                }
            }
            
            /// Returns the next property name.
            public var next: Name? {
                if self == Name.standardProperties.last {
                    return .keyword1
                } else if let i = Name.standardProperties.firstIndex(of: self) {
                    return Name.standardProperties[i+1]
                } else if let k = Name.indexOfKeyword(self) {
                    return Name.keywordAtIndex(k+1)
                } else {
                    return nil
                }
            }
            
            /// Returns the previous property name.
            public var prev: Name? {
                if let i = Name.standardProperties.firstIndex(of: self) {
                    if i == 0 {
                        return nil
                    } else {
                        return Name.standardProperties[i-1]
                    }
                } else if let k = Name.indexOfKeyword(self) {
                    if k == 0 {
                        return  Name.standardProperties.last
                    } else {
                        return Name.keywordAtIndex(k-1)
                    }
                } else {
                    return nil
                }
            }
            
            /// Returns a description of the property.
            public var description: String {
                switch self {
                case .plain:
                    return "Plain text"
                case .canvas:
                    return "Background"
                case .number:
                    return "Numbers"
                case .escape:
                    return "Escape sequences"
                case .string:
                    return "Strings"
                case .preProcessor:
                    return "Preprocessor directives"
                case .stringPreProc:
                    return "Strings within directives"
                case .blockComment:
                    return "Block comments"
                case .lineComment:
                    return "Line comments"
                case .lineNum:
                    return "Line numbers"
                case .operatorProp:
                    return "Operators"
                case .interpolation:
                    return "Interpolation sequences"
                case .keyword1, .keyword2, .keyword3, .keyword4, .keyword5, .keyword6, .keyword7, .keyword8, .keyword9, .keyword10, .keyword11, .keyword12, .keyword13, .keyword14, .keyword15, .keyword16, .keyword17, .keyword18, .keyword19, .keyword20, .keyword21, .keyword22, .keyword23, .keyword24, .keyword25, .keyword26:
                    if let index = Name.indexOfKeyword(self) {
                        return "Keyword \(index + 1)"
                    }
                    return "?"
                }
            }
            
            /// Returns if the property is a keyword.
            var isKeyword: Bool {
                switch self {
                case .keyword1, .keyword2, .keyword3, .keyword4, .keyword5, .keyword6, .keyword7, .keyword8, .keyword9, .keyword10, .keyword11, .keyword12, .keyword13, .keyword14, .keyword15, .keyword16, .keyword17, .keyword18, .keyword19, .keyword20, .keyword21, .keyword22, .keyword23, .keyword24, .keyword25, .keyword26:
                    return true
                default:
                    return false
                }
            }
            
            var keywordIndex: Int? {
                guard self.isKeyword else {
                    return nil
                }
                return Name.indexOfKeyword(self)
            }
            
            /// Return the CSS classes associated to the name.
            func getCSSClasses() -> [String] {
                switch self {
                case .plain:
                    return ["hl"]
                case .canvas:
                    return ["hl"]
                case .number:
                    return ["hl", "num"]
                case .escape:
                    return ["hl", "esc"]
                case .string:
                    return ["hl", "str"]
                case .preProcessor:
                    return ["hl", "ppc"]
                case .stringPreProc:
                    return ["hl", "pps"]
                case .blockComment:
                    return ["hl", "com"]
                case .lineComment:
                    return ["hl", "slc"]
                case .lineNum:
                    return ["hl", "lin"]
                case .operatorProp:
                    return ["hl", "opt"]
                case .interpolation:
                    return ["hl", "ipl"]
                    
                case .keyword1, .keyword2, .keyword3, .keyword4, .keyword5, .keyword6, .keyword7, .keyword8, .keyword9, .keyword10, .keyword11, .keyword12, .keyword13, .keyword14, .keyword15, .keyword16, .keyword17, .keyword18, .keyword19, .keyword20, .keyword21, .keyword22, .keyword23, .keyword24, .keyword25, .keyword26:
                    if let index = Name.indexOfKeyword(self) {
                        return ["hl", "kw" + String(UnicodeScalar(UInt8(97 + index)))]
                    }
                    return []
                }
            }
        }
        
        internal weak var theme: SCSHTheme?
        
        public var color: String {
            didSet {
                if oldValue != color {
                    self.theme?.onPropertyDidChange(self)
                }
            }
        }
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
            self.color = color
            self.isBold = false
            self.isItalic = false
            self.isUnderline = false
        }
        
        public init(color: String, isBold: Bool = false, isItalic: Bool = false, isUnderline: Bool = false) {
            self.color = color
            self.isBold = isBold
            self.isItalic = isItalic
            self.isUnderline = isUnderline
        }
        
        required public convenience init?(dict: [String: Any]?) {
            self.init(color: dict?["color"] as? String ?? "", isBold: dict?["bold"] as? Bool ?? false, isItalic:  dict?["italic"] as? Bool ?? false, isUnderline: dict?["underline"] as? Bool ?? false)
        }
        
        public func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [
                "color": color,
            ]
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
        public func toCSSStyle() -> String {
            var css = ""
            if color != "" {
                css += "    color: \(color);\n"
            }
            if isBold {
                css += "    font-weight: bold;\n"
            }
            if isItalic {
                css += "    font-style: italic;\n"
            }
            if isUnderline {
                css += "    text-decoration: underline;\n"
            }
            return css
        }
        
        public func output() -> String {
            var s = "{ Colour=\"\(color)\""
            if isBold {
                s += ", Bold=true"
            }
            if isItalic {
                s += ", Italic=true"
            }
            if isUnderline {
                s += ", Underline=true"
            }
            s += " }"
            return s
        }
    }
    
    // MARK: - Theme Properties Iterator
    public struct PropertiesIterator: IteratorProtocol {
        let theme: SCSHTheme
        private var index: Property.Name?

        init(_ theme: SCSHTheme) {
            self.theme = theme
        }

        mutating public func next() -> SCSHThemePropertyProtocol? {
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
        case missingProperty(name: Property.Name)
        case missingProperties
        case missingUrl
    }
    
    // MARK: -
    weak var delegate: SCSHThemeDelegate?
    
    public var name: String {
        didSet {
            if oldValue != name {
                delegate?.themeDidChangeName(self)
                if !self.isDirty {
                    self.isDirty = true
                }
            }
        }
    }
    internal var originalName: String = ""
    
    public var desc: String {
        didSet {
            if oldValue != desc {
                delegate?.themeDidChangeDescription(self)
                if !self.isDirty {
                    self.isDirty = true
                }
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
            }
        }
    }
        
    /// Indicate if the theme is a standard provided by highlight.
    /// Set to false to allow the customization.
    public var isStandalone: Bool = true
    
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
        return Property.Name.standardProperties.count + keywords.count
    }

    subscript(name: Property.Name) -> SCSHThemePropertyProtocol? {
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
        case .operatorProp:
            return self.operatorProp
        case .interpolation:
            return self.interpolation
        case .keyword1, .keyword2, .keyword3, .keyword4, .keyword5, .keyword6, .keyword7, .keyword8, .keyword9, .keyword10, .keyword11, .keyword12, .keyword13, .keyword14, .keyword15, .keyword16, .keyword17, .keyword18, .keyword19, .keyword20, .keyword21, .keyword22, .keyword23, .keyword24, .keyword25, .keyword26:
            if let i = Property.Name.indexOfKeyword(name), i >= 0 && i < keywords.count {
                return keywords[i]
            }
            
            return nil
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
    
    private(set) var keywords: [Property] = []
    
    @objc dynamic var isDirty: Bool = false {
        didSet {
            if oldValue != isDirty {
                delegate?.themeDidChangeDirtyStatus(self)
            }
        }
    }
    
    public init(name: String, desc: String, categories: Set<String>, plain: Property, canvas: CanvasProperty, number: Property, string: Property, escape: Property, preProcessor: Property, stringPreProc: Property, blockComment: Property, lineComment: Property, lineNum: Property, operatorProp: Property, interpolation: Property, keywords: [Property]) {
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
        
        self.keywords = keywords
        
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
        
        self.isDirty = true
    }
    
    convenience public init(name: String) {
        self.init(name: name, desc: "", categories: ["light"], plain: Property(color: "#000000"), canvas: CanvasProperty(color: "#ffffff"), number: Property(), string: Property(), escape: Property(), preProcessor: Property(), stringPreProc: Property(), blockComment: Property(), lineComment: Property(), lineNum: Property(), operatorProp: Property(), interpolation: Property(), keywords: [])
    }
    
    convenience public init?(dict dictionary: [String: Any]?) {
        guard let dict = dictionary else {
            return nil
        }
        let name = dict["name"] as? String ?? ""
        let desc = dict["desc"] as? String ?? ""
        let categories = dict["categories"] as? Set<String> ?? []
        
        guard let plain = Property(dict: dict[Property.Name.plain.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let canvas = CanvasProperty(dict: dict[Property.Name.canvas.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let number = Property(dict: dict[Property.Name.number.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let string = Property(dict: dict[Property.Name.string.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let escape = Property(dict: dict[Property.Name.escape.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let preProcessor = Property(dict: dict[Property.Name.preProcessor.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let stringPreProc = Property(dict: dict[Property.Name.stringPreProc.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let blockComment = Property(dict: dict[Property.Name.blockComment.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let lineComment = Property(dict: dict[Property.Name.lineComment.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let lineNum = Property(dict: dict[Property.Name.lineNum.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let operatorProp = Property(dict: dict[Property.Name.operatorProp.rawValue] as? [String: Any]) else {
            return nil
        }
        guard let interpolation = Property(dict: dict[Property.Name.interpolation.rawValue] as? [String: Any]) else {
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
        
        self.init(name: name, desc: desc, categories: categories, plain: plain, canvas: canvas, number: number, string: string, escape: escape, preProcessor: preProcessor, stringPreProc: stringPreProc, blockComment: blockComment, lineComment: lineComment, lineNum: lineNum, operatorProp: operatorProp, interpolation: interpolation, keywords: keywords)
        
        self.originalName = dict["originalName"] as? String ?? ""
        self.isDirty = false
        if let standalone = dict["standalone"] as? Bool {
            self.isStandalone = standalone
        }
    }
    
    public func toDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "name": name,
            "originalName": originalName,
            "desc": desc,
            "categories": categories,
            
            Property.Name.plain.rawValue: plain.toDictionary(),
            Property.Name.canvas.rawValue: canvas.toDictionary(),
            Property.Name.number.rawValue: number.toDictionary(),
            Property.Name.string.rawValue: string.toDictionary(),
            Property.Name.escape.rawValue: escape.toDictionary(),
            Property.Name.preProcessor.rawValue: preProcessor.toDictionary(),
            Property.Name.stringPreProc.rawValue: stringPreProc.toDictionary(),
            Property.Name.blockComment.rawValue: blockComment.toDictionary(),
            Property.Name.lineComment.rawValue: lineComment.toDictionary(),
            Property.Name.lineNum.rawValue: lineNum.toDictionary(),
            Property.Name.operatorProp.rawValue: operatorProp.toDictionary(),
            Property.Name.interpolation.rawValue: interpolation.toDictionary(),
            
            "keywords": keywords.map({ $0.toDictionary() }),
            
            "standalone": isStandalone,
        ]
        
        return dict
    }
    
    func save(to url: URL) throws {
        var s = "Description=\"\(desc.escapingForLua())\"\n\n"
        s += "Categories = {" + categories.map({ "\"" + $0.escapingForLua() + "\"" }).joined(separator: ", ") + "}\n\n"
        
        s += Property.Name.plain.rawValue + " = " + plain.output() + "\n"
        s += Property.Name.canvas.rawValue + " = " + canvas.output() + "\n"
        s += Property.Name.number.rawValue + " = " + number.output() + "\n"
        s += Property.Name.string.rawValue + " = " + string.output() + "\n"
        s += Property.Name.escape.rawValue + " = " + escape.output() + "\n"
        s += Property.Name.preProcessor.rawValue + " = " + preProcessor.output() + "\n"
        s += Property.Name.stringPreProc.rawValue + " = " + stringPreProc.output() + "\n"
        s += Property.Name.blockComment.rawValue + " = " + blockComment.output() + "\n"
        s += Property.Name.lineComment.rawValue + " = " + lineComment.output() + "\n"
        s += Property.Name.lineNum.rawValue + " = " + lineNum.output() + "\n"
        s += Property.Name.operatorProp.rawValue + " = " + operatorProp.output() + "\n"
        s += Property.Name.interpolation.rawValue + " = " + interpolation.output() + "\n"
        
        s += "\nKeywords = {\n\t" +
            keywords.map({ $0.output() }).joined(separator: ", \n\t") +
            "\n}\n\n"
        do {
            try s.write(to: url, atomically: true, encoding: .utf8)
            isDirty = false
            originalName = url.deletingPathExtension().lastPathComponent
            name = originalName
        } catch {
            throw error
        }
    }
    
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(font: NSFont, smartCaption: Bool, showColorCodes: Bool = true, extraCSS css: String = "") -> String {
        return getHtmlExample(fontName: font.fontName, fontSize: Float(font.pointSize), smartCaption: smartCaption, showColorCodes: showColorCodes, extraCSS: css)
    }
    
    /// Get a html code for preview the theme settings.
    public func getHtmlExample(fontName: String = "Menlo", fontSize: Float = 12, smartCaption: Bool = false, showColorCodes: Bool = true, extraCSS css: String = "") -> String {
        var cssFont = ""
        if fontName != "" {
            cssFont = "    font-family: \(fontName);\n    font-size: \(fontSize)pt;\n"
        }
        
        let exportProperty = { (name: Property.Name, property: SCSHThemePropertyProtocol)->String in
            return "." + name.getCSSClasses().joined(separator: ".") + " {\n" + property.toCSSStyle() + cssFont + " } \n"
        }
        var style = ""
        
        for name in Property.Name.standardProperties {
            guard let prop = self[name] else {
                continue
            }
            
            style += exportProperty(name, prop)
        }
        
        for (i, keyword) in keywords.enumerated() {
            if let name = Property.Name.keywordAtIndex(i) {
                style += exportProperty(name, keyword)
            }
        }
        
        let textColor = plain.toCSSStyle()
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
    padding: 1em;
}
.color_code {
\(cssFont)
\(textColor)
    display: \(showColorCodes ? "initial" : "none");
    text-align: right;
}
table {
    width: 100%;
    border-collapse: collapse;
}
td {
    padding: 2px;
}
        
\(style)
        
\(css)
</style>
</head>
<body class="hl">
    <pre class="hl"><table>
"""
        var name = Property.Name.standardProperties.first
        while name != nil {
            if name == .canvas {
                name = name!.next
                continue
            }
            guard let prop = self[name!] else {
                break
            }
            s += """
        <tr>
            <td class="\(name!.getCSSClasses().joined(separator: " "))">\(smartCaption ? name!.rawValue : name!.description)</td>
            <td class="color_code">\(prop.color)</td>
        </tr>
"""
            name = name!.next
        }
        
        s += """
    </table></pre>
</body>
</html>
"""
        return s
    }
    
    /// Get a NSAttributedString for preview the theme settings.
    public func getAttributedExample(font: NSFont, smartCaption: Bool = false, showColorCodes: Bool = true, extraCSS css: String = "") -> NSAttributedString {
        return getAttributedExample(fontName: font.fontName, fontSize: Float(font.pointSize), smartCaption: smartCaption, showColorCodes: showColorCodes, extraCSS: css)
    }
    
    /// Get a NSAttributedString for preview the theme settings.
    public func getAttributedExample(fontName: String = "Menlo", fontSize: Float = 12, smartCaption: Bool = false, showColorCodes: Bool = true, extraCSS css: String = "") -> NSAttributedString {
        return NSAttributedString(html: getHtmlExample(fontName: fontName, fontSize: fontSize, smartCaption: smartCaption, showColorCodes: showColorCodes, extraCSS: css).data(using: .utf8)!, options: [:], documentAttributes: nil)!
    }
    
    /// Get a NSAttributedString for preview the theme settings in the icon.
    /// This code don't call internally the getHtmlExample and is more (about 6x)  fast!
    internal func getAttributedExampleForIcon(font: NSFont) -> NSAttributedString {
        let color = NSColor(fromHexString: self.backgroundColor) ?? NSColor.black
        
        let s = NSMutableAttributedString()
        var name = Property.Name.standardProperties.first
        while name != nil {
            guard let prop = self[name!] as? Property else {
                name = name!.next
                continue
            }
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .backgroundColor: color,
                .foregroundColor: NSColor(fromHexString: prop.color) ?? NSColor.black
            ]
            if prop.isUnderline {
                attributes[.underlineStyle] = NSUnderlineStyle.single
            }
            var fontTraits: NSFontTraitMask = []
            if prop.isBold {
                fontTraits.insert(.boldFontMask)
            } else if prop.isItalic {
                fontTraits.insert(.italicFontMask)
            }
            attributes[.font] = font
            if !fontTraits.isEmpty, let f = NSFontManager.shared.font(withFamily: font.familyName ?? font.fontName, traits: fontTraits, weight: 0, size: font.pointSize) {
                attributes[.font] = f
            }
            
            s.append(NSAttributedString(string: name!.description + "\n", attributes: attributes))
            name = name!.next
        }
        
        return s
    }
    
    /// Get an image preview of the theme.
    /// - parameters:
    ///   - size: Image size.
    ///   - font: Font.
    func getImage(size: CGSize, font: NSFont) -> NSImage? {
        let format = getAttributedExampleForIcon(font: font)
        
        let rect = CGRect(origin: .zero, size: size)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(
            data: nil,
            width: Int(rect.width),
            height: Int(rect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
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
                context.setLineWidth(0)
                context.setFillColor(NSColor.controlAccentColor.cgColor)
                context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX-20, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY+20))
                context.fillPath()
            }
            
            if let image = context.makeImage() {
                return NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
            }
        }
        return nil
    }
    
    public func makeIterator() -> PropertiesIterator {
        return PropertiesIterator(self)
    }
    
    public func appendKeyword(_ keyword: Property) {
        keyword.theme = self
        keywords.append(keyword)
        delegate?.themeDidAddKeyword(self, keyword: keyword)
        isDirty = true
    }
    public func insertKeyword(_ keyword: Property, at index: Int) {
        keyword.theme = self
        keywords.insert(keyword, at: index)
        delegate?.themeDidAddKeyword(self, keyword: keyword)
        isDirty = true
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
        
        return keyword
    }
    
    internal func onPropertyDidChange(_ property: SCSHThemePropertyProtocol) {
        delegate?.themeDidChangeProperty(self, property: property)
        
        if !self.isDirty {
            isDirty = true
        }
    }
}

extension String {
    func escapingForLua() -> String {
        var s = self.replacingOccurrences(of: "\\", with: "\\\\")
        s = s.replacingOccurrences(of: "\"", with: "\\\"")
        return s
    }
}
