//
//  SliderView.swift
//  Syntax Highlight
//
//  Created by Sbarex on 28/02/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

@IBDesignable public class SliderView: NSSlider {
    @IBOutlet var tickLabelformatter: NumberFormatter?
    @IBInspectable var firstTickLabel: String?
    @IBInspectable var lastTickLabel: String?
    
    static let tickLabelHeight: CGFloat = {
        let s = "1" as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.toolTipsFont(ofSize: NSFont.smallSystemFontSize)]
        let frame = s.boundingRect(with: NSSize(width: CGFloat.infinity, height: .infinity), options: [], attributes: attrs)
        return frame.height
    }()
    
    public override var intrinsicContentSize: NSSize {
        get {
            var s = super.intrinsicContentSize
            if self.sliderType == .linear {
                if self.isVertical {
                    s.width += SliderView.tickLabelHeight + 14
                } else {
                    s.height += SliderView.tickLabelHeight + 14
                }
            }
            
            return s
        }
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        /*
        let context = NSGraphicsContext.current!.cgContext
        NSColor.red.set()
        context.fill(self.bounds)
        */
        super.draw(dirtyRect)
        
        guard self.sliderType == .linear else {
            return
        }
        
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.toolTipsFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: NSColor.secondaryLabelColor, .paragraphStyle: NSParagraphStyle.default.mutableCopy()]
        

        let drawLabel = { (label: String?, tickIndex: Int, attrs: [NSAttributedString.Key: Any], minPos: CGFloat, maxPos: CGFloat) -> NSRect in
            guard maxPos > 0, minPos < maxPos else {
                // print("Draw tick \(tickIndex) [min: \(minPos), max: \(maxPos)] SKIP")
                
                return .zero
            }
            
            let tickRect = self.rectOfTickMark(at: tickIndex)
            if !self.isVertical, let paragraph = attrs[.paragraphStyle] as? NSMutableParagraphStyle {
                if tickIndex == self.numberOfTickMarks - 1 {
                    paragraph.alignment = .right
                } else if tickIndex == 0 {
                    paragraph.alignment = .left
                } else {
                    paragraph.alignment = .center
                }
            }
            
            let value = self.tickMarkValue(at: tickIndex)
            
            let s: String?
            if let s1 = label {
                s = s1
            } else if let formatter = self.tickLabelformatter {
                s = formatter.string(from: NSNumber(value: value))
            } else {
                s = "\(value)"
            }
            
            guard let text = s as NSString? else {
                return .zero
            }
            
            var origin = self.isVertical ? NSPoint(x: tickRect.maxX + 2, y: tickRect.minY) : NSPoint(x: tickRect.midX, y: tickRect.maxY + 2)
            let r = text.size(withAttributes: attrs)
            if let paragraph = attrs[.paragraphStyle] as? NSMutableParagraphStyle {
                switch paragraph.alignment {
                case .right:
                    origin.x -= r.width
                case .center:
                    origin.x -= r.width / 2
                default:
                    break
                }
            }
            // print("Draw tick \(tickIndex) at \(origin.x) with size \(r.width) [min: \(minPos), max: \(maxPos)] ", terminator: "")
            
            if self.isVertical {
                guard origin.y >= minPos, origin.y + r.height <= maxPos else {
                    // print("SKIP no space")
                    return .zero
                }
            } else {
                guard origin.x >= minPos, origin.x + r.width <= maxPos else {
                    // print("SKIP no space")
                    return .zero
                }
            }
            // print("")
            
            let rect = NSRect(origin: origin, size: r)
            text.draw(in: rect, withAttributes: attrs)
            
            return rect
        }
        
        var availSize = ceil(self.isVertical ? self.bounds.height : self.bounds.width)
        
        // Draw the first label.
        var r = drawLabel(self.firstTickLabel, 0, attrs, 0, availSize)
        var p = ceil(self.isVertical ? r.maxY : r.maxX)
        // Draw the last label.
        r = drawLabel(self.lastTickLabel, self.numberOfTickMarks - 1, attrs, p, availSize)
        availSize = floor(availSize - (self.isVertical ? r.height : r.width))
        
        // print("start tick from \(p), available width \(availSize) in \(dirtyRect)")
        
        for i in 1..<self.numberOfTickMarks-1 {
            r = drawLabel(nil, i, attrs, p, availSize)
            if r != .zero {
                p = ceil(self.isVertical ? r.maxY : r.maxX)
            }
        }
        
    }
}
