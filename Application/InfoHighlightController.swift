//
//  InfoHighlightController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 24/11/2019.
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

class InfoHighlightController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var text: String = "" {
        didSet {
            textView?.string = text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.string = text
        if #available(OSX 10.15, *) {
            textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
        } else {
            // Fallback on earlier versions
            textView.font = NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11)
        }
        
        if text.isEmpty {
            progressIndicator.startAnimation(self)
            (NSApplication.shared.delegate as? AppDelegate)?.service?.highlightInfo(reply: { (t) in
                self.text = t
                self.progressIndicator.stopAnimation(self)
            })
        }
    }
}
