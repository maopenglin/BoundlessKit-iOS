//
//  UIView+UIView+DopamineAnimation.swift
//  DopamineKit
//
//  Created by Akash Desai on 9/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

// call all these in main queue DispatchQueue.main
public extension UIView {
    
    @objc public func showGrowObjc(completionHandler: @escaping () -> Void = {}) {
        showGrow(completionHandler: completionHandler)
    }
    
    public func showGrow(count: Int = 12, duration: TimeInterval = 0.5, scaleX: CGFloat = 0.96, scaleY: CGFloat = 1, completionHandler: @escaping () -> Void = {}) {
        
        
        let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
        scaleAnimation.repeatCount = Float(count)
        scaleAnimation.duration = duration / TimeInterval(scaleAnimation.repeatCount)
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = scaleX
        scaleAnimation.autoreverses = true
        scaleAnimation.initialVelocity = 5
        scaleAnimation.damping = 2
//        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
//        scaleAnimation.repeatCount = Float(count)
//        scaleAnimation.duration = duration
//        scaleAnimation.fromValue = 1
//        scaleAnimation.toValue = scaleX
//        scaleAnimation.autoreverses = true

        CoreAnimationDelegate(
            didStart:{
                print("here3")
        }, didStop: {
            completionHandler()
        }).start(view: self, animation: scaleAnimation)
        
        // applause
//        if count < 0 {
//            DispatchQueue.main.async {
//                self.transform = .identity
//                self.layer.removeAllAnimations()
//                print("here")
//            }
//            completionHandler()
//            return
//        }
//
//        UIView.animateKeyframes(withDuration: duration / TimeInterval(count),
//                       delay: 0,
//                       options: [],
//                       animations: {
//                        if count % 2 == 0 {
//                        self.transform = CGAffineTransform.init(scaleX: scaleX, y: scaleY)
//                        } else {
//                        self.transform = CGAffineTransform.init(scaleX: 1, y: 1)
//                        }
//        },
//                       completion:{ finished in
//                        guard finished else { return }
//                        self.showGrow(count: count - 1)
//                        print("here1")
//        }
//        )
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
////            self.animation
//        }
    }
    
    public func showShimmy(count:Int = 2, duration:TimeInterval = 5.0, translation:Int = 10, speed:Float = 3, completion: @escaping ()->Void = {}) {
        
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
    
    public func rotate360Degrees(count: Float = 2, duration: CFTimeInterval = 1.0, completion: @escaping ()->Void = {}) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.repeatCount = count
        rotateAnimation.duration = duration/TimeInterval(rotateAnimation.repeatCount)
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = 2.0 * CGFloat.pi
        
        CoreAnimationDelegate(didStop: completion).start(view: self, animation: rotateAnimation)
    }
    
    public func showPulse(count: Float = 1, duration: TimeInterval = 0.86, scale: CGFloat = 1.4, velocity: CGFloat = 5.0, damping: CGFloat = 2.0, completion: @escaping ()->Void = {}) {
        
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.repeatCount = count
        pulse.duration = duration/TimeInterval(pulse.repeatCount)
        pulse.toValue = scale
        pulse.autoreverses = true
        pulse.initialVelocity = velocity
        pulse.damping = damping
        
        CoreAnimationDelegate(didStop: completion).start(view: self, animation: pulse)
    }
    
    public func showVibrate(duration:TimeInterval = 1.0, vibrateCount:Int = 6, vibrateTranslation:Int = 20, vibrateSpeed:Float = 3, scale: CGFloat = 0.95, scaleVelocity: CGFloat = 5.0, scaleDamping: CGFloat = 8)  {
        
        let path = UIBezierPath()
        path.move(to: .zero)
        for _ in 1...vibrateCount {
            path.addLine(to: CGPoint(x: vibrateTranslation, y: 0))
            path.addLine(to: CGPoint(x: -vibrateTranslation, y: 0))
        }
        path.close()
        
        let vibrateAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        vibrateAnimation.repeatCount = 1
        vibrateAnimation.duration = duration
        vibrateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        vibrateAnimation.path = path.cgPath
        vibrateAnimation.speed = vibrateSpeed
        
        let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
        scaleAnimation.repeatCount = 0
        scaleAnimation.duration = 0.3
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = scale
        scaleAnimation.autoreverses = true
        scaleAnimation.initialVelocity = scaleVelocity
        scaleAnimation.damping = scaleDamping
        
        let group = CAAnimationGroup()
        let oldClipsToBounds = clipsToBounds
        group.animations = [vibrateAnimation, scaleAnimation]
        group.duration = duration
        CoreAnimationDelegate(didStart:{
//            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.layer.masksToBounds = false
        }, didStop: {
            self.clipsToBounds = oldClipsToBounds
        }
            ).start(view: self, animation: group)
    }
    
    public func showGlow(duration: Double = 0.2, color: UIColor = UIColor(red: 153/256.0, green: 101/256.0, blue: 21/256.0, alpha: 0.8), alpha: CGFloat = 0.8, radius: CGFloat = 50, count: Float = 2) {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        color.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: self.bounds.size)).fill(with: .sourceAtop, alpha:1.0)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        let glowView = UIImageView(image: image)
        glowView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
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
        
        CoreAnimationDelegate(
            willStart: { start in
//                self.superview!.insertSubview(glowView, aboveSubview:self)
                self.insertSubview(glowView, aboveSubview: self)
                start()
        },
            didStop: {
                glowView.removeFromSuperview()
        }
            ).start(view: glowView, animation: animation)
    }
    
    public func showSheen(duration: Double = 2.0, color: UIColor? = nil) {
        guard let bundle = DopamineKit.frameworkBundle else {
            return
        }
//        let image = UIImage(named: "sheen", in: bundle, compatibleWith: nil)
        
//        var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil)
//        if let color = color {
//            image = image?.withRenderingMode(.alwaysTemplate)
//            imageView.tintColor = color
//        }
        
        var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil)
        if let color = color {
            image = image?.tint(tintColor: color)
        }
        
        
        let imageView = UIImageView(image: image)
        
        let height = self.frame.height
        let width: CGFloat = height * 1.667
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        //        animation.speed = 2.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + width
        
        CoreAnimationDelegate(
            willStart: { start in
                self.addSubview(imageView)
                start()
        },
            didStop: {
                imageView.removeFromSuperview()
        }
            ).start(view: imageView, animation: animation)
    }
}

fileprivate class CoreAnimationDelegate : NSObject, CAAnimationDelegate {
    
    let willStart: (@escaping()->Void)->Void
    let didStart: ()->Void
    let didStop: ()->Void
    
    init(willStart: @escaping (@escaping()->Void)->Void = {startAnimation in startAnimation()}, didStart: @escaping ()->Void = {}, didStop: @escaping ()->Void = {}) {
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
