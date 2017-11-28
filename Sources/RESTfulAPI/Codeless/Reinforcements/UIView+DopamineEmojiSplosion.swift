//
//  UIView+DopamineEmojiSplosion.swift
//  DopamineKit
//
//  Created by Akash Desai on 5/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public extension UIView {
    public func showGifSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 1.0,
                                  scaleSpeed: CGFloat = 0,
                                  scaleRange: CGFloat = 0,
                                  lifetime: Float = 2.0,
                                  lifetimeRange: Float = 0,
                                  fadeout: Float = 0.2,
                                  quantity: Float = 1.0,
                                  bursts: Double = 1.0,
                                  velocity: CGFloat = 30,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = -30,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 0,
                                  spin: CGFloat = 0,
                                  backgroundColor: UIColor = .black,
                                  backgroundAlpha: CGFloat = 0.7
        ) {
        if backgroundAlpha > 0 {
            let vc = UIGifgliaViewController(autoDismissTimeout: bursts * Double(lifetime), backgroundColor: backgroundColor, backgroundAlpha: backgroundAlpha) { view in
                view.showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, lifetimeRange:lifetimeRange, fadeout:fadeout, birthRate:quantity, birthCycles:bursts, velocity:velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spin)
            }
            UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
//            UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true, completion: {
//                vc.gifViewController.view.showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, lifetimeRange:lifetimeRange, fadeout:fadeout, birthRate:quantity, birthCycles:bursts, velocity:velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spin)
//            })
        } else {
            showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, lifetimeRange:lifetimeRange, fadeout:fadeout, birthRate:quantity, birthCycles:bursts, velocity:velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spin)
        }
    }
    
    public func showEmojiSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 1.0,
                                  scaleSpeed: CGFloat = 0,
                                  scaleRange: CGFloat = 0,
                                  lifetime: Float = 2.0,
                                  lifetimeRange: Float = 0.5,
                                  fadeout: Float = 0.2,
                                  quantity: Float = 1.0,
                                  bursts: Double = 1.0,
                                  velocity: CGFloat = 0,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = 0,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 0,
                                  spin: CGFloat = 0,
                                  completion: (() -> Void)? = nil
        ) {
        showEmojiSplosion(at:location, content:content, scale:scale, scaleSpeed:scaleSpeed, scaleRange:scaleRange, lifetime:lifetime, lifetimeRange:lifetimeRange, fadeout:fadeout, birthRate:quantity, birthCycles:bursts, velocity:velocity, xAcceleration:xAcceleration, yAcceleration:yAcceleration, angle:angle, range:range, spin:spin, completion: completion)
    }
    
    public func showEmojiSplosion(at location: CGPoint, content: CGImage?, scale: CGFloat, scaleSpeed: CGFloat, scaleRange: CGFloat, lifetime: Float, lifetimeRange: Float, fadeout: Float, birthRate: Float, birthCycles: Double, velocity: CGFloat, xAcceleration: CGFloat, yAcceleration: CGFloat, angle: CGFloat, range: CGFloat, spin: CGFloat, completion: (() -> Void)? = nil) {
        guard let content = content else {
            DopeLog.debug("❌ received nil image content!")
            return
        }
        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = location
            
            let cell = CAEmitterCell()
            cell.name = "emojiCell"
            cell.contents = content
            cell.birthRate = birthRate
            cell.lifetime = lifetime
            cell.lifetimeRange = lifetimeRange
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
            if fadeout != 0 {
                cell.alphaSpeed = -1.0 / fadeout
                cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeout))
            }
            
            emitter.emitterCells = [cell]
            
            emitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(emitter)
            DopeLog.debug("💥 Emojisplosion on <\(NSStringFromClass(type(of: self)))> at <\(location)>!")
            DispatchQueue.main.asyncAfter(deadline: .now() + birthCycles) {
                emitter.birthRate = 0
                completion?()
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(lifetime + lifetimeRange + 0.2)) {
                    emitter.removeFromSuperlayer()
                }
            }
        }
    }
}

