//
//  DLGlow.swift
//  To Do List
//
//  Created by Akash Desai on 10/3/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    public func showGlow() {
        showGlow(duration: 0.2, color: UIColor(red: 153/256.0, green: 101/256.0, blue: 21/256.0, alpha: 0.8), alpha: 0.8, radius: 50, count: 2)
    }
    
    public func showGlow(duration: Double, color: UIColor, alpha: CGFloat, radius: CGFloat, count: Float) {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        color.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: self.bounds.size)).fill(with: .sourceAtop, alpha:1.0)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        let glowView = UIImageView(image: image)
        glowView.center = self.center
        glowView.alpha = 0
        glowView.layer.shadowColor = color.cgColor
        glowView.layer.shadowOffset = .zero
        glowView.layer.shadowRadius = radius
        glowView.layer.shadowOpacity = 1.0
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = alpha
        animation.repeatCount = count
        animation.duration = duration
//        animation.speed = 0.35
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        GlowAnimationDelegate(
            willStart: { start in
                self.superview!.insertSubview(glowView, aboveSubview:self)
                start()
        },
            didStop: {
                glowView.removeFromSuperview()
        }
            ).start(view: glowView, animation: animation)
    }
}

fileprivate class GlowAnimationDelegate : NSObject, CAAnimationDelegate {
    
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

