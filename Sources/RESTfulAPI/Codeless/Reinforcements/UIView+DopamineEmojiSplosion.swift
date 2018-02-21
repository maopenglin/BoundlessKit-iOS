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
    public func showEmojiSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 0.6,
                                  scaleSpeed: CGFloat = 0.2,
                                  scaleRange: CGFloat = 0.2,
                                  lifetime: Float = 3.0,
                                  lifetimeRange: Float = 0.5,
                                  fadeout: Float = -0.2,
                                  quantity birthRate: Float = 6.0,
                                  bursts birthCycles: Double = 1.0,
                                  velocity: CGFloat = -50,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = -150,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 45,
                                  spin: CGFloat = 0,
                                  hapticFeedback: Bool = false,
                                  systemSound: UInt32 = 0,
                                  completion: @escaping ()->Void = {}
        ) {
        guard let content = content else {
            DopeLog.debug("❌ received nil image content!")
            return
        }
        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = location
            
            let cell = CAEmitterCell()
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
            if fadeout > 0 {
                cell.alphaSpeed = -1.0 / fadeout
                cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeout))
            }
            else if fadeout < 0 {
                cell.alphaSpeed = 1.0 / -fadeout
                cell.color = cell.color?.copy(alpha: 0)
            }
            
            emitter.emitterCells = [cell]
            
            emitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(emitter)
            self.layer.setNeedsLayout()
//            DopeLog.debug("💥 Emojisplosion on <\(NSStringFromClass(type(of: self)))> at <\(location)>!")
            DopeAudio.play(systemSound, vibrate: hapticFeedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + birthCycles) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(lifetime + lifetimeRange)) {
                    emitter.removeFromSuperlayer()
//                    DopeLog.debug("💥 Emojisplosion done")
                    completion()
                }
            }
        }
    }
}

