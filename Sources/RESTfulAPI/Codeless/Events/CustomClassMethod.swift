//
//  CustomClassMethod.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation

extension NSObject {
    @objc func reinforceMethod() {
        reinforceMethod()
        
        CustomClassMethod(targetInstance: self)?.attemptReinforcement()
    }
}

internal class CustomClassMethod : NSObject {
    
    let sender: String = "customClassMethod"
    let target: String
    let action: String
    
    init(target: String, action: String) {
        self.target = target
        self.action = action
    }
    
    fileprivate static var registeredMethods: [String:String] = [:]
    
    public static let registerMethods: Void = {
        for actionID in DopamineVersion.current.actionIDs {
            CustomClassMethod(actionID: actionID)?.registerMethod()
        }
    }()
    
    public static func registerVisualizerMethods() {
        for actionID in DopamineVersion.current.visualizerActionIDs {
            CustomClassMethod(actionID: actionID)?.registerMethod()
        }
    }
    
    fileprivate func registerMethod() {
        guard let originalClass = NSClassFromString(target).self
            else { DopeLog.error("Invalid class <\(target)>"); return}
        
        guard CustomClassMethod.registeredMethods[target] == nil else { return }
        
        CustomClassMethod.swizzle(
            originalClass: originalClass,
            originalSelector: NSSelectorFromString(action),
            swizzledClass: NSObject.self,
            swizzledSelector: #selector(reinforceMethod)
        )
        
        CustomClassMethod.registeredMethods[target] = action
    }
    
}

extension CustomClassMethod {
    func attemptReinforcement() {
        
        DopamineVersion.current.codelessReinforcementFor(sender: sender, target: target, selector: action)  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(options: reinforcement) {
                    EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
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
            
        case "custom":
            viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
            })
            
            if viewsAndLocations?.count == 0 {
                DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}

extension CustomClassMethod {
    convenience init?(targetInstance: NSObject) {
        let target = NSStringFromClass(type(of: targetInstance))
        guard let action = CustomClassMethod.registeredMethods[target] else { DopeLog.error("No method found"); return nil }
        
        self.init(target: target, action: action)
    }
    
    convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        guard components.count == 3,
            components[0] == "customClassMethod"
            else { return nil }
        
        self.init(target: components[1], action: components[2])
    }
    
    convenience init(target: Any, action: Selector) {
        self.init(target: NSStringFromClass(type(of: target) as! AnyClass), action: NSStringFromSelector(action))
    }
}

extension CustomClassMethod {
    fileprivate static func swizzle(originalClass: AnyClass, originalSelector: Selector, swizzledClass: AnyClass, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(originalClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector)
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
}
