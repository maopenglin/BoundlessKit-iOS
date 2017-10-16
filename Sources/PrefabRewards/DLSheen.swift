//
//  DLSheen.swift
//  To Do List
//
//  Created by Akash Desai on 10/3/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    public func showSheen(duration: Double) {
        guard let bundle = DopamineKit.frameworkBundle else {
            return
        }
        let imageView = UIImageView(image: UIImage.init(named: "sheen", in: bundle, compatibleWith: nil))
        
        let height = self.frame.height
        let width: CGFloat = height * 1.667
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
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


fileprivate extension DopamineKit {
    fileprivate class var frameworkBundle: Bundle? {
        if let bundleURL = Bundle(for: DopamineKit.classForCoder()).url(forResource: "DopamineKit", withExtension: "bundle") {
            return Bundle(url: bundleURL)
        } else {
            DopamineKit.debugLog("The DopamineKit framework bundle cannot be found")
            return nil
        }
    }
}
