//
//  StarburstTouch.swift
//  To Do List
//
//  Created by Akash Desai on 5/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension UIView {
    func showStarburst(at location:CGPoint) {
        let stars = CAEmitterLayer(starburstLayerAt: location)
        layer.addSublayer(stars)
//        Helper.playStarSound()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            stars.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                stars.removeFromSuperlayer()
            }
        }
    }
}

class UIButtonWithStarburstOnClick : UIButton {
    var enableStarburst = true
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if enableStarburst, isTouchInside,
            let touch = touches.first {
            showStarburst(at: touch.location(in: self))
        }
        super.touchesEnded(touches, with: event)
    }
}

extension CAEmitterLayer {
    convenience init(starburstLayerAt location:CGPoint) {
        self.init()
        emitterPosition = location
        
        let cell = CAEmitterCell()
        cell.name = "starEmitter"
        cell.birthRate = 20
        cell.lifetime = 1.0
        cell.spin = CGFloat.pi
        cell.spinRange = CGFloat.pi / 2.0
        cell.velocity = 300
        cell.velocityRange = 50
        cell.scale = 0.01
        cell.scaleSpeed = 0.1
        cell.scaleRange = 0.1
        cell.emissionRange = CGFloat.pi * 2.0
        cell.contents = "🎉".image().cgImage // UIImage(named: "star")!.cgImage
        
        emitterCells = [cell]
    }
}

extension String {
    func image() -> UIImage {
        let size = CGSize(width: 160, height: 160)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 160)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}
