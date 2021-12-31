//
//  Service+App.swift
//  Syntax Highlight
//
//  Created by Sbarex on 02/04/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

extension SettingsBase {
    @objc var hasAdvancedSettings: Bool {
        return (self.isCSSDefined && !self.css.isEmpty) || (self.isArgumentsDefined && !self.arguments.isEmpty)
    }
}

extension SettingsFormat {
    @objc override var hasAdvancedSettings: Bool {
        return super.hasAdvancedSettings || (isPreprocessorDefined && !preprocessor.trimmingCharacters(in: .whitespaces).isEmpty) || (isSyntaxDefined && !syntax.isEmpty) || (isAppendArgumentsDefined && !appendArguments.isEmpty) || isUsingLSP
    }
    
    var isLSPValid: Bool {
        return isUsingLSP && !self.lspExecutable.isEmpty && FileManager.default.isExecutableFile(atPath: self.lspExecutable)
    }
    
    var LSPImage: NSImage? {
        return NSImage(named: useLSP ? (isLSPValid ? NSImage.statusAvailableName : NSImage.statusUnavailableName) : NSImage.statusNoneName)
    }
    
    var LSPRequireHTML: Bool {
        return useLSP && lspHover
    }
}

extension Settings {
    var isGitValid: Bool {
        return isVCS && !self.gitPath.isEmpty && FileManager.default.isExecutableFile(atPath: self.gitPath)
    }
    
    var isHgValid: Bool {
        return isVCS && !self.hgPath.isEmpty && FileManager.default.isExecutableFile(atPath: self.hgPath)
    }
    
    var isSVNValid: Bool {
        return isVCS && !self.svnPath.isEmpty && FileManager.default.isExecutableFile(atPath: self.svnPath)
    }

    @objc override var hasAdvancedSettings: Bool {
        return super.hasAdvancedSettings || self.isDebug || self.convertEOL
    }
}
