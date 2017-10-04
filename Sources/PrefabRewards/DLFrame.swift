////
////  DLFrame.swift
////  To Do List
////
////  Created by Akash Desai on 5/29/17.
////  Copyright © 2017 DopamineLabs. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//
//extension UIView {
//    func showGoldenFrame() {
//        let frameImage = UIImage(named: "frame-gold")!
//        let frameView = UIImageView(image: frameImage)
//        frameView.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
//        let glassView = UIImageView(image: UIImage(named: "glass-foreground"))
//        glassView.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
//        glassView.alpha = 0
//        addSubview(glassView)
////        let frameView = UIView()
////        frameView.layer.borderColor = UIColor.yellow.cgColor
////        frameView.layer.borderWidth = 2.0
////        frameView.frame = self.frame.insetBy(dx: 2.0, dy: 2.0)
//        
//        frameView.alpha = 0
//        addSubview(frameView)
//        Helper.playPhotoSound()
//        
//        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: .curveEaseIn, animations: {
//            frameView.alpha = 1
//            glassView.alpha = 1
//            self.takeViewShot()
//        }) { _ in
//            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: .curveEaseOut, animations: {
//                frameView.alpha = CGFloat(0)
//                glassView.alpha = 0
//            }) { _ in
//                frameView.removeFromSuperview()
//            }
//        }
//    }
//    
//    func takeViewShot() {
//        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
//        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        if let image = image {
//            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
//        } else {
//            NSLog("Could not save view screenshot...")
//        }
//    }
//}
