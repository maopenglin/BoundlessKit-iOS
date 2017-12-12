//
//  CustomClassMethod.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation


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
        
        NSObject.swizzleReinforceableMethod(
            originalClass: originalClass,
            originalSelector: NSSelectorFromString(action)
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
    convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        guard components.count == 3,
            components[0] == "customClassMethod"
            else { return nil }
        
        self.init(target: components[1], action: components[2])
    }
    
    convenience init?(targetInstance: NSObject) {
        let target = NSStringFromClass(type(of: targetInstance))
        guard let action = CustomClassMethod.registeredMethods[target] else { DopeLog.error("No method found"); return nil }
        
        self.init(target: target, action: action)
    }
    
    convenience init(target: Any, action: Selector) {
        self.init(target: NSStringFromClass(type(of: target) as! AnyClass), action: NSStringFromSelector(action))
    }
}

extension NSObject {
    fileprivate class func swizzle(originalClass: AnyClass, originalSelector: Selector, swizzledClass: AnyClass, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(originalClass, originalSelector) else { DopeLog.error("class_getInstanceMethod(\"\(originalClass), \(originalSelector)\") failed"); return }
        guard let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector) else { DopeLog.error("class_getInstanceMethod(\"\(swizzledClass), \(swizzledSelector)\") failed"); return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    fileprivate class func swizzleReinforceableMethod(originalClass: AnyClass, originalSelector: Selector) {
        guard originalClass.isSubclass(of: NSObject.self) else { DopeLog.debug("Not a NSObject"); return }
        guard let originalMethod = class_getInstanceMethod(originalClass, originalSelector) else { DopeLog.error("class_getInstanceMethod(\"\(originalClass), \(originalSelector)\") failed"); return }
        guard let swizzledMethodNoParams = class_getInstanceMethod(NSObject.self, #selector(reinforceMethod)) else { DopeLog.error("failed"); return }
        
        self.swizzle(
            originalClass: originalClass.self,
            originalSelector: originalSelector,
            swizzledClass: NSObject.self,
            swizzledSelector: method_getNumberOfArguments(originalMethod) == method_getNumberOfArguments(swizzledMethodNoParams) ? #selector(reinforceMethod) : #selector(reinforceMethodWithTap(_:))
        )
        
        print("Swizzerped num args:\(method_getNumberOfArguments(originalMethod))")
    }
    
    @objc func reinforceMethod() {
        reinforceMethod()
        
        CustomClassMethod(targetInstance: self)?.attemptReinforcement()
    }
    
    @objc func reinforceMethodWithTap(_ sender: UITapGestureRecognizer) {
        reinforceMethodWithTap(sender)
        
        CustomClassMethod(targetInstance: self)?.attemptReinforcement()
    }
}
