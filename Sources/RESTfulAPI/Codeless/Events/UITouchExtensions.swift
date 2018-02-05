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
            DispatchQueue.main.async {
                UIWindow.lastTouchPoint = view.convert(self.location(in: view), to: nil)
            }
            
            let senderClassname = NSStringFromClass(Swift.type(of: self))
            let targetName = NSStringFromClass(Swift.type(of: view))
            let selectorName = "ended"
            
            DopamineChanges.shared.delegate?.attemptingReinforcement(senderInstance: self, targetInstance: view, actionSelector: selectorName)
            
            DopamineVersion.current.codelessReinforcementFor(sender: senderClassname, target: targetName, selector: selectorName)  { reinforcement in
                guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
                guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if let viewsAndLocations = self.reinforcementViews(options: reinforcement) {
                        Reinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                    }
                }
                
            }
        }
    }
    
    private func reinforcementViews(options: [String: Any]) -> [(UIView, CGPoint)]? {
        
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
            viewsAndLocations = [(UIWindow.topWindow!, UIWindow.lastTouchPoint.withMargins(marginX: viewMarginX, marginY: viewMarginY))]
            
        case "superview":
            guard let superview = view?.superview else {
                DopeLog.error("Could not find superview", visual: true)
                return nil
            }
            
            viewsAndLocations = [(superview, superview.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            
        case "target":
            guard let view = view else {
                DopeLog.error("Could not find target view", visual: true)
                return nil
            }
            
            viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            
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
