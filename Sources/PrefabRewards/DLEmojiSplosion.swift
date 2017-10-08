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

public enum SpinIntensity : CGFloat {
    case none=0, slight=120, heavy=360
}

public extension UIView {
    public func showEmojiSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 1.0,
                                  scaleSpeed: CGFloat = 0,
                                  scaleRange: CGFloat = 0,
                                  lifetime: Float = 2.0,
                                  fadeout: Float = 0.2,
                                  quantity: Float = 1.0,
                                  bursts: Double = 1.0,
                                  velocity: CGFloat = 0,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = 0,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 0,
                                  spinIntensity: SpinIntensity = .none
        ) {
        showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, fadeout:fadeout, birthRate:quantity, birthCycles:bursts, velocity:velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spinIntensity.rawValue)
    }
    
    public func showEmojiSplosion(at location: CGPoint, content: CGImage?, scale: CGFloat, scaleSpeed: CGFloat, scaleRange: CGFloat, lifetime: Float, fadeout: Float, birthRate: Float, birthCycles: Double, velocity: CGFloat, xAcceleration: CGFloat, yAcceleration: CGFloat, angle: CGFloat, range: CGFloat, spin: CGFloat) {
        guard let content = content else {
            DopamineKit.debugLog("❌ received nil image content!")
            return
        }
        
        let presentingLayer: CALayer = self.superview!.layer // (UIApplication.shared.delegate?.window??.layer)!
        let position = convert(location, to: self.superview!)
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = position
        
        let cell = CAEmitterCell()
        cell.name = "emojiCell"
        cell.contents = content
        cell.birthRate = birthRate
        cell.lifetime = lifetime
        cell.spin = spin.degreesToRadians()
        cell.spinRange = cell.spin / 8
        cell.velocity = velocity
        cell.velocityRange = cell.velocity / 3
        cell.xAcceleration = xAcceleration
        cell.yAcceleration = yAcceleration
        cell.scale = scale
        cell.scaleSpeed = scaleSpeed
        cell.scaleRange = scaleRange
        cell.emissionLongitude = angle.degreesToRadians()
        cell.emissionRange = range.degreesToRadians()
        cell.alphaSpeed = -1.0 / fadeout
        cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeout))
        
        emitter.emitterCells = [cell]
        DopamineKit.debugLog("Emoji'Splosion'!")
        DispatchQueue.main.async {
            emitter.beginTime = CACurrentMediaTime()
            presentingLayer.addSublayer(emitter)
            //        Helper.playStarSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + birthCycles) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(lifetime + 0.3)) {
                    emitter.removeFromSuperlayer()
                }
            }
        }
    }
}

public extension String {
    func image(font:UIFont = .systemFont(ofSize: 24)) -> UIImage {
        let size = (self as NSString).size(attributes: [NSFontAttributeName: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        (self as NSString).draw(at: .zero, withAttributes: [NSFontAttributeName: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

fileprivate extension CGFloat {
    func degreesToRadians() -> CGFloat {
        return self / 180 * .pi
    }
    
    init(degrees: CGFloat) {
        self = degrees.degreesToRadians()
    }
}
