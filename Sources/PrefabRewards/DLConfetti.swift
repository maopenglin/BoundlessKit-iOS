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
                      size:CGSize = CGSize(width: 9, height: 6),
                      shapes:[ConfettiShape] = [.rectangle, .rectangle, .circle],
                      colors:[UIColor] = [UIColor.from(hex: "4d81fb"), UIColor.from(hex: "9243f9"), UIColor.from(hex: "fdc33b"), UIColor.from(hex: "f7332f")],
                      completion: @escaping ()->Void = {}) {
        
        self.confettiBurst(duration: 0.8, size: size, shapes: shapes, colors: colors) {
            self.confettiShower(duration: duration, size: size, shapes: [.rectangle, .rectangle, .circle, .rectangle, .rectangle, .circle], colors: colors, completion: completion)
        }
    }
    
    internal func confettiBurst(duration:Double, size:CGSize, shapes:[ConfettiShape], colors:[UIColor], completion: @escaping ()->Void) {
        DispatchQueue.main.async {
            
            /* Create bursting confetti */
            let confettiEmitter = CAEmitterLayer()
            confettiEmitter.emitterPosition = CGPoint(x: self.frame.width/2.0, y: -30)
            confettiEmitter.emitterShape = kCAEmitterLayerLine
            confettiEmitter.emitterSize = CGSize(width: self.frame.width / 4, height: 0)
            
            var cells:[CAEmitterCell] = []
            for color in colors {
                for shape in shapes {
                    let confettiImage: CGImage
                    switch shape {
                    case .rectangle:
                        confettiImage = ConfettiShape.rectangleConfetti(size: size, color: color)
                    case .circle:
                        confettiImage = ConfettiShape.circleConfetti(size: size, color: color)
                    case .spiral:
                        confettiImage = ConfettiShape.spiralConfetti(size: size, color: color)
                    }
                    let cell = CAEmitterCell()
                    cell.setValuesForBurst1()
                    cell.contents = confettiImage
                    cells.append(cell)
                }
            }
            confettiEmitter.emitterCells = cells
            
            /* Start showing the confetti */
            confettiEmitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(confettiEmitter)
            
            /* Remove the burst effect */
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                completion()
                for cell in confettiEmitter.emitterCells! {
                    cell.setValuesForBurst2()
                }
                
                /* Remove the confetti emitter */
                DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                    confettiEmitter.birthRate = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        confettiEmitter.removeFromSuperlayer()
                    }
                }
            }
        }
    }
    
    internal func confettiShower(duration:Double, size:CGSize, shapes:[ConfettiShape], colors:[UIColor], completion: @escaping ()->Void) {
        DispatchQueue.main.async {
            
            /* Create showering confetti */
            let confettiEmitter = CAEmitterLayer()
            confettiEmitter.emitterPosition = CGPoint(x: self.frame.width/2.0, y: -30)
            confettiEmitter.emitterShape = kCAEmitterLayerLine
            confettiEmitter.emitterSize = CGSize(width: self.frame.width, height: 0)
            
            var cells:[CAEmitterCell] = []
            for color in colors {
                for shape in shapes {
                    let confettiImage: CGImage
                    switch shape {
                    case .rectangle:
                        confettiImage = ConfettiShape.rectangleConfetti(size: size, color: color)
                    case .circle:
                        confettiImage = ConfettiShape.circleConfetti(size: size, color: color)
                    case .spiral:
                        confettiImage = ConfettiShape.spiralConfetti(size: size, color: color)
                    }
                    let cell = CAEmitterCell()
                    cell.setValuesForShower()
                    cell.contents = confettiImage
                    cells.append(cell)
                }
            }
            
            /* Create some blurred confetti for depth perception */
            let blurredCell = CAEmitterCell()
            blurredCell.setValuesForShowerBlurred()
            blurredCell.contents = ConfettiShape.blurImage(ConfettiShape.rectangleConfetti(size: size, color: colors[0]), radius: 2)
            cells.append(blurredCell)
            
            confettiEmitter.emitterCells = cells
            
            /* Start showing the confetti */
            confettiEmitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(confettiEmitter)
            
            /* Remove the confetti emitter */
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                confettiEmitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                    confettiEmitter.removeFromSuperlayer()
                    completion()
                }
            }
        }
    }
}

extension CAEmitterCell {
    func setValuesForBurst1() {
        self.birthRate = 12
        self.lifetime = 7
        self.velocity = 250
        self.velocityRange = 50
        self.yAcceleration = -80
        self.emissionLongitude = .pi
        self.emissionRange = .pi/4
        self.spin = 1
        self.spinRange = 3
        self.scaleRange = 1
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
    }
    
    func setValuesForBurst2() {
        self.birthRate = 0
        self.velocity = 200
        self.yAcceleration = 5
    }
    
    func setValuesForShower() {
        self.birthRate = 16
        self.lifetime = 7
        self.velocity = 200
        self.velocityRange = 50
        self.emissionLongitude = .pi
        self.emissionRange = .pi/4
        self.spin = 1
        self.spinRange = 3
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
    }
    
    func setValuesForShowerBlurred() {
        self.birthRate = 1
        self.lifetime = 7
        self.velocity = 300
        self.velocityRange = 50
        self.emissionLongitude = .pi
        self.spin = 1
        self.spinRange = 3
        self.scale = 3
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
    }
}


extension ConfettiShape {
    
    fileprivate static func rectangleConfetti(size: CGSize, color: UIColor) -> CGImage {
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
        
        return image!.cgImage!
    }
    
    fileprivate static func spiralConfetti(size: CGSize, color: UIColor) -> CGImage {
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
        
        return image!.cgImage!
    }
    
    fileprivate static func circleConfetti(size: CGSize, color: UIColor) -> CGImage {
        let diameter = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.cgImage!
    }
    
    fileprivate static func blurImage(_ image: CGImage, radius: Int) -> CGImage {
        guard radius != 0 else {
            return image
        }
        let imageToBlur = CIImage(cgImage: image)
        let blurfilter = CIFilter(name: "CIGaussianBlur")!
        blurfilter.setValue(radius, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let context = CIContext(options: nil)
        return context.createCGImage(resultImage, from: resultImage.extent)!
    }
}



