//
//  UIApplicationExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation


internal extension UIApplication {
    
    func attemptReinforcement(senderInstance: AnyObject, targetInstance: AnyObject, selectorObj: Selector) {
        let senderClassname = NSStringFromClass(type(of: senderInstance))
        let targetClassname = NSStringFromClass(type(of: targetInstance))
        let selectorName = NSStringFromSelector(selectorObj)
        
        DopamineVersion.current.codelessReinforcementFor(sender: senderClassname, target: targetClassname, selector: selectorName) { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(senderInstance: senderInstance, targetInstance: targetInstance, options: reinforcement) {
                    EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
            
        }
    }
    
    func reinforcementViews(senderInstance: AnyObject, targetInstance: AnyObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
        
        guard let viewOption = options["ViewOption"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewCustom = options["ViewCustom"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginX = options["ViewMarginX"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginY = options["ViewMarginY"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        
        let viewsAndLocations: [(UIView, CGPoint)]?
        
        switch viewOption {
        case "fixed":
            let view = UIWindow.topWindow!
            let xMargin = viewMarginX <= 1.0 && viewMarginX > 0 ? viewMarginX * view.bounds.width : viewMarginX
            let yMargin = viewMarginY <= 1.0 && viewMarginY > 0 ? viewMarginY * view.bounds.height : viewMarginY
            viewsAndLocations = [(view, CGPoint(x: xMargin, y: yMargin))]
            
        case "touch":
            viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
            
        case "sender":
            if let view = senderInstance as? UIView {
                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                let view = senderInstance.value(forKey: "view") as? UIView {
                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
            }
            DopeLog.error("Could not find sender view", visual: true)
            return nil
            
        case "superview":
            if let senderInstance = senderInstance as? UIView,
                let superview = senderInstance.superview {
                viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                let view = senderInstance.value(forKey: "view") as? UIView,
                let superview = view.superview {
                viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
            }
            DopeLog.error("Could not find superview", visual: true)
            return nil
            
        case "target":
            if let view = targetInstance as? UIView {
                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
            } else if targetInstance.responds(to: NSSelectorFromString("view")),
                let view = targetInstance.value(forKey: "view") as? UIView {
                viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
            }
            DopeLog.error("Could not find target view", visual: true)
            return nil
            
            
        case "custom":
            if viewCustom != "" {
                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                    return CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
                })
            }
            DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
            return nil
            
        default:
            DopeLog.error("Unknown ViewOption <\(viewOption)>", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
