//
//  NSImage+ext.swift
//  Syntax Highlight
//
//  Created by Sbarex on 12/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

extension NSImage {
    func image(withBrightness brightness: CGFloat, contrast: CGFloat, saturation: CGFloat)->NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let ciImage = CIImage(cgImage: cgImage)
            
        guard let filter = CIFilter(name: "CIColorControls") else {
            return nil
        }
        filter.setDefaults()
            
        filter.setValue(saturation, forKey: "inputSaturation")
        filter.setValue(brightness, forKey: "inputBrightness")
        filter.setValue(contrast, forKey: "inputContrast")
        filter.setValue(ciImage, forKey: "inputImage")
            
        guard let outputImage = filter.outputImage else {
            return nil
        }
        let rep = NSCIImageRep(ciImage: outputImage)
        let nsImage = NSImage(size: self.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
}
