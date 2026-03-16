//
//  CustomTypeViewController.swift
//  SyntaxHighlight
//
//  Created by Sbarex on 15/11/2019.
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
import Syntax_Highlight_XPC_Service

enum UTISupported {
    case unknown
    case no
    case yes
    case highlight
}

class UTIStatus {
    let UTI: UTI
    var supported: UTISupported = .unknown
    let standard: Bool
    var recognized: String?
    var isMain: Bool
    
    init(UTI: UTI, standard: Bool) {
        self.UTI = UTI
        self.standard = standard
        self.recognized = nil
        self.isMain = false
    }
}

class DropSensor: NSView {
    weak var dropDelegate: DropSensorDelegate?
    
    var acceptableTypes: [NSPasteboard.PasteboardType] { return [.fileURL] }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        registerForDraggedTypes(acceptableTypes)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.dropDelegate?.enterDrag(sender)
        return .every
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.dropDelegate?.exitDrag(sender)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.dropDelegate?.endDrag(sender)
    }
}

protocol DropSensorDelegate: AnyObject {
    func enterDrag(_ sender: NSDraggingInfo)
    func exitDrag(_ sender: NSDraggingInfo?)
    func endDrag(_ sender: NSDraggingInfo)
}

class CustomTypeViewController: NSViewController, DropSensorDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var dropSensor: DropSensor!
    
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var dropView: NSView!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var handledLegend: NSView!
    @IBOutlet weak var notHandledLegend: NSView!
    @IBOutlet weak var supportedLegend: NSView!
    @IBOutlet weak var resetButton: NSButton!
    
    private var firstDrop = true
    
    enum Mode {
        case drop
        case info
    }
    
    var mode: Mode = .drop {
        didSet {
            guard oldValue != mode else { return }
            switch mode {
            case .drop:
                tabView.selectTabViewItem(at: 1)
                resetButton.isHidden = true
            case .info:
                tabView.selectTabViewItem(at: 0)
                resetButton.isHidden = false
            }
        }
    }
    
    var handledUTIs: [UTI] = []
    
    var UTIs: [UTIStatus] = [] {
        didSet {
            self.handledLegend.isHidden = true
            self.notHandledLegend.isHidden = true
            self.supportedLegend.isHidden = true
            if (self.UTIs.count > 0) {
                for (i, uti) in self.UTIs.enumerated() {
                    var syntax: String?
                    if let u = SCSHWrapper.shared.settings?.searchStandaloneUTI(for: uti.UTI), let s = SCSHWrapper.shared.settings?.utiSettings[u] {
                        syntax = s.syntax.isEmpty ? s.specialSyntax : s.syntax
                    }
                    if syntax == nil {
                        syntax = HighlightWrapper.shared.areSomeSyntaxSupported(extensions: uti.UTI.extensions)
                    }
                    
                    if let _ = handledUTIs.first(where: { $0.UTI == uti.UTI.UTI }) {
                        uti.supported = .yes
                        self.handledLegend.isHidden = false
                    } else {
                        self.supportedLegend.isHidden = syntax == nil
                        uti.supported = syntax != nil ? .highlight : .no
                    }
                    
                    self.notHandledLegend.isHidden = syntax != nil
                    uti.recognized = syntax
                    
                    var c = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("status"))
                    self.tableView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: c))
                    
                    c = self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("highlight"))
                    self.tableView.reloadData(forRowIndexes: IndexSet(integer: i), columnIndexes: IndexSet(integer: c))
                }
            }
            
            self.tableView.reloadData()
            self.tableView.scrollRowToVisible(0)
        }
    }
        
    override func viewDidLoad() {
        self.dropSensor.dropDelegate = self
        
        resetUTI(self)
        
        handledUTIs = (NSApplication.shared.delegate as? AppDelegate)?.handledUTIs ?? []
        
        self.dropView.wantsLayer = true
        self.dropView.layer?.cornerRadius = 12
        self.dropView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.dropView.layer?.borderWidth = 4
        
        self.tableView.doubleAction = #selector(self.handleDblClik(_:))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.standardWindowButton(.zoomButton)?.isHidden = true
        view.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }
    
    @IBAction func handleDblClik(_ sender: Any) {
        guard self.tableView.selectedRow >= 0 else {
            return
        }
        let uti = self.UTIs[self.tableView.selectedRow]
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(uti.UTI.UTI, forType: .string)
    }
    
    func enterDrag(_ sender: NSDraggingInfo) {
        mode = .drop
        self.dropView.layer?.borderColor = NSColor.selectedControlColor.cgColor
    }
    func exitDrag(_ sender: NSDraggingInfo?) {
        mode = firstDrop ? .drop : .info
        self.dropView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
    }
    
    func endDrag(_ sender: NSDraggingInfo) {
        self.dropView.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        
        if let fileUrl = sender.draggingPasteboard.pasteboardItems?.first?.propertyList(forType: .fileURL) as? String, let url = URL(string: fileUrl) {
            
            setUTIs(for: url)
        } else {
            self.UTIs = []
            mode = .drop
        }
    }
    
    internal func setUTIs(for url: URL) {
        var UTIs: [UTIStatus] = []
        
        do {
            let v = try url.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey])
            if let uti = v.typeIdentifier {
                UTIs.append(UTIStatus(UTI: UTI(uti), standard: true))
            }
        } catch {
        }
        
        let ext = url.pathExtension
        if !ext.isEmpty {
            let tags = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, ext as CFString, nil)
            if let t = tags?.takeRetainedValue() as? [String] {
                for u in t {
                    if UTIs.first(where: { $0.UTI.UTI == u }) == nil {
                        UTIs.append(UTIStatus(UTI: UTI(u), standard: false))
                    }
                }
            }
        }
        
        if let u = SCSHWrapper.shared.settings?.searchUTI(for: url), UTIs.first(where: { $0.UTI.UTI == u }) == nil {
            UTIs.append(UTIStatus(UTI: UTI(u), standard: true))
        }
        
        if let uti = SCSHWrapper.shared.settings?.searchUTI(for: url) {
            for u in UTIs {
                u.isMain = u.UTI.UTI == uti
            }
        }
        
        self.UTIs = UTIs
        mode = .info
        firstDrop = false
    }
    
    @IBAction func resetUTI(_ sender: Any) {
        self.firstDrop = true
        self.UTIs = []
        mode = .drop
    }
    
    @IBAction func browseForFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.showsTagField = false
        openPanel.isExtensionHidden = false
        openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = openPanel.runModal()
        
        guard result == .OK, let url = openPanel.url else {
            return
        }
        setUTIs(for: url)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.UTIs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else {
            return NSTableCellView()
        }
        
        let uti = self.UTIs[row]
        
        let labelFont = NSFont.labelFont(ofSize: NSFont.systemFontSize)
        let font: NSFont
        if uti.standard || uti.isMain {
            font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        } else {
            font = labelFont
        }
        
        let view = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        
        if tableColumn.identifier == NSUserInterfaceItemIdentifier("description") {
            view.textField?.stringValue = uti.UTI.description + (uti.isMain ? " [main]" : "")
            view.textField?.font = font
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("UTI") {
            view.textField?.stringValue = uti.UTI.UTI // NSAttributedString(string: uti.UTI.UTI, attributes: [NSAttributedString.Key.font: font])
            view.textField?.font = font
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("status") {
            switch (uti.supported) {
            case .yes:
                view.imageView?.image = NSImage(named: NSImage.statusAvailableName)
                view.imageView?.toolTip = "Supported and handled."
            case .no:
                view.imageView?.image = NSImage(named: NSImage.statusUnavailableName)
                view.imageView?.toolTip = "Not supported."
            case .highlight:
                view.imageView?.image = NSImage(named: NSImage.statusPartiallyAvailableName)
                view.imageView?.toolTip = "Potentially supported but not handled."
            case .unknown:
                view.imageView?.image = NSImage(named: NSImage.statusNoneName)
                view.imageView?.toolTip = "Unknown status."
            }
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("ext") {
            view.textField?.stringValue = uti.UTI.extensions.joined(separator: ", ")
            view.textField?.font = labelFont
        } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("highlight") {
            view.textField?.stringValue = uti.recognized ?? (uti.supported == .yes ? "" : "-")
            view.textField?.font = labelFont
        }
        
        return view
    }

    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        let tableColumn = tableView.tableColumns[column]
        
        guard tableColumn.identifier != NSUserInterfaceItemIdentifier("status") else {
            return 20
        }
        
        var size: CGFloat = 0
        
        let labelFont = NSFont.labelFont(ofSize: NSFont.systemFontSize)
        let boldFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        
        for uti in UTIs {
            let font: NSFont
            let s: String
            if tableColumn.identifier == NSUserInterfaceItemIdentifier("description") {
                s = uti.UTI.description
                font = uti.standard ? boldFont : labelFont
            } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("ext") {
                s = uti.UTI.extensions.joined(separator: ", ")
                font = labelFont
            } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("UTI") {
                s = uti.UTI.UTI
                font = uti.standard ? boldFont : labelFont
            } else if tableColumn.identifier == NSUserInterfaceItemIdentifier("highlight") {
                s = uti.recognized ?? (uti.supported == .yes ? "" : "-")
                font = labelFont
            } else {
                continue
            }
            size = max(size, (s as NSString).size(withAttributes: [.font: font]).width)
        }
        return size + 8
    }
    
    @IBAction func tableViewDoubleClick(_ sender: NSTableView) {
        guard tableView.clickedRow >= 0 else {
            return
        }
        let uti = UTIs[tableView.clickedRow]
        if uti.supported == .yes {
            for w in NSApplication.shared.windows {
                if let vc = w.contentViewController as? SettingsSplitViewController {
                    vc.selectUTI(uti.UTI)
                    break
                }
            }
        }
    }
    
    @IBAction func showHelp(_ sender: Any) {
        if let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            NSHelpManager.shared.openHelpAnchor("SyntaxHighlight_INQUIRY", inBook: locBookName)
        }
    }
}
