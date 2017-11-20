////
////  DLUIManager.swift
////  DopamineKit
////
////  Created by Akash Desai on 11/19/17.
////
//
//import Foundation
//
//
//import Foundation
//import UIKit
//
//@objc
//public class DLUIManager: NSObject {
//    
//    @objc
//    public static var main = DLUIManager()
//    
//    public var _window: DLWindow! = nil
//    open var window: DLWindow {
//        get {
//            if _window == nil {
//                _window = DLWindow(frame: UIScreen.main.bounds)
//                _window?.rootViewController = viewController
//                _window.isHidden = false
//                _window.alpha = 1
//            }
//            return _window!
//        }
//    }
//    
//    var _viewController: DLViewController! = nil
//    var viewController: DLViewController {
//        get {
//            if _viewController == nil {
//                _viewController = DLViewController()
//            }
//            return _viewController!
//        }
//    }
//    
//    public func show(_ animated: Bool = false) {
//        if animated {
//            self.window.isHidden = false
//            UIView.animate(withDuration: 0.3, animations: { () -> Void in
//                self.window.alpha = 1
//            })
//        } else {
//            self.window.isHidden = false
//            self.window.alpha = 1
//        }
//    }
//    
//    public func hide(_ animated: Bool = true) {
//        if animated {
//            UIView.animate(withDuration: 0.3, animations: { () -> Void in
//                self.window.alpha = 0
//            }, completion: { finished in
//                self.window.isHidden = true
//            })
//        } else {
//            window.isHidden = true
//        }
//    }
//}

