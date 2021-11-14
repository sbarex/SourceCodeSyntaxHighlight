//
//  LSPViewController.swift
//  Syntax Highlight
//
//  Created by Sbarex on 04/04/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

class LSPViewController: NSViewController {
    var useLSP: Bool = false {
        didSet {
            guard oldValue != useLSP else { return }
            outlineView?.reloadData()
        }
    }
    var lspExecutable: String = "" {
        didSet {
            guard oldValue != lspExecutable else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 1), columnIndexes: IndexSet(integer: 1))
        }
    }
    var lspDelay: Int = 0 {
        didSet {
            guard oldValue != lspDelay else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 2), columnIndexes: IndexSet(integer: 1))
        }
    }
    var lspSyntax: String = "" {
        didSet {
            guard oldValue != lspSyntax else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 3), columnIndexes: IndexSet(integer: 1))
        }
    }
    var lspHover: Bool = false {
        didSet {
            guard oldValue != lspHover else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 4), columnIndexes: IndexSet(integer: 1))
        }
    }
    var lspSemantic: Bool = false {
        didSet {
            guard oldValue != lspSemantic else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 5), columnIndexes: IndexSet(integer: 1))
        }
    }
    var lspSyntaxError: Bool = false {
        didSet {
            guard oldValue != lspSyntaxError else { return }
            outlineView?.reloadData(forRowIndexes: IndexSet(integer: 6), columnIndexes: IndexSet(integer: 1))
        }
    }
    
    var lspOptions: [String] = [] {
        didSet {
            guard oldValue != lspOptions else { return }
            outlineView?.reloadData()
        }
    }
    
    
    enum Items: CaseIterable {
        case useLSP
        case executable
        case delay
        case syntax
        case hover
        case semantic
        case syntaxError
        case options
        
        var label: String {
            switch self {
            case .useLSP:
                return "Use a Language Server"
            case .executable:
                return "Executable"
            case .delay:
                return "Delay (ms)"
            case .syntax:
                return "Syntax"
            case .hover:
                return "Hover"
            case .semantic:
                return "Semantic"
            case .syntaxError:
                return "Syntax Error"
            case .options:
                return "Options"
            }
        }
    }
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var settings: SettingsFormat? {
        didSet {
            initSettings()
        }
    }
    
    var onDismiss: (()->Void)?
    
    @discardableResult
    func initSettings() -> Bool {
        outlineView?.beginUpdates()
        guard let settings = self.settings else {
            self.useLSP = false
            
            outlineView?.endUpdates()
            return false
        }
        self.useLSP = settings.useLSP
        self.lspExecutable = settings.lspExecutable
        self.lspSyntax = settings.lspSyntax
        self.lspDelay = settings.lspDelay
        self.lspHover = settings.lspHover
        self.lspSemantic = settings.lspSemantic
        self.lspSyntaxError = settings.lspSyntaxError
        self.lspOptions = settings.lspOptions
        
        outlineView?.expandItem(Items.options)
        outlineView?.reloadData()
        outlineView?.endUpdates()
        return true
    }
    
    @IBAction func handleSave(_ sender: Any) {
        settings?.useLSP = useLSP
        settings?.lspExecutable = lspExecutable
        settings?.lspDelay = lspDelay
        settings?.lspSyntax = lspSyntax
        settings?.lspHover = lspHover
        settings?.lspSemantic = lspSemantic
        settings?.lspSyntaxError = lspSyntaxError
        settings?.lspOptions = lspOptions.filter({ !$0.isEmpty })
        
        self.dismiss(sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSettings()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        onDismiss?()
    }
    
    func addOption(at index: Int) {
        guard lspOptions.count < 15 else { return }
        outlineView.beginUpdates()
        if index < 0 {
            if lspOptions.isEmpty {
                lspOptions.append("")
                outlineView.insertItems(at: IndexSet(integer: lspOptions.count-1), inParent: Items.options, withAnimation: NSTableView.AnimationOptions.effectGap)
            } else {
                addOption(at: 0)
            }
        } else {
            lspOptions.insert("", at: index+1)
            outlineView.insertItems(at: IndexSet(integer: index), inParent: Items.options, withAnimation: NSTableView.AnimationOptions.effectGap)
            outlineView.reloadItem(Items.options)
        }
        outlineView.expandItem(Items.options)
        outlineView.endUpdates()
    }
    
    func delOption(at index: Int) {
        outlineView.beginUpdates()
        lspOptions.remove(at: index)
        outlineView.reloadData()
        outlineView.reloadItem(Items.options)
        outlineView.endUpdates()
    }
    
    func moveOption(at index: Int, up: Bool) {
        outlineView.beginUpdates()
        let option = lspOptions[index]
        lspOptions.remove(at: index)
        if up {
            lspOptions.insert(option, at: index-1)
        } else {
            lspOptions.insert(option, at: index+1)
        }
        outlineView.reloadItem(Items.options)
        outlineView.endUpdates()
    }
}

// MARK: - NSOutlineViewDelegate
extension LSPViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        guard column == 0 else {
            return 300
        }
        
        var size: CGFloat = 0
        let labelFont = NSFont.labelFont(ofSize: NSFont.systemFontSize)
        
        for item in Items.allCases {
            let s = item.label
            size = max(size, (s as NSString).size(withAttributes: [.font: labelFont]).width)
        }
        return size + 8 + 20
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let item = item as? Items {
            let cell: NSTableCellView
            if tableColumn?.identifier.rawValue == "label" {
                if item == .options {
                    let c = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ButtonCell"), owner: nil) as! ButtonCell
                    c.isEnabled = useLSP
                    c.tag = -1
                    c.delegate = self
                    c.allowUp = false
                    c.allowDown = false
                    c.allowDel = false
                    cell = c
                } else {
                    cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LabelCell"), owner: nil) as! NSTableCellView
                }
                cell.textField?.stringValue = item.label
                return cell
            } else {
                let r: NSTableCellView
                switch item {
                case .useLSP, .hover, .semantic, .syntaxError:
                    let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "YNCell"), owner: nil) as! YNCell
                    cell.ynPopupButton.isEnabled = item == .useLSP || useLSP
                    cell.ynPopupButton.toolTip = nil
                    if item == .useLSP {
                        cell.tag = 1
                        cell.state = useLSP
                    } else if item == .hover {
                        cell.tag = 2
                        cell.state = self.lspHover
                        cell.ynPopupButton.toolTip = "Execute hover requests (for HTML render engine only)."
                    } else if item == .semantic {
                        cell.tag = 3
                        cell.state = self.lspSemantic
                        cell.ynPopupButton.toolTip = "Retrieve semantic token types (requires LSP 3.16)."
                    } else if item == .syntaxError {
                        cell.tag = 4
                        cell.state = self.lspSyntaxError
                        cell.ynPopupButton.toolTip = "Retrieve syntax error information (assumes hover or semantic)."
                    }
                    cell.delegate = self
                    r = cell
                case .executable:
                    let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PathCell"), owner: nil) as! BrowseCell
                    cell.url = lspExecutable.isEmpty ? nil : URL(fileURLWithPath: lspExecutable)
                    cell.textField?.isEditable = true
                    cell.textField?.isEnabled = useLSP
                    cell.textField?.toolTip = "Full path of the Language Server executable."
                    cell.browseButton.isEnabled = useLSP
                    cell.delegate = self
                    r = cell
                case .delay:
                    let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NumberCell"), owner: nil) as! IntegerCell
                    cell.integerValue = lspDelay
                    cell.textField?.isEditable = true
                    cell.textField?.isEnabled = useLSP
                    cell.stepper?.isEnabled = useLSP
                    cell.delegate = self
                    r = cell
                case .syntax:
                    let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "StringCell"), owner: nil) as! StringCell
                    cell.tag = -1
                    cell.stringValue = lspSyntax
                    cell.textField?.isEditable = true
                    cell.textField?.isEnabled = useLSP
                    cell.textField?.toolTip = "Set syntax which is understood by the server."
                    cell.textField?.placeholderString = "Syntax understood by the server"
                    cell.delegate = self
                    r = cell
                case .options:
                    let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LabelCell"), owner: nil) as! NSTableCellView
                    
                    cell.textField?.stringValue = ""
                    r = cell
                }
                return r
            }
        } else if let index = item as? Int {
            if tableColumn?.identifier.rawValue == "label" {
                let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ButtonCell"), owner: nil) as! ButtonCell
                cell.textField?.stringValue = "Item \(index+1)"
                cell.tag = index
                cell.isEnabled = useLSP
                cell.delegate = self
                
                cell.allowUp = index > 0
                cell.allowDown = index < lspOptions.count - 1
                cell.allowDel = true
                return cell
            } else {
                let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "StringCell"), owner: nil) as! StringCell
                cell.tag = index
                cell.stringValue = lspOptions[index]
                cell.textField?.isEditable = true
                cell.textField?.isEnabled = useLSP
                cell.textField?.toolTip = "Server CLI option."
                cell.textField?.placeholderString = "Server CLI option"
                cell.delegate = self
                
                return cell
            }
        }
        return nil
    }
    
    func selectionShouldChange(in outlineView: NSOutlineView) -> Bool {
        return true
    }
}

// MARK: - NSOutlineViewDataSource
extension LSPViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return Items.allCases.count
        } else if item as? Items == Items.options {
            return lspOptions.count
        } else {
            return 1
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item as? Items == Items.options && !lspOptions.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            switch index {
            case 0:
                return Items.useLSP
            case 1:
                return Items.executable
            case 2:
                return Items.delay
            case 3:
                return Items.syntax
            case 4:
                return Items.hover
            case 5:
                return Items.semantic
            case 6:
                return Items.syntaxError
            case 7:
                return Items.options
                
            default:
                return false
                
            }
        } else if item as? Items == Items.options {
            return index
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let item = item as? Items {
            if tableColumn?.identifier.rawValue == "label" {
                return item.label
            }
        }
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        print("ok")
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return tableColumn?.identifier.rawValue == "value"
    }
}

extension LSPViewController: StringCellDelegate {
    func stringCell(_ cell: StringCell, didChangeValue stringValue: String) {
        if cell.tag < 0 {
            self.lspSyntax = stringValue
        } else {
            self.lspOptions[cell.tag] = stringValue
        }
    }
}
extension LSPViewController: IntegerCellDelegate {
    func integerCell(_ cell: IntegerCell, didChangeValue integerValue: Int) {
        self.lspDelay = integerValue
    }
}
extension LSPViewController: BrowseCellDelegate {
    func browseCell(_ cell: BrowseCell, didChangeValue url: URL?) {
        self.lspExecutable = url?.path ?? ""
    }
}

extension LSPViewController: YNCellDelegate {
    func ynCell(_ cell: YNCell, didChangeValue state: Bool) {
        if cell.tag == 1 {
            self.useLSP = state
        } else if cell.tag == 2 {
            self.lspHover = state
        } else if cell.tag == 3 {
            self.lspSemantic = state
        } else if cell.tag == 4 {
            self.lspSyntaxError = state
        }
    }
    func ynCellWillSelected(_ cell: YNCell) {
        if cell.tag == 1 {
            outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        } else if cell.tag == 2 {
            outlineView.selectRowIndexes(IndexSet(integer: 4), byExtendingSelection: false)
        } else if cell.tag == 3 {
            outlineView.selectRowIndexes(IndexSet(integer: 5), byExtendingSelection: false)
        } else if cell.tag == 4 {
            outlineView.selectRowIndexes(IndexSet(integer: 6), byExtendingSelection: false)
        }
    }
}

extension LSPViewController: ButtonCellDelegate {
    func buttonCellDidAddButton(_ cell: ButtonCell) {
        addOption(at: cell.tag)
    }
    func buttonCellDidDelButton(_ cell: ButtonCell) {
        delOption(at: cell.tag)
    }
    
    func buttonCellDidMoveButton(_ cell: ButtonCell, up: Bool) {
        moveOption(at: cell.tag, up: up)
    }
}

@objc
protocol YNCellDelegate: AnyObject {
    @objc
    optional func ynCell(_ cell: YNCell, didChangeValue state: Bool)
    @objc
    optional func ynCellWillSelected(_ cell: YNCell)
}

class YNCell: NSTableCellView {
    private var _tag: Int = -1
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    @IBOutlet weak var ynPopupButton: NSPopUpButton!
    var state: Bool = false {
        didSet {
            ynPopupButton.selectItem(at: state ? 0 : 1)
            if oldValue != state {
                self.delegate?.ynCell?(self, didChangeValue: state)
            }
        }
    }
    
    @IBAction func handleState(_ sender: NSPopUpButton) {
        state = sender.indexOfSelectedItem == 0
    }
    
    weak var delegate: YNCellDelegate?;
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    internal func initialize() {
        NotificationCenter.default.addObserver(self,
                         selector: #selector(dropdownMenuOpened),
                         name: NSPopUpButton.willPopUpNotification,
                         object: ynPopupButton)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSPopUpButton.willPopUpNotification, object: ynPopupButton)
    }
    
    @objc
    internal func dropdownMenuOpened(_ notification: Notification) {
        if notification.object as? NSPopUpButton == self.ynPopupButton {
            self.delegate?.ynCellWillSelected?(self)
        }
    }
}

@objc
protocol BrowseCellDelegate: AnyObject {
    @objc
    optional func browseCell(_ cell: BrowseCell, didChangeValue url: URL?)
}

class BrowseCell: NSTableCellView, NSTextFieldDelegate {
    @IBOutlet weak var browseButton: NSButton!
    var url: URL? {
        didSet {
            if oldValue != url {
                textField?.stringValue = url?.path ?? ""
                delegate?.browseCell?(self, didChangeValue: url)
            }
        }
    }
    
    weak var delegate: BrowseCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    @IBAction func handleBrowse(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.showsTagField = false
        openPanel.allowsOtherFileTypes = true
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [UTType.script, UTType.shellScript, UTType.executable, UTType.unixExecutable]
        } else {
            openPanel.allowedFileTypes = ["public.script", "public.shell-script", "public.executable", "public.unix-executable"]
        }
        openPanel.isExtensionHidden = false
        openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        
        let result = openPanel.runModal()
        
        guard result == .OK, let url = openPanel.url else {
            return
        }
        self.url = url
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard obj.object as? NSTextField == self.textField else {
            return
        }
        url = textField!.stringValue.isEmpty ? nil : URL(fileURLWithPath: textField!.stringValue)
    }
}

@objc
protocol StringCellDelegate: AnyObject {
    @objc
    optional func stringCell(_ cell: StringCell, didChangeValue stringValue: String)
}

class StringCell: NSTableCellView, NSTextFieldDelegate {
    private var _tag: Int = -1
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    var stringValue: String = "" {
        didSet {
            if oldValue != stringValue {
                textField?.stringValue = stringValue
                delegate?.stringCell?(self, didChangeValue: stringValue)
            }
        }
    }
    
    weak var delegate: StringCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard obj.object as? NSTextField == self.textField else {
            return
        }
        stringValue = textField!.stringValue
    }
}

@objc
protocol IntegerCellDelegate: AnyObject {
    @objc
    optional func integerCell(_ cell: IntegerCell, didChangeValue integerValue: Int)
}


class IntegerCell: NSTableCellView, NSTextFieldDelegate {
    @IBOutlet weak var stepper: NSStepper!
    
    var integerValue: Int = 0 {
        didSet {
            if oldValue != integerValue {
                textField?.integerValue = integerValue
                stepper.integerValue = integerValue
                delegate?.integerCell?(self, didChangeValue: integerValue)
            }
        }
    }
    
    weak var delegate: IntegerCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard obj.object as? NSTextField == self.textField else {
            return
        }
        integerValue = textField!.integerValue
    }
    
    @IBAction func handleStepper(_ sender: NSStepper) {
        integerValue = stepper.integerValue
    }
}

@objc protocol ButtonCellDelegate: AnyObject {
    @objc optional func buttonCellDidAddButton(_ cell: ButtonCell)
    @objc optional func buttonCellDidDelButton(_ cell: ButtonCell)
    
    @objc optional func buttonCellDidMoveButton(_ cell: ButtonCell, up: Bool)
}

class ButtonCell: NSTableCellView {
    private var _tag: Int = -1
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    @IBOutlet weak var buttonsView: NSStackView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var delButton: NSButton!
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    
    var allowDel: Bool = true {
        didSet {
            delButton?.isHidden = !allowDel
        }
    }
    var allowUp: Bool = true {
        didSet {
            upButton?.isHidden = !allowUp
        }
    }
    var allowDown: Bool = true {
        didSet {
            downButton?.isHidden = !allowDown
        }
    }
    
    weak var delegate: ButtonCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    var isEnabled: Bool = true {
        didSet {
            addButton.isEnabled = isEnabled
            delButton.isEnabled = isEnabled
            upButton.isEnabled = isEnabled
            downButton.isEnabled = isEnabled
        }
    }
    
    private var trackingArea: NSTrackingArea?
    
    override var frame: CGRect {
        didSet {
            if let trackingArea = self.trackingArea {
                removeTrackingArea(trackingArea)
            }
            
            self.trackingArea = NSTrackingArea(
                rect: bounds,
                options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited,/* NSTrackingAreaOptions.mouseMoved */],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea!)
        }
    }
    
    deinit {
        if let trackingArea = self.trackingArea {
            removeTrackingArea(trackingArea)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        buttonsView.isHidden = true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard isEnabled else { return }
        buttonsView.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard isEnabled else { return }
        buttonsView.isHidden = true
    }
    
    @IBAction func handleAdd(_ sender: Any) {
        delegate?.buttonCellDidAddButton?(self)
    }
    
    @IBAction func handleDel(_ sender: Any) {
        delegate?.buttonCellDidDelButton?(self)
    }
    
    @IBAction func handleUp(_ sender: Any) {
        delegate?.buttonCellDidMoveButton?(self, up: true)
    }
    @IBAction func handleDown(_ sender: Any) {
        delegate?.buttonCellDidMoveButton?(self, up: false)
    }
}
