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
        - colors: This directly affects the quantity of confetti. For example, [.blue] will show half as much confetti as [.blue, .blue]
     */
    public func showConfetti(duration:Double = 0,
                      size:CGSize = CGSize(width: 9, height: 6),
                      shapes:[ConfettiShape] = [.rectangle, .rectangle, .circle],
                      colors:[UIColor] = [UIColor.from(hex: "4d81fb", alpha: 0.8), UIColor.from(hex: "4ac4fb", alpha: 0.8), UIColor.from(hex: "9243f9", alpha: 0.8), UIColor.from(hex: "fdc33b", alpha: 0.8), UIColor.from(hex: "f7332f", alpha: 0.8)],
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
            for shape in shapes {
                let confettiImage: CGImage
                switch shape {
                case .rectangle:
                    confettiImage = ConfettiShape.rectangleConfetti(size: size)
                case .circle:
                    confettiImage = ConfettiShape.circleConfetti(size: size)
                case .spiral:
                    confettiImage = ConfettiShape.spiralConfetti(size: size)
                }
                for color in colors {
                    let cell = CAEmitterCell()
                    cell.setValuesForBurstPhase1()
                    cell.contents = confettiImage
                    cell.color = color.cgColor
                    cells.append(cell)
                }
            }
            confettiEmitter.emitterCells = cells
            
            /* Start showing the confetti */
            confettiEmitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(confettiEmitter)
            completion()
            
            /* Remove the burst effect */
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 4) {
                for cell in confettiEmitter.emitterCells! {
                    cell.setValuesForBurstPhase2()
                }
                
                /* Remove the confetti emitter */
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 3/4) {
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
            for shape in shapes {
                let confettiImage: CGImage
                switch shape {
                case .rectangle:
                    confettiImage = ConfettiShape.rectangleConfetti(size: size)
                case .circle:
                    confettiImage = ConfettiShape.circleConfetti(size: size)
                case .spiral:
                    confettiImage = ConfettiShape.spiralConfetti(size: size)
                }
                for color in colors {
                    let cell = CAEmitterCell()
                    cell.setValuesForShower()
                    cell.contents = confettiImage
                    cell.color = color.cgColor
                    cells.append(cell)
                    /* Create some blurred confetti for depth perception */
                    let rand = Int(arc4random_uniform(2))
                    if rand != 0 {
                        let blurredCell = CAEmitterCell()
                        blurredCell.setValuesForShowerBlurred(scale: rand)
                        blurredCell.contents = confettiImage.blurImage(radius: rand)
                        blurredCell.color = color.cgColor
                        cells.append(blurredCell)
                    }
                }
            }
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

fileprivate extension CAEmitterCell {
    fileprivate func setValuesForBurstPhase1() {
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
    
    fileprivate func setValuesForBurstPhase2() {
        self.birthRate = 0
        self.velocity = 300
        self.yAcceleration = 200
    }
    
    fileprivate func setValuesForShower() {
        self.birthRate = 10
        self.lifetime = 7
        self.velocity = 200
        self.velocityRange = 50
        self.yAcceleration = 200
        self.emissionLongitude = .pi
        self.emissionRange = .pi/4
        self.spin = 1
        self.spinRange = 3
        self.scale = 0.6
        self.scaleRange = 0.8
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
    }
    
    fileprivate func setValuesForShowerBlurred(scale: Int) {
        self.birthRate = 1
        self.lifetime = 7
        self.velocity = 300
        self.velocityRange = 150
        self.yAcceleration = 200
        self.emissionLongitude = .pi
        self.spin = 1
        self.spinRange = 3
        self.scale = CGFloat(1 + scale)
        self.scaleRange = 2
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
    }
}


fileprivate extension ConfettiShape {
    
    fileprivate static func rectangleConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
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
    
    fileprivate static func spiralConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
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
    
    fileprivate static func circleConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
        let diameter = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.cgImage!
    }
}

fileprivate extension CGImage {
     fileprivate func blurImage(radius: Int) -> CGImage {
        guard radius != 0 else {
            return self
        }
        let imageToBlur = CIImage(cgImage: self)
        let blurfilter = CIFilter(name: "CIGaussianBlur")!
        blurfilter.setValue(radius, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.value(forKey: kCIOutputImageKey) as! CIImage
        
        let context = CIContext(options: nil)
        return context.createCGImage(resultImage, from: resultImage.extent)!
    }
}



