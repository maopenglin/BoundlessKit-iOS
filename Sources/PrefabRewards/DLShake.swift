//
//  DLShake.swift
//  To Do List
//
//  Created by Akash Desai on 9/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    func shake(count:Int = 2, duration:TimeInterval = 5.0, translation:Int = 10, speed:Float = 3, completion: @escaping ()->Void = {}) {
        
        let path = UIBezierPath()
        path.move(to: .zero)
        for _ in 1...count {
            path.addLine(to: CGPoint(x: translation, y: 0))
            path.addLine(to: CGPoint(x: -translation, y: 0))
        }
        path.close()
        
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.repeatCount = 1
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.path = path.cgPath
        animation.speed = speed
        
        CoreAnimationDelegate(didStop: completion).start(view: self, animation: animation)
    }
    
    func rotate360Degrees(count: Float = 2, duration: CFTimeInterval = 1.0, completion: @escaping ()->Void = {}) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.repeatCount = count
        rotateAnimation.duration = duration/TimeInterval(rotateAnimation.repeatCount)
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = 2.0 * CGFloat.pi
        
        CoreAnimationDelegate(didStop: completion).start(view: self, animation: rotateAnimation)
    }
    
    func pulse(count: Float = 1, duration: TimeInterval = 0.86, scale: CGFloat = 1.4, velocity: CGFloat = 5.0, damping: CGFloat = 2.0, completion: @escaping ()->Void = {}) {
        
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.repeatCount = count
        pulse.duration = duration/TimeInterval(pulse.repeatCount)
        pulse.toValue = scale
        pulse.autoreverses = true
        pulse.initialVelocity = velocity
        pulse.damping = damping
        
        CoreAnimationDelegate(didStop: completion).start(view: self, animation: pulse)
    }
}

fileprivate class CoreAnimationDelegate : NSObject, CAAnimationDelegate {
    
    let willStart: (()->Void)->Void
    let didStart: ()->Void
    let didStop: ()->Void
    
    init(willStart: @escaping (()->Void)->Void = {startAnimation in startAnimation()}, didStart: @escaping ()->Void = {}, didStop: @escaping ()->Void = {}) {
        self.willStart = willStart
        self.didStart = didStart
        self.didStop = didStop
    }
    
    func start(view: UIView, animation:CAAnimation) {
        willStart() {
            animation.delegate = self
            view.layer.add(animation, forKey: nil)
        }
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        didStart()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            didStop()
        }
    }
}
