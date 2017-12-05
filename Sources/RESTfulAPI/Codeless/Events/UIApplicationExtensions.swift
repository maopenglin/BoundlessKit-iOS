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
    
    private func reinforcementViews(senderInstance: AnyObject, targetInstance: AnyObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
        
        guard let viewOption = options["ViewOption"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewCustom = options["ViewCustom"] as? String else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginX = options["ViewMarginX"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginY = options["ViewMarginY"] as? CGFloat else { DopeLog.error("Missing parameter", visual: true); return nil }
        
        let viewsAndLocations: [(UIView, CGPoint)]?
        
        switch viewOption {
        case "fixed":
            let view = UIWindow.topWindow!
            viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            
        case "touch":
            viewsAndLocations = [(UIWindow.topWindow!, UIWindow.lastTouchPoint.withMargins(marginX: viewMarginX, marginY: viewMarginY))]
            
        case "sender":
            if let view = senderInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                let view = senderInstance.value(forKey: "view") as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if senderInstance.responds(to: NSSelectorFromString("imageView")),
                let view = senderInstance.value(forKey: "imageView") as? UIImageView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find sender view for \(type(of: senderInstance))", visual: true)
                return nil
            }
            
        case "superview":
            if let senderInstance = senderInstance as? UIView,
                let superview = senderInstance.superview {
                viewsAndLocations = [(superview, superview.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if senderInstance.responds(to: NSSelectorFromString("view")),
                let view = senderInstance.value(forKey: "view") as? UIView,
                let superview = view.superview {
                viewsAndLocations = [(superview, superview.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find superview", visual: true)
                return nil
            }
            
        case "target":
            if let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if targetInstance.responds(to: NSSelectorFromString("view")),
                let view = targetInstance.value(forKey: "view") as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find target view", visual: true)
                return nil
            }
            
            
        case "custom":
            viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
            })
            
            if viewsAndLocations?.count == 0 {
                DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unknown ViewOption <\(viewOption)>", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
