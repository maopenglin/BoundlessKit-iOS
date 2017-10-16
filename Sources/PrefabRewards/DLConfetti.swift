//
//  DLConfetti.swift
//  To Do List
//
//  Created by Akash Desai on 9/27/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

public enum ConfettiShape : Int {
    case rectangle, circle, spiral
}

public extension UIView {
    /**
     Creates a CAEmitterLayer that drops celebration confetti from the top of the view
     
     - parameters:
        - duration: How long celebration confetti should last
        - size: Size of individual confetti pieces
        - shapes: This directly affects the quantity of confetti. For example, [.circle] will show half as much confetti as [.circle, .circle]
        - colors: Confetti colors are randomly selected from this array. Repeated colors increase that color's likelihood
     */
    public func showConfetti(duration:Double = 2.0,
                      size:CGSize = CGSize(width: 15, height: 10),
                      shapes:[ConfettiShape] = [.rectangle, .rectangle, .circle],
                      colors:[UIColor] = [UIColor.blue, UIColor.purple, UIColor.yellow, UIColor.red],
                      completion: @escaping ()->Void = {}) {
        
        firstBurst(duration: 0.8, size: size, shapes: shapes, colors: colors) {
            self.secondBurst(duration: duration, size: size, shapes: shapes, colors: colors, completion: completion)
        }
    }
    
    internal func firstBurst(duration:Double,
                              size:CGSize,
                              shapes:[ConfettiShape],
                              colors:[UIColor],
                              completion: @escaping ()->Void) {
        let confettiEmitter = CAEmitterLayer(center: CGPoint(x: self.frame.width/2.0, y: 0), emitterWidth: self.frame.width / 4.0, emissionRange: CGFloat.pi/4.0, birthRate: 8, velocity: 250, yAcceleration: -80, confettiSize: size, confettiShapes: shapes, confettiColors: colors)
        confettiEmitter.beginTime = CACurrentMediaTime()
        self.layer.addSublayer(confettiEmitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
            confettiEmitter.birthRate = 0
            completion()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                for cell in confettiEmitter.emitterCells! {
                    cell.yAcceleration = 0
                }
                confettiEmitter.birthRate = 0
                confettiEmitter.velocity = 200
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    confettiEmitter.removeFromSuperlayer()
                }
            }
        }
    }
    
    internal func secondBurst(duration:Double,
                              size:CGSize,
                              shapes:[ConfettiShape],
                              colors:[UIColor],
                              completion: @escaping ()->Void) {
        let confettiEmitter = CAEmitterLayer(center: CGPoint(x: self.frame.width/2.0, y: 0), emitterWidth: self.frame.width, emissionRange: CGFloat.pi/4.0, birthRate: 2, velocity: 200, yAcceleration: 0, confettiSize: size, confettiShapes: shapes, confettiColors: colors)
        confettiEmitter.beginTime = CACurrentMediaTime()
        self.layer.addSublayer(confettiEmitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            confettiEmitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                confettiEmitter.removeFromSuperlayer()
                completion()
            }
        }
    }
}

fileprivate extension CAEmitterLayer {
    convenience init(center: CGPoint, emitterWidth: CGFloat, emissionRange: CGFloat, birthRate: Float, velocity: CGFloat, yAcceleration: CGFloat, confettiSize:CGSize, confettiShapes:[ConfettiShape], confettiColors:[UIColor]) {
        self.init()
        
        self.emitterPosition = center
        self.emitterShape = kCAEmitterLayerLine
        self.emitterSize = CGSize(width: emitterWidth, height: 1)
        
        var cells:[CAEmitterCell] = []
        
        for color in confettiColors {
            for shape in confettiShapes {
                let confettiImage: UIImage
                switch shape {
                case .rectangle:
                    confettiImage = rectangleConfetti(size: confettiSize, color: color)
                case .circle:
                    confettiImage = circleConfetti(size: confettiSize, color: color)
                case .spiral:
                    confettiImage = spiralConfetti(size: confettiSize, color: color)
                }
                let cell = CAEmitterCell()
                
                cell.birthRate = birthRate
                cell.lifetime = 7.0
                cell.lifetimeRange = 0
                cell.velocity = velocity
                cell.yAcceleration = yAcceleration
                cell.emissionLongitude = CGFloat.pi
                cell.emissionRange = emissionRange
                cell.spin = 1
                cell.spinRange = 3
                cell.scale = 1
                cell.scaleRange = 1
                cell.scaleSpeed = -0.05
                cell.contents = confettiImage.cgImage!
                
                cells.append(cell)
            }
        }
        
        self.emitterCells = cells
    }
    
    fileprivate func rectangleConfetti(size: CGSize, color: UIColor) -> UIImage {
        let offset = size.width / CGFloat((arc4random_uniform(7) + 1))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.beginPath()
        context.move(to: CGPoint(x:offset, y: 0))
        context.addLine(to: CGPoint(x: size.width, y: 0))
        context.addLine(to: CGPoint(x: size.width - offset, y: size.height))
        context.addLine(to: CGPoint(x: 0, y: size.height))
        context.closePath()
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    fileprivate func spiralConfetti(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        let lineWidth:CGFloat = size.width / 8.0
        let halfLineWidth = lineWidth / 2.0
        context.beginPath()
        context.setLineWidth(lineWidth)
        context.move(to: CGPoint(x: halfLineWidth, y: halfLineWidth))
        context.addCurve(to: CGPoint(x: size.width - halfLineWidth, y: size.height - halfLineWidth), control1: CGPoint(x: 0.25*size.width, y: size.height), control2: CGPoint(x: 0.75*size.width, y: 0))
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    fileprivate func circleConfetti(size: CGSize, color: UIColor) -> UIImage {
        let diameter = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
