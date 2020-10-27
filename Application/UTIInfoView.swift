//
//  UTIInfoView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 24/09/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa

fileprivate enum InfoItem {
    case single(name: String, value: String)
    case multiple(name: String, values: [InfoItem])
}

class UTIInfoView: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var outlineView: NSOutlineView!
    
    fileprivate var info : [InfoItem] = []
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)

        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
    }
    
    func initFromUTI(_ uti: UTI) {
        info = []
        info.append(InfoItem.single(name: "Description", value: uti.description))
        
        if uti.extensions.count > 1 {
            var extensions: [InfoItem] = []
            for (i, ext) in uti.extensions.enumerated() {
                extensions.append(InfoItem.single(name: "Item \(i+1)", value: ext))
            }
            info.append(InfoItem.multiple(name: "Extensions", values: extensions))
        } else if uti.extensions.count == 1 {
            info.append(InfoItem.single(name: "Extension", value: uti.extensions.first!))
        }
        
        if uti.mimeTypes.count > 1 {
            var mimes: [InfoItem] = []
            for (i, mime) in uti.mimeTypes.enumerated() {
                mimes.append(InfoItem.single(name: "Item \(i+1)", value: mime))
            }
            info.append(InfoItem.multiple(name: "Mime Types", values: mimes))
        } else if uti.mimeTypes.count == 1 {
            info.append(InfoItem.single(name: "Mime Type", value: uti.mimeTypes.first!))
        }
        
        info.append(InfoItem.single(name: "UTI", value: uti.UTI))
        if uti.conformsTo.count > 1 {
            var conforms: [InfoItem] = []
            for (i, uti) in uti.conformsTo.enumerated() {
                conforms.append(InfoItem.single(name: "Item \(i+1)", value: uti))
            }
            info.append(InfoItem.multiple(name: "Conforms to", values: conforms))
        } else if uti.conformsTo.count == 1 {
            info.append(InfoItem.single(name: "Conform to", value: uti.conformsTo.first!))
        }
        info.append(InfoItem.single(name: "Is dynamic", value: uti.isDynamic ? "Yes" : "No"))
        
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
}

extension UTIInfoView: NSOutlineViewDelegate {
    
}


extension UTIInfoView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return info[index]
        } else if let info = item as? InfoItem {
            switch info {
            case .single(_, _):
                return info
            case .multiple(_, let values):
                return values[index]
            }
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let info = item as? InfoItem else {
            return false
        }
        switch info {
        case .single(_, _):
            return false
        case .multiple(_, let values):
            return values.count > 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return info.count
        } else if let info = item as? InfoItem {
            switch info {
            case .single(_, _):
                return 0
            case .multiple(_, let values):
                return values.count
            }
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        guard let info = item as? InfoItem else {
            return item
        }
        let name: String
        let value: String
        switch info {
        case .single(let i_name, let i_value):
            name = i_name
            value = i_value
        case .multiple(let i_name, _):
            name = i_name
            value = ""
        }
        
        if tableColumn?.identifier.rawValue == "name" {
            return name
        } else {
            return value
        }
    }
}
