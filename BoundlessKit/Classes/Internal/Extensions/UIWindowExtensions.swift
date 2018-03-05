//
//  UIWindowExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UIWindow {
    static func presentTopLevelAlert(alertController:UIAlertController, completion:(() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alertController, animated: true, completion: completion)
        }
    }
}

internal extension UIWindow {
    class var topWindow: UIWindow? {
        get {
            if let window = UIApplication.shared.keyWindow {
                return window
            }
            for window in UIApplication.shared.windows.reversed() {
                if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero { return window }
            }
            return nil
        }
    }
    
    static var lastTouchPoint: CGPoint {
        get {
            return EventReinforcement.lastTouchLocationInUIWindow
        }
        set {
            EventReinforcement.lastTouchLocationInUIWindow = newValue
        }
    }
}

internal extension UIWindow {
    func viewControllerStack() -> [UIViewController] {
        var accumulator = [UIViewController]()
        
        var vc = rootViewController
        while(vc != nil) {
            accumulator.append(vc!)
            if let tabController = vc as? UITabBarController {
                vc = tabController.selectedViewController
            } else if let navController = vc as? UINavigationController {
                if navController.viewControllers.isEmpty == false {
                    accumulator.append(contentsOf: navController.viewControllers)
                    accumulator.removeLast()
                }
                vc = navController.topViewController
            } else {
                vc = vc?.presentedViewController
            }
        }
        return accumulator
    }
}
