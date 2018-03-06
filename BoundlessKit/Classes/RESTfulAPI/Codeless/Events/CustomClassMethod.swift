//
//  CustomClassMethod.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation


internal class CustomClassMethod : NSObject {
    
    enum SwizzleType : String {
        case
        noParam = "noParamAction",
        tapActionWithSender = "tapInitWithTarget",
        collectionDidSelect = "collectionDidSelect",
        viewControllerDidAppear = "viewControllerDidAppear",
        viewControllerDidDisappear = "viewControllerDidDisappear"
    }
    
    let sender: String
    let target: String
    let action: String
    
    init(sender: String, target: String, action: String) {
        self.sender = sender
        self.target = target
        self.action = action
    }
    
    convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        guard components.count == 3
            else { return nil }
        
        self.init(sender: components[0], target: components[1], action: components[2])
    }
    
    convenience init?(senderType: SwizzleType, targetInstance: NSObject) {
        let target = NSStringFromClass(type(of: targetInstance))
        guard let action = CustomClassMethod.registeredMethods["\(senderType.rawValue)-\(target)"] else { BoundlessLog.error("No method found for sender-target:\(senderType.rawValue)-\(target)"); return nil }
        
        self.init(sender: senderType.rawValue, target: target, action: action)
    }
    
    convenience init?(swizzleType: SwizzleType, targetName: String?, actionName: String?) {
        if let targetName = targetName,
            let actionName = actionName {
            self.init(sender: swizzleType.rawValue, target: targetName, action: actionName)
        } else {
            return nil
        }
    }
    
    fileprivate static var registeredMethods: [String:String] = [:]
    
    public static let registerMethods: Void = {
        for actionID in BoundlessVersion.current.actionIDs {
            CustomClassMethod(actionID: actionID)?.registerMethod()
        }
    }()
    
    public static func registerVisualizerMethods() {
        for actionID in BoundlessVersion.current.visualizerActionIDs {
            CustomClassMethod(actionID: actionID)?.registerMethod()
        }
    }
    
    fileprivate func registerMethod() {
        guard BoundlessConfiguration.current.integrationMethod == "codeless" else {
            BoundlessLog.debug("Codeless integration mode disabled")
            return
        }
        guard let originalClass = NSClassFromString(target).self else {
            BoundlessLog.error("Invalid class <\(target)>")
            return
        }
        let originalSelector = NSSelectorFromString(action)
//        guard originalSelector != Selector() else {
//            BoundlessLog.error("Invalid action selector <\(action)>")
//            return
//        }
        
        guard CustomClassMethod.registeredMethods["\(sender)-\(target)"] == nil else { return }
        
        NSObject.swizzleReinforceableMethod(
            swizzleType: sender,
            originalClass: originalClass,
            originalSelector: originalSelector
        )
        
        CustomClassMethod.registeredMethods["\(sender)-\(target)"] = action
    }
    
}

extension CustomClassMethod {
    func attemptReinforcement() {
        BoundlessVersion.current.codelessReinforcementFor(sender: sender, target: target, selector: action)  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { BoundlessLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { BoundlessLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(options: reinforcement) {
                    EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
        }
    }
    
    func attemptViewControllerReinforcement(vc: UIViewController) {
        BoundlessVersion.current.codelessReinforcementFor(sender: sender, target: target, selector: action)  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { BoundlessLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { BoundlessLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(viewController: vc, options: reinforcement) {
                    EventReinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
        }
    }
    
    private func reinforcementViews(viewController: UIViewController? = nil, options: [String: Any]) -> [(UIView, CGPoint)]? {
        
        guard let viewOption = options["ViewOption"] as? String else { BoundlessLog.error("Missing parameter", visual: true); return nil }
        guard let viewCustom = options["ViewCustom"] as? String else { BoundlessLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginX = options["ViewMarginX"] as? CGFloat else { BoundlessLog.error("Missing parameter", visual: true); return nil }
        guard let viewMarginY = options["ViewMarginY"] as? CGFloat else { BoundlessLog.error("Missing parameter", visual: true); return nil }
        
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
                BoundlessLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                return nil
            }
            
        case "target":
            if let view = viewController?.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                BoundlessLog.error("Could not find viewController view", visual: true)
                return nil
            }
            
        case "superview":
            if let vc = viewController,
                let parentVC = vc.presentingViewController,
                let view = parentVC.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                BoundlessLog.error("Could not find viewController parent view", visual: true)
                return nil
            }
            
        default:
            BoundlessLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}

extension NSObject {
    fileprivate class func swizzle(originalClass: AnyClass, originalSelector: Selector, swizzledClass: AnyClass, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(originalClass, originalSelector) else { BoundlessLog.error("class_getInstanceMethod(\"\(originalClass), \(originalSelector)\") failed"); return }
        guard let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector) else { BoundlessLog.error("class_getInstanceMethod(\"\(swizzledClass), \(swizzledSelector)\") failed"); return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        BoundlessLog.debug("Swizzled class:\(originalClass) method:\(originalSelector)")
    }
    
    fileprivate class func swizzleReinforceableMethod(swizzleType: String, originalClass: AnyClass, originalSelector: Selector) {
        guard originalClass.isSubclass(of: NSObject.self) else { BoundlessLog.debug("Not a NSObject"); return }
        guard let _ = class_getInstanceMethod(originalClass, originalSelector) else { BoundlessLog.error("class_getInstanceMethod(\"\(originalClass), \(originalSelector)\") failed"); return }
        
        
        var swizzledSelector: Selector
        if (swizzleType == CustomClassMethod.SwizzleType.noParam.rawValue) {
            swizzledSelector = #selector(reinforceMethodWithoutParams)
        } else if (swizzleType == CustomClassMethod.SwizzleType.tapActionWithSender.rawValue) {
            swizzledSelector = #selector(reinforceMethodTapWithSender(_:))
        } else if (swizzleType == CustomClassMethod.SwizzleType.collectionDidSelect.rawValue) {
            swizzledSelector = #selector(reinforceCollectionSelection(_:didSelectItemAt:))
        } else if (swizzleType == CustomClassMethod.SwizzleType.viewControllerDidAppear.rawValue) {
            return
        } else if (swizzleType == CustomClassMethod.SwizzleType.viewControllerDidDisappear.rawValue) {
            return
        } else {
            BoundlessLog.error("Unknown Swizzle Type: \(swizzleType)")
            return
        }
        
        
        self.swizzle(
            originalClass: originalClass.self,
            originalSelector: originalSelector,
            swizzledClass: NSObject.self,
            swizzledSelector: swizzledSelector
            
        )
    }
    
    @objc func reinforceMethodWithoutParams() {
        reinforceMethodWithoutParams()
        
        CustomClassMethod(senderType: .noParam, targetInstance: self)?.attemptReinforcement()
    }
    
    @objc func reinforceMethodTapWithSender(_ sender: UITapGestureRecognizer) {
        reinforceMethodTapWithSender(sender)
        
        CustomClassMethod(senderType: .tapActionWithSender, targetInstance: self)?.attemptReinforcement()
    }
    
    @objc func reinforceCollectionSelection(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        reinforceCollectionSelection(collectionView, didSelectItemAt: indexPath)
        
        CustomClassMethod(senderType: .collectionDidSelect, targetInstance: self)?.attemptReinforcement()
    }
}