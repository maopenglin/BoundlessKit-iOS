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

public enum EmojiSplosionIntensity : Int {
    case one, some, many
    
    fileprivate var explosionValues: (birthRate: Float, velocity: CGFloat) {
        switch self {
        case .one: return (birthRate: 1, velocity: 100)
        case .some: return (birthRate: 3, velocity: 500)
        case .many: return (birthRate: 10, velocity: 750)
        }
    }
}

public enum SpinIntensity : CGFloat {
    case none=0, slight=120, heavy=360
}

public extension UIView {
    public func showEmojiSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 1.0,
                                  scaleSpeed: CGFloat = 0.1,
                                  scaleRange: CGFloat = 0.1,
                                  lifetime: Float = 2.0,
                                  intensity: EmojiSplosionIntensity = .one,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = 0,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 1,
                                  spinIntensity: SpinIntensity = .none
        ) {
        showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, birthRate:intensity.explosionValues.birthRate, velocity:intensity.explosionValues.velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spinIntensity.rawValue)
    }
    
    public func showEmojiSplosion(at location: CGPoint, content: CGImage?, scale: CGFloat, scaleSpeed: CGFloat, scaleRange: CGFloat, lifetime: Float, birthRate: Float, velocity: CGFloat, xAcceleration: CGFloat, yAcceleration: CGFloat, angle: CGFloat, range: CGFloat, spin: CGFloat) {
        guard let content = content else {
            DopamineKit.debugLog("❌ received nil image content!")
            return
        }
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = convert(location, to: nil)
        
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
        let fadeOutDuration: Float = 0.2
        cell.alphaSpeed = -1.0 / fadeOutDuration
        cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeOutDuration))
        
        emitter.emitterCells = [cell]
        DopamineKit.debugLog("Emoji'Splosion'!")
        DispatchQueue.main.async {
            let windowLayer = UIApplication.shared.delegate?.window??.layer
            emitter.beginTime = CACurrentMediaTime()
            windowLayer?.addSublayer(emitter)
            //        Helper.playStarSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
        let rect = CGRect(origin: .zero, size: size)
        (self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: font])
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
