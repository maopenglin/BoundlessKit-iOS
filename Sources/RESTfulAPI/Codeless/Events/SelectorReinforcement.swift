//
//  SelectorReinforcement.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation


@objc
open class SelectorReinforcement : NSObject {
    
    enum SelectorType : String {
        case
        appLaunch = "appLaunch",
        appTerminate = "appTerminate",
        appActive = "appActive",
        appInactive = "appInactive",
        viewControllerDidAppear = "viewControllerDidAppear",
        viewControllerDidDisappear = "viewControllerDidDisappear",
        collectionDidSelect = "collectionDidSelect",
        tapActionWithSender = "tapActionWithSender",
        noParamAction = "noParamAction"
        
        init?(from selector: Selector) {
            if (selector == #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:))) {
                self = .appLaunch
            } else if (selector == #selector(UIApplicationDelegate.applicationWillTerminate(_:))) {
                self = .appTerminate
            } else if (selector == #selector(UIApplicationDelegate.applicationDidBecomeActive(_:))) {
                self = .appActive
            } else if (selector == #selector(UIApplicationDelegate.applicationWillResignActive(_:))) {
                self = .appInactive
            } else if (selector == #selector(UIViewController.viewDidAppear(_:))) {
                self = .viewControllerDidAppear
            } else if (selector == #selector(UIViewController.viewDidDisappear(_:))) {
                self = .viewControllerDidDisappear
            } else if (selector == #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:))) {
                self = .collectionDidSelect
            } else if (!NSStringFromSelector(selector).contains(":")) {
                self = .noParamAction
            } else {
                return nil
            }
        }
    }
    
    let selectorType: String
    let target: String
    let action: String
    var actionID: String {
        get {
            return [selectorType, target, action].joined(separator: "-")
        }
    }
    
    @objc
    public static func rFor(target: NSObject, action: Selector) {
        SelectorReinforcement.init(selectorType: SelectorType.noParamAction, targetName: NSStringFromClass(type(of: target)), actionName: NSStringFromSelector(action))?.attemptReinforcement(targetInstance: target)
    }
    fileprivate init(selectorType: String, target: String, action: String) {
        self.selectorType = selectorType
        self.target = target
        self.action = action
    }
    
    fileprivate convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        guard components.count == 3 else {
            return nil
        }
        
        self.init(selectorType: components[0], target: components[1], action: components[2])
    }
    
    convenience init?(selectorType: SelectorType?, targetName: String?, actionName: String?) {
        if let targetName = targetName,
            let actionName = actionName,
            let selectorType = selectorType {
            self.init(selectorType: selectorType.rawValue, target: targetName, action: actionName)
        } else {
            return nil
        }
    }
    
    convenience init?(targetName: String?, selector: Selector?) {
        if let targetName = targetName,
            let selector = selector,
            let selectorType = SelectorType(from: selector) {
            self.init(selectorType: selectorType.rawValue, target: targetName, action: NSStringFromSelector(selector))
        } else {
            return nil
        }
    }
    
//    convenience init?(registeredFor selectorType: SelectorType, targetInstance: NSObject){
//        let target = NSStringFromClass(type(of: targetInstance))
////        guard let action = SelectorReinforcement.registeredMethods["\(senderType.rawValue)-\(target)"] else {
////            DopeLog.error("No method found for selectorType-target:\(senderType.rawValue)-\(target)")
////            return nil
////        }
//        guard let action = SelectorReinforcement.registeredMethods[target],
//        let selectorType = action
//        else {
//            DopeLog.error("No method found for selectorType-target:\(senderType.rawValue)-\(target)")
//            return nil
//        }
//
//        self.init(selectorType: selectorType.rawValue, target: target, action: action)
//    }
    
    // [target: [action:type]]
    fileprivate static var registeredMethods: [String:[String:SelectorType]] = [:]
    
    public static let registerMethods: Void = {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }()
    
    public static func registerVisualizerMethods() {
        for actionID in DopamineVersion.current.visualizerActionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    fileprivate func registerMethod() {
        DopeLog.debug("Attempting to register :\(self.actionID)")
        guard DopamineConfiguration.current.integrationMethod == "codeless" else {
            DopeLog.debug("Codeless integration mode disabled")
            return
        }
        guard let originalClass = NSClassFromString(target).self else {
            DopeLog.error("Invalid class <\(target)>")
            return
        }
//        guard SelectorReinforcement.registeredMethods["\(selectorType)-\(target)"] == nil else {
//            DopeLog.debug("Reinforcement for selectorType-target:\(selectorType)-\(target) method:\(action) already registered.")
//            return
//        }
        
        let originalSelector = NSSelectorFromString(action)
        
        NSObject.swizzleReinforceableMethod(
            swizzleType: selectorType,
            originalClass: originalClass,
            originalSelector: originalSelector
        )
        
//        SelectorReinforcement.registeredMethods["\(selectorType)-\(target)"] = [action: SelectorType(rawValue: selectorType)!]
    }
    
}

extension SelectorReinforcement {
    
    func attemptReinforcement(targetInstance: NSObject) {
        DopamineVersion.current.codelessReinforcementFor(sender: selectorType, target: target, selector: action)  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(targetInstance: targetInstance, options: reinforcement) {
                    Reinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
        }
    }
    
    private func reinforcementViews(targetInstance: NSObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
        
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
            let parts = viewCustom.components(separatedBy: "-")
            if parts.count == 2 {
                let vcClass = parts[0]
                let viewVarName = parts[1]
                print("VCClass:\(vcClass) viewVarName:\(viewVarName)")
                if vcClass == "self" {
                    if let view = targetInstance.value(forKey: viewVarName) as? UIView {
                        viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                    } else {
                        DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                        return nil
                    }
                } else if
                    let keyWindow = UIApplication.shared.keyWindow,
                    let vc = keyWindow.getViewControllersWithClassname(classname: vcClass).first,
                    let view = vc.value(forKey: viewVarName) as? UIView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
            } else {
                viewsAndLocations = UIView.find(viewCustom, { (view) -> CGPoint in
                    return view.pointWithMargins(x: viewMarginX, y: viewMarginY)
                })
                if viewsAndLocations?.count == 0 {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
            }
            
        case "target":
            if let viewController = targetInstance as? UIViewController,
                let view = viewController.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find viewController view", visual: true)
                return nil
            }
            
        case "superview":
            if let vc = targetInstance as? UIViewController,
                let parentVC = vc.presentingViewController,
                let view = parentVC.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find viewController parent view", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}

extension NSObject {
    fileprivate class func swizzleReinforceableMethod(swizzleType: String, originalClass: AnyClass, originalSelector: Selector) {
        guard originalClass.isSubclass(of: NSObject.self) else { DopeLog.debug("Not a NSObject"); return }
        guard let _ = class_getInstanceMethod(originalClass, originalSelector) else { DopeLog.error("class_getInstanceMethod(\"\(originalClass), \(originalSelector)\") failed"); return }
        
        
        var swizzledSelector: Selector
        if (swizzleType == SelectorReinforcement.SelectorType.noParamAction.rawValue) {
            swizzledSelector = #selector(DopamineObject.methodToReinforce)
        } else if (swizzleType == SelectorReinforcement.SelectorType.tapActionWithSender.rawValue) {
            swizzledSelector = #selector(DopamineObject.methodWithSenderToReinforce(_:))
        } else {
            DopeLog.debug("Registered reinforcement class:\(originalClass) method:\(originalSelector)")
            return
        }
        
        SwizzleHelper.injectSelector(DopamineAppDelegate.self, swizzledSelector, originalClass.self, originalSelector)
    }
}
