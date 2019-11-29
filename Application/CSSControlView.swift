//
//  CSSControlView.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 16/11/2019.
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

class CSSControlView: NSViewController {
    var cssCode: String = "" {
        didSet {
            textView?.string = cssCode
        }
    }
    var isUTIWarningHidden: Bool = true {
        didSet {
            warningMessage?.isHidden = isUTIWarningHidden
        }
    }
    var handler: ((String)->Void)?
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var warningMessage: NSTextField!
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            NSHelpManager.shared.openHelpAnchor("SyntaxHighlight_CUSTOMCSS", inBook: locBookName)
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        handler?(textView.string)
        dismiss(sender)
    }
    
    override func viewDidLoad() {
        warningMessage.isHidden = isUTIWarningHidden
        textView?.string = cssCode
        
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
    }
}
