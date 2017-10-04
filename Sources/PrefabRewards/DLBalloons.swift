//
//  DLBalloons.swift
//  To Do List
//
//  Created by Akash Desai on 5/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    public func showBalloons() {
        let largestSize = min(frame.width, frame.height) / 3
        let balloonSizes = [largestSize/2, largestSize/2, largestSize/3, largestSize]
        for size in balloonSizes {
            showBalloon(width: size, height: size)
        }
    }
    
    fileprivate func showBalloon(width: CGFloat, height: CGFloat) {
        let animation = CAKeyframeAnimation(keyPath: "position")
        let path = UIBezierPath()
        let balloonImage = UIImage(named: "three-balloon")!
        let balloonView = UIImageView(image: balloonImage)
        
        let xStart = CGFloat(randomWithMax: self.frame.maxX)
        let yStart = self.frame.maxY
        let xEnd = CGFloat(randomWithMax: self.frame.maxX)
        let yEnd = CGFloat(0)
        let xMid = xEnd / 2
        let yMid = CGFloat(randomWithMax: self.frame.maxY)
        
        balloonView.frame = CGRect(x: xStart, y: yStart, width: width, height: height)
        self.addSubview(balloonView)
        
        path.move(to: CGPoint(x: xStart,y: yStart))
        path.addQuadCurve(to: CGPoint(x: xEnd, y: yEnd), controlPoint: CGPoint(x: xMid, y: yMid))
        
        animation.path = path.cgPath
        animation.repeatCount = 0
        animation.duration = 5.0 - 0.5 * NSNumber.random(withMax: 3).doubleValue
        animation.fillMode = kCAFillModeRemoved
        animation.isRemovedOnCompletion = true
        let balloonDelegate = BalloonAnimationDelegate(balloonView: balloonView)
        animation.delegate = balloonDelegate
        balloonView.layer.add(animation, forKey: "random upward path")
    }
}

class BalloonAnimationDelegate : NSObject, CAAnimationDelegate {
    
    let balloonView: UIView
    
    init(balloonView: UIView) {
        self.balloonView = balloonView
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        balloonView.removeFromSuperview()
    }
}

extension CGFloat {
    init(randomWithMax max:CGFloat) {
        self.init(NSNumber.random(withMax: max as NSNumber))
    }
}

extension NSNumber {
    static func random(withMax max: NSNumber) -> NSNumber {
        return arc4random_uniform(UInt32(max)+1) as NSNumber
    }
}
