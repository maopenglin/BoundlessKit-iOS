//
//  DLCoins.swift
//  To Do List
//
//  Created by Akash Desai on 5/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

public extension UIView {
    
    public func showCoins(at location:CGPoint, width: CGFloat = 30, vibration:Bool = false) {
        
        let url = URL(string: "https://dl2.macupdate.com/images/icons256/26677.png")
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                
                DopamineKit.debugLog("here")
                let image = UIImage(data: data!)!
//                let image = CAEmitterLayer.circleImage(diameter: 12.0, color: UIColor.blue)
                
                let coins = CAEmitterLayer(center: location, size: CGSize(width: width, height: 12), content: image.cgImage)
                self.layer.addSublayer(coins)
                if vibration { AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) }
                //        Helper.playCoinSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    coins.birthRate = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                        coins.removeFromSuperlayer()
                    }
                }
            }
        }).resume()
    }
    
}

public class UIButtonWithCoinsOnClick : UIButton {
    
    public var enableCoins = true
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if enableCoins, isTouchInside,
            let touch = touches.first {
            showCoins(at: touch.location(in: self), width: self.bounds.width)
        }
        super.touchesEnded(touches, with: event)
    }
}

fileprivate extension CAEmitterLayer {
    
    convenience init(center:CGPoint, size: CGSize, content: Any? = CAEmitterLayer.circleImage(diameter: 12.0, color: UIColor.blue).cgImage) {
        self.init()
        self.emitterPosition = center
        self.emitterShape = "rectangle"
        self.emitterSize = size
        
        
        let cell = CAEmitterCell()
        cell.name = "dopeEmitter"
        cell.birthRate = 20
        cell.lifetime = 1.5
        cell.spin = CGFloat.pi
        cell.spinRange = CGFloat.pi
        cell.velocity = 200
        cell.scaleRange = 0.4
        cell.alphaSpeed = -2.0
        cell.color = UIColor.blue.cgColor.copy(alpha: 3.0)
        //        cell.alphaRange = 1.0
        cell.emissionRange = CGFloat.pi / 8.0
        cell.emissionLongitude = CGFloat.pi / -2.0
        cell.contents = content
        
        emitterCells = [cell]
    }
    
    fileprivate static func circleImage(diameter: CGFloat, color: UIColor) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let alphaColor = color.withAlphaComponent(0.6)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        alphaColor.set()
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
