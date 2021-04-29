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

import Foundation
import Lua

extension SCSHTheme.Property {
    /// Initialize from a Lua Table.
    convenience init(table: Table?) {
        let color = table?["Colour"] as? String ?? ""
        let isBold = table?["Bold"] as? Bool ?? false
        let isItalic = table?["Italic"] as? Bool ?? false
        let isUnderline = table?["Underline"] as? Bool ?? false
        
        self.init(color: color, isBold: isBold, isItalic: isItalic, isUnderline: isUnderline)
    }
}

extension SCSHTheme.CanvasProperty {
    /// Initialize from a Lua Table.
    convenience init(table: Table?) {
        let color = table?["Colour"] as? String ?? ""
        
        self.init(color: color)
    }
}

extension SCSHTheme {
    /** states which may occurs during input file parsing */
    fileprivate enum State: Int {
        case STANDARD=0
        case STRING
        case NUMBER
        case SL_COMMENT
        case ML_COMMENT
        case ESC_CHAR
        case DIRECTIVE
        case DIRECTIVE_STRING
        case LINENUMBER
        case SYMBOL
        case STRING_INTERPOLATION

        // don't use constants > KEYWORD as array indices!
        case KEYWORD
        case STRING_END
        case NUMBER_END
        case SL_COMMENT_END
        case ML_COMMENT_END
        case ESC_CHAR_END
        case DIRECTIVE_END
        case SYMBOL_END
        case STRING_INTERPOLATION_END
        case KEYWORD_END
        case IDENTIFIER_BEGIN
        case IDENTIFIER_END
        case EMBEDDED_CODE_BEGIN
        case EMBEDDED_CODE_END

        case _UNKNOWN=100
        case _REJECT
        case _EOL
        case _EOF
        case _WS
        case _TESTPOS
    }
    
    /** output formats */
    fileprivate enum OutputType: Int {
        case HTML
        case XHTML
        case TEX
        case LATEX
        case RTF
        case ESC_ANSI
        case ESC_XTERM256
        case HTML32_UNUSED
        case SVG
        case BBCODE
        case PANGO
        case ODTFLAT
        case ESC_TRUECOLOR
    }
    
    enum LuaError: Error {
        case error(message: String)
    }
    
    /// Initialize loading a Lua file.
    convenience init(url: URL) throws {
        let REGEX_IDENTIFIER = "[a-zA-Z_]\\w*"
        let REGEX_NUMBER = "(?:0x|0X)[0-9a-fA-F]+|\\d*[\\.]?\\d+(?:[eE][\\-\\+]\\d+)?[lLuU]*"
        
        let name = url.deletingPathExtension().lastPathComponent
        
        let vm = Lua.VirtualMachine(openLibs: true)

        vm.globals["HL_LANG_DIR"] = ""
       
        let pluginParameter = ""
        vm.globals["HL_INPUT_FILE"] = pluginParameter
        vm.globals["HL_PLUGIN_PARAM"] = pluginParameter
        
        vm.globals["HL_OUTPUT"] = ""

        vm.globals["Identifiers"]=REGEX_IDENTIFIER;
        vm.globals["Digits"]=REGEX_NUMBER

        // Initialize environment for hook functions
        vm.globals["HL_STANDARD"]=State.STANDARD.rawValue
        vm.globals["HL_STRING"]=State.STRING.rawValue
        vm.globals["HL_NUMBER"]=State.NUMBER.rawValue
        vm.globals["HL_LINE_COMMENT"]=State.SL_COMMENT.rawValue
        vm.globals["HL_BLOCK_COMMENT"]=State.ML_COMMENT.rawValue
        vm.globals["HL_ESC_SEQ"]=State.ESC_CHAR.rawValue
        vm.globals["HL_PREPROC"]=State.DIRECTIVE.rawValue
        vm.globals["HL_PREPROC_STRING"]=State.DIRECTIVE_STRING.rawValue
        vm.globals["HL_OPERATOR"]=State.SYMBOL.rawValue
        vm.globals["HL_LINENUMBER"]=State.LINENUMBER.rawValue
        vm.globals["HL_INTERPOLATION"]=State.STRING_INTERPOLATION.rawValue
        vm.globals["HL_KEYWORD"]=State.KEYWORD.rawValue
        vm.globals["HL_STRING_END"]=State.STRING_END.rawValue
        vm.globals["HL_LINE_COMMENT_END"]=State.SL_COMMENT_END.rawValue
        vm.globals["HL_BLOCK_COMMENT_END"]=State.ML_COMMENT_END.rawValue
        vm.globals["HL_ESC_SEQ_END"]=State.ESC_CHAR_END.rawValue
        vm.globals["HL_PREPROC_END"]=State.DIRECTIVE_END.rawValue
        vm.globals["HL_OPERATOR_END"]=State.SYMBOL_END.rawValue
        vm.globals["HL_KEYWORD_END"]=State.KEYWORD_END.rawValue
        vm.globals["HL_EMBEDDED_CODE_BEGIN"]=State.EMBEDDED_CODE_BEGIN.rawValue
        vm.globals["HL_EMBEDDED_CODE_END"]=State.EMBEDDED_CODE_END.rawValue
        vm.globals["HL_IDENTIFIER_BEGIN"]=State.IDENTIFIER_BEGIN.rawValue
        vm.globals["HL_IDENTIFIER_END"]=State.IDENTIFIER_END.rawValue

        vm.globals["HL_INTERPOLATION_END"]=State.STRING_INTERPOLATION_END.rawValue
        vm.globals["HL_UNKNOWN"]=State._UNKNOWN.rawValue
        vm.globals["HL_REJECT"]=State._REJECT.rawValue
        vm.globals["HL_FORMAT_HTML"] = OutputType.HTML.rawValue
        vm.globals["HL_FORMAT_XHTML"] = OutputType.XHTML.rawValue
        vm.globals["HL_FORMAT_TEX"] = OutputType.TEX.rawValue
        vm.globals["HL_FORMAT_LATEX"] = OutputType.LATEX.rawValue
        vm.globals["HL_FORMAT_RTF"] = OutputType.RTF.rawValue
        vm.globals["HL_FORMAT_ANSI"] = OutputType.ESC_ANSI.rawValue
        vm.globals["HL_FORMAT_XTERM256"] = OutputType.ESC_XTERM256.rawValue
        vm.globals["HL_FORMAT_TRUECOLOR"] = OutputType.ESC_TRUECOLOR.rawValue
        vm.globals["HL_FORMAT_SVG"] = OutputType.SVG.rawValue
        vm.globals["HL_FORMAT_BBCODE"] = OutputType.BBCODE.rawValue
        vm.globals["HL_FORMAT_PANGO"] = OutputType.PANGO.rawValue
        vm.globals["HL_FORMAT_ODT"] = OutputType.ODTFLAT.rawValue

        // default values for --verbose
        vm.globals["IgnoreCase"]=false
        vm.globals["EnableIndentation"]=false
        vm.globals["DisableHighlighting"]=false

        let r = vm.eval(url)
        
        switch r {
        case .values(_):
            let desc = vm.globals["Description"] as? String ?? ""
            let categories: [String]
            if let a = vm.globals["Categories"] as? Table {
                categories = a.asSequence()
            } else {
                categories = []
            }
            
            let plain = Property(table: vm.globals[Property.Name.plain.rawValue] as? Table)
            let canvas = CanvasProperty(table: vm.globals[Property.Name.canvas.rawValue] as? Table)
            let number = Property(table: vm.globals[Property.Name.number.rawValue] as? Table)
            let string = Property(table: vm.globals[Property.Name.string.rawValue] as? Table)
            let escape = Property(table: vm.globals[Property.Name.escape.rawValue] as? Table)
            let preProcessor = Property(table: vm.globals[Property.Name.preProcessor.rawValue] as? Table)
            let stringPreProc = Property(table: vm.globals[Property.Name.stringPreProc.rawValue] as? Table)
            let blockComment = Property(table: vm.globals[Property.Name.blockComment.rawValue] as? Table)
            let lineComment = Property(table: vm.globals[Property.Name.lineComment.rawValue] as? Table)
            let lineNum = Property(table: vm.globals[Property.Name.lineNum.rawValue] as? Table)
            let operatorProp = Property(table: vm.globals[Property.Name.operatorProp.rawValue] as? Table)
            let interpolation = Property(table: vm.globals[Property.Name.interpolation.rawValue] as? Table)

            var keywords: [Property] = []
            if let kk = vm.globals["Keywords"] as? Table {
                for n in kk.keys() {
                    if let t = kk[n] as? Table {
                        keywords.append(Property(table: t))
                    } else {
                        print(n)
                    }
                }
            }
            
            self.init(name: name, desc: desc, categories: Set<String>(categories), plain: plain, canvas: canvas, number: number, string: string, escape: escape, preProcessor: preProcessor, stringPreProc: stringPreProc, blockComment: blockComment, lineComment: lineComment, lineNum: lineNum, operatorProp: operatorProp, interpolation: interpolation, keywords: keywords)
            originalName = name
            self.path = url.path
            self.isDirty = false
        case .error(let s):
            throw LuaError.error(message: s)
        }
    }
}
