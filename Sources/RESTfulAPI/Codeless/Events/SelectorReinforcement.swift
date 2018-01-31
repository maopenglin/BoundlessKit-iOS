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
        singleParamAction = "singleParamAction",
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
    
    public static func registerVisualizerMethods() {
        for actionID in DopamineVersion.current.visualizerActionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public static func registerMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public static func registerSimpleMethod(classType: AnyClass, selector: Selector, reinforcement: [String: Any]) {
        let numParams = NSStringFromSelector(selector).components(separatedBy: ":").count - 1
        if numParams > 1 {
            DopeLog.error("Cannot register method with 2 or more parameters")
            return
        }
        let newReinforcement = SelectorReinforcement(selectorType: (numParams==1 ? SelectorType.singleParamAction.rawValue : SelectorType.noParamAction.rawValue), target: NSStringFromClass(classType), action: NSStringFromSelector(selector))
        DopamineVersion.current.update(visualizer: [newReinforcement.actionID: ["test":["Hello!"]]])
    }
    
    public static func unregisterMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.unregisterMethod()
        }
    }
    public static func unregisterMethod(classType: AnyClass, selector: Selector) {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.unregisterMethod()
        }
    }
    
    fileprivate static var registeredMethods: [String:[String]] = [:]
    
    fileprivate func registerMethod() {
        DopeLog.debug("Attempting to register :\(self.actionID)...")
        guard DopamineConfiguration.current.integrationMethod == "codeless" else {
            DopeLog.debug("Codeless integration mode disabled")
            return
        }
        
        var targetsRegisteredMethods = SelectorReinforcement.registeredMethods[target] ?? []
        guard targetsRegisteredMethods.index(of: target) == nil else {
            DopeLog.debug("Reinforcement for selectorType-target:\(selectorType)-\(target) method:\(action) already registered.")
            return
        }
        
        guard let originalClass = NSClassFromString(target).self,
            originalClass.isSubclass(of: NSObject.self) else {
            DopeLog.error("Invalid class <\(target)>")
            return
        }
        
        let originalSelector = NSSelectorFromString(action)
        guard class_getInstanceMethod(originalClass, originalSelector) != nil else {
            DopeLog.error("Class <\(originalClass)> has no method <\(originalSelector)>")
            return
        }
        
        if (selectorType == SelectorReinforcement.SelectorType.noParamAction.rawValue) {
            SwizzleHelper.injectSelector(DopamineObject.self, #selector(DopamineObject.methodToReinforce), originalClass.self, originalSelector)
            DopeLog.debug("Swizzled class:\(originalClass) method:\(originalSelector)")
        } else if (selectorType == SelectorReinforcement.SelectorType.singleParamAction.rawValue) {
            SwizzleHelper.injectSelector(DopamineObject.self, #selector(DopamineObject.methodWithSenderToReinforce(_:)), originalClass.self, originalSelector)
            DopeLog.debug("Swizzled class:\(originalClass) method:\(originalSelector)")
        } // else is a standard swizzle
        
        
        targetsRegisteredMethods.append(action)
        SelectorReinforcement.registeredMethods[target] = targetsRegisteredMethods
        DopeLog.debug("Registered reinforcement class:\(originalClass) method:\(originalSelector)")
    }
    
    fileprivate func unregisterMethod() {
        DopeLog.debug("Attempting to unregister :\(self.actionID)...")
        guard DopamineConfiguration.current.integrationMethod == "codeless" else {
            DopeLog.debug("Codeless integration mode disabled")
            return
        }
        
        guard var targetsRegisteredMethods = SelectorReinforcement.registeredMethods[target],
            let actionIndex = targetsRegisteredMethods.index(of: action) else {
                DopeLog.debug("Reinforcement for selectorType-target:\(selectorType)-\(target) method:\(action) not registered.")
                return
        }
        
        guard let originalClass = NSClassFromString(target).self,
            originalClass.isSubclass(of: NSObject.self) else {
            DopeLog.error("Invalid class <\(target)>")
            return
        }
        
        let originalSelector = NSSelectorFromString(action)
        guard class_getInstanceMethod(originalClass, originalSelector) != nil else {
            DopeLog.error("Class <\(originalClass)> has no method <\(originalSelector)>")
            return
        }
        
        if (selectorType == SelectorReinforcement.SelectorType.noParamAction.rawValue) {
            SwizzleHelper.injectSelector(DopamineObject.self, #selector(DopamineObject.methodToReinforce), originalClass.self, originalSelector)
            DopeLog.debug("Unswizzled class:\(originalClass) method:\(originalSelector)")
        } else if (selectorType == SelectorReinforcement.SelectorType.singleParamAction.rawValue) {
            SwizzleHelper.injectSelector(DopamineObject.self, #selector(DopamineObject.methodWithSenderToReinforce(_:)), originalClass.self, originalSelector)
            DopeLog.debug("Unswizzled class:\(originalClass) method:\(originalSelector)")
        } // else is a standard swizzle
        
        targetsRegisteredMethods.remove(at: actionIndex)
        SelectorReinforcement.registeredMethods[target] = targetsRegisteredMethods
        DopeLog.debug("Unregistered reinforcement class:\(originalClass) method:\(originalSelector)")
    }
    
}

extension SelectorReinforcement {
    
    @objc
    public static func attemptReinforcement(target: NSObject, action: Selector) {
        SelectorReinforcement(selectorType: SelectorType.noParamAction, targetName: NSStringFromClass(type(of: target)), actionName: NSStringFromSelector(action))?.attemptReinforcement(targetInstance: target)
    }
    
    @objc
    public static func attemptReinforcement(sender: AnyObject, target: NSObject, action: Selector) {
        SelectorReinforcement(selectorType: SelectorType.singleParamAction, targetName: NSStringFromClass(type(of: target)), actionName: NSStringFromSelector(action))?.attemptReinforcement(targetInstance: target)
    }
    
    func attemptReinforcement(targetInstance: NSObject) {
        DopamineVersion.current.codelessReinforcementFor(sender: self.selectorType, target: self.target, selector: self.action)  { reinforcement in
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
            if parts.count > 0 {
                let vcClass = parts[0]
                var parent: NSObject
                if vcClass == "self" {
                    parent = targetInstance
                } else if
                    let keyWindow = UIApplication.shared.keyWindow,
                    let vc = keyWindow.getViewControllersWithClassname(classname: vcClass).first {
                    parent = vc
                } else {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
                
                let childPath = Array(parts[1...parts.count-1])
                for childName in childPath {
                    if parent.responds(to: NSSelectorFromString(childName)),
                        let obj = parent.value(forKey: childName) as? NSObject {
                        parent = obj
                    }
                }
                
                if let view = parent as? UIView {
                    viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
                } else {
                    DopeLog.error("Could not find CustomView <\(viewCustom)>", visual: true)
                    return nil
                }
            
            } else if viewCustom == "self", let view = targetInstance as? UIView {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
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
