//
//  UIWindowExtensions.swift
//  DopamineKit
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
            return CodelessReinforcement.lastTouchLocationInUIWindow
        }
        set {
            CodelessReinforcement.lastTouchLocationInUIWindow = newValue
        }
    }
}


internal extension UIWindow {
    func getViewControllersWithClassname(classname: String) -> [UIViewController] {
        return rootViewController?.getSubViewControllersWithClassname(classname: classname) ?? []
    }
}
internal extension UIViewController {
    func getSubViewControllersWithClassname(classname: String) -> [UIViewController] {
        var vcs = [UIViewController]()
        
        if let tabController = self as? UITabBarController,
            let tabVCs = tabController.viewControllers {
            for vc in tabVCs.reversed() {
                vcs += vc.getSubViewControllersWithClassname(classname: classname)
            }
        } else if let navController = self as? UINavigationController {
            for vc in navController.viewControllers.reversed() {
                vcs += vc.getSubViewControllersWithClassname(classname: classname)
            }
        } else {
            if let vc = self.presentedViewController {
                vcs += vc.getSubViewControllersWithClassname(classname: classname)
            }
            for vc in childViewControllers.reversed() {
                vcs += vc.getSubViewControllersWithClassname(classname: classname)
            }
        }
        
        if classname == NSStringFromClass(type(of: self)) {
            vcs.append(self)
        }

//        do {
//            let regex = try NSRegularExpression(pattern: classname, options: [.caseInsensitive])
//            let myClassname = String(describing: type(of: self))
//            let matches = regex.numberOfMatches(in: myClassname, options: [], range: NSRange(location: 0, length: myClassname.count))
//            if (matches > 0) {
//                vcs.append(self)
//            }
//        } catch {
//            print(error)
//        }
        
        return vcs
    }
}
