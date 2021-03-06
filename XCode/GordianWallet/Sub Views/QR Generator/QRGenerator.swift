//
//  QRGenerator.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit

class QRGenerator: UIView {
    
    func getQRCode(textInput: String) -> (qr: UIImage, error: Bool) {
        
        let imageToReturn = UIImage(named: "clear.png")!
        
        let data = textInput.data(using: .ascii)
        
        // Generate the code image with CIFilter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return (imageToReturn, true) }
        filter.setValue(data, forKey: "inputMessage")
        
        // Scale it up (because it is generated as a tiny image)
        //let scale = UIScreen.main.scale
        let transform = CGAffineTransform(scaleX: 10.0, y: 10.0)//CGAffineTransform(scaleX: 10, y: 10)
        guard let output = filter.outputImage?.transformed(by: transform) else { return (imageToReturn, true) }
        
        // Change the color using CIFilter
        let grey = #colorLiteral(red: 0.07804081589, green: 0.09001789242, blue: 0.1025182381, alpha: 1)
        
        let colorParameters = [
            "inputColor0": CIColor(color: grey), // Foreground
            "inputColor1": CIColor(color: .white) // Background
        ]
        
        let colored = (output.applyingFilter("CIFalseColor", parameters: colorParameters))
        
        func renderedImage(uiImage: UIImage) -> UIImage? {
            
            let image = uiImage
            
            return UIGraphicsImageRenderer(size: image.size,
                                           format: image.imageRendererFormat).image { _ in
                                            image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        }
        
        let uiImage = UIImage(ciImage: colored)
        
        if let qr = renderedImage(uiImage: uiImage) {
            
            return (qr, false)
            
        } else {
            
            return (imageToReturn, true)
            
        }
                
    }
    
}
