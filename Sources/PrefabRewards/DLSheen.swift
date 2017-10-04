//
//  DLSheen.swift
//  To Do List
//
//  Created by Akash Desai on 10/3/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

fileprivate class SheenAnimationDelegate : NSObject, CAAnimationDelegate {
    
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

extension UIView {
    func showSheen() {
        let imageView = UIImageView(image: UIImage(named: "sheen")!)
        
        let height = self.frame.height
        let width: CGFloat = height * 1.667
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = 2.0
//        animation.speed = 2.0
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + width
        
        SheenAnimationDelegate(
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
