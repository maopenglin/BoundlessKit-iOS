//
//  UITouchExtensions.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UITouch {
    
    func attemptReinforcement() {
        if let view = self.view,
            self.phase == .ended {
            let senderClassname = NSStringFromClass(Swift.type(of: self))
            let targetName = view.getParentResponders().joined(separator: ",")
            let selectorName = "ended"
            
            DopamineVersion.current.codelessReinforcementFor(sender: senderClassname, target: targetName, selector: selectorName)  { reinforcement in
                guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
                guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if let viewsAndLocations = self.reinforcementViews(options: reinforcement) {
                        EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                    }
                }
                
            }
        }
    }
    
    func reinforcementViews(options: [String: Any]) -> [(UIView, CGPoint)]? {
        
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
            viewsAndLocations = [(UIWindow.topWindow!, Helper.lastTouchLocationInUIWindow)]
            
        case "superview":
            guard let superview = view?.superview else {
                DopeLog.error("Could not find superview", visual: true)
                return nil
            }
            
            viewsAndLocations = [(superview, CGPoint(x: superview.bounds.width / 2, y: superview.bounds.height / 2))]
            
        case "target":
            guard let view = view else {
                DopeLog.error("Could not find target view", visual: true)
                return nil
            }
            
            viewsAndLocations = [(view, CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2))]
            
            
        case "custom":
            guard viewCustom != "" else {
                DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                return nil
            }
            
            viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                return CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
            })
            
        default:
            DopeLog.error("Unknown ViewOption <\(viewOption)>", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
