//
//  SelectorReinforcement.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation


@objc
open class SelectorReinforcement : NSObject {
    
    fileprivate static var registered = [String:SelectorReinforcement]()
    fileprivate static var unregistered = [String:SelectorReinforcement]()
    
    let selectorType: SelectorType
    public let targetClass: AnyClass
    public let selector: Selector
    public var reinforcer: Selector?
    public var actionID: String {
        get {
            return [selectorType.rawValue,
                    NSStringFromClass(targetClass),
                    NSStringFromSelector(selector)]
                .joined(separator: "-")
        }
    }
    
    fileprivate init(selectorType: SelectorType, targetClass: AnyClass, selector: Selector) {
        self.selectorType = selectorType
        self.targetClass = targetClass
        self.selector = selector
        super.init()
        self.reinforcer = SelectorReinforcement.registered[actionID]?.reinforcer ?? SelectorReinforcement.unregistered[actionID]?.reinforcer
    }
    
    
    
    public convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        if components.count == 3,
            let selectorType = SelectorType(rawValue: components[0]),
            let targetClass = NSClassFromString(components[1]) {
            let selector = NSSelectorFromString(components[2])
            self.init(selectorType: selectorType, targetClass: targetClass, selector: selector)
        } else {
            return nil
        }
    }
    
    public convenience init(targetClass: AnyClass, selector: Selector) {
        self.init(selectorType: SelectorType(from: selector), targetClass: targetClass, selector: selector)
    }
    
    public convenience init(target: NSObject, selector: Selector) {
        self.init(selectorType: SelectorType(from: selector), targetClass: type(of: target), selector: selector)
    }
    
    
    
    func registerMethod() -> Bool {
        DopeLog.debug("Attempting to register <\(self.actionID)>...")
        guard DopamineConfiguration.current.integrationMethod == "codeless" else {
            DopeLog.debug("Codeless integration mode disabled")
            return false
        }
        
        guard SelectorReinforcement.registered[actionID] == nil else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) already registered.")
            return false
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            SwizzleHelper.injectSelector(reinforcedClass, reinforcedSelector, targetClass, selector)
            self.reinforcer = reinforcedSelector
            SelectorReinforcement.unregistered.removeValue(forKey: actionID)
            SelectorReinforcement.registered[actionID] = self
            DopeLog.debug("Registered reinforcer for class \(targetClass) selector \(selector) with reinforced selector \(reinforcedSelector)")
            return true
        } else {
            DopeLog.debug("Could not register reinforcer for class \(targetClass) selector \(selector)")
            return false
        }
    }
    
    func unregisterMethod() -> Bool {
        DopeLog.debug("Attempting to unregister <\(self.actionID)>...")
        guard DopamineConfiguration.current.integrationMethod == "codeless" else {
            DopeLog.debug("Codeless integration mode disabled")
            return false
        }
        
        guard let _ = SelectorReinforcement.registered[actionID]?.reinforcer else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) not registered.")
            return false
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            SwizzleHelper.injectSelector(reinforcedClass, reinforcedSelector, targetClass, selector)
            self.reinforcer = reinforcedSelector
            SelectorReinforcement.registered.removeValue(forKey: actionID)
            SelectorReinforcement.unregistered[actionID] = self
            DopeLog.debug("Unregistered reinforcer for class \(targetClass) selector \(selector) with reinforced selector \(reinforcedSelector)")
            return true
        } else {
            DopeLog.debug("Could not unregister reinforcer for class \(targetClass) selector \(selector)")
            return false
        }
    }
    
    
    
    enum SelectorType : String {
        case
        appLaunch = "appLaunch",
        appTerminate = "appTerminate",
        appActive = "appActive",
        appInactive = "appInactive",
        viewControllerDidAppear = "viewControllerDidAppear",
        viewControllerDidDisappear = "viewControllerDidDisappear",
        collectionDidSelect = "collectionDidSelect",
        custom = "customSelector"
        
        init(from selector: Selector) {
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
            } else {
                self = .custom
            }
        }
    }
    
    var reinforcedCounterparts: (AnyClass, Selector)? {
        switch selectorType {
        case .appLaunch:
            return (DopamineAppDelegate.self, #selector(DopamineAppDelegate.reinforced_application(_:didFinishLaunchingWithOptions:)))
        case .appActive:
            return (DopamineAppDelegate.self, #selector(DopamineAppDelegate.reinforced_applicationDidBecomeActive(_:)))
        case .viewControllerDidAppear:
            return (DopamineViewController.self, #selector(DopamineViewController.reinforced_viewDidAppear(_:)))
        case .custom:
            print("Getting custom method for \(NSStringFromClass(targetClass)) \(NSStringFromSelector(selector))")
            if let createdSelector = self.reinforcer ?? SelectorReinforcement.registered[actionID]?.reinforcer ?? SelectorReinforcement.unregistered[actionID]?.reinforcer {
                return (targetClass, createdSelector)
            } else if let newSelector = DopamineObject.createReinforcedMethod(for: targetClass, selector, selector.withRandomString()) {
                return (targetClass, newSelector)
            } else {
                DopeLog.error("Could not create runtime method for (<\(NSStringFromClass(targetClass))>) copying method (<\(selector)>)")
                return nil
            }
        default:
            DopeLog.error("Unsupported currently")
            return nil
        }
    }
}

extension SelectorReinforcement {
    
    @objc
    public static func attemptReinforcement(senderInstance: AnyObject?, targetInstance: NSObject, action: Selector) {
        SelectorReinforcement(target: targetInstance, selector: action).attemptReinforcement(senderInstance: senderInstance, targetInstance: targetInstance)
    }
    
    func attemptReinforcement(senderInstance: AnyObject?, targetInstance: NSObject) {
        
        let reinforcements = DopamineVersion.current.codelessReinforcementFor(sender: selectorType.rawValue, target: NSStringFromClass(targetClass), selector: NSStringFromSelector(selector))  { reinforcement in
            guard let delay = reinforcement["Delay"] as? Double else { DopeLog.error("Missing parameter", visual: true); return }
            guard let reinforcementType = reinforcement["primitive"] as? String else { DopeLog.error("Missing parameter", visual: true); return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let viewsAndLocations = self.reinforcementViews(senderInstance: senderInstance, targetInstance: targetInstance, options: reinforcement) {
                    Reinforcement.showReinforcement(on: viewsAndLocations, of: reinforcementType, withParameters: reinforcement)
                }
            }
        }
        DopamineChanges.shared.delegate.attemptedReinforcement?(senderInstance: senderInstance, targetInstance: targetInstance, actionSelector: NSStringFromSelector(selector), reinforcements: reinforcements)
    }
    
    private func reinforcementViews(senderInstance: AnyObject?, targetInstance: NSObject, options: [String: Any]) -> [(UIView, CGPoint)]? {
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
            var parts = viewCustom.components(separatedBy: "-")
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
                
                parts.removeFirst()
                for childName in parts {
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
            
        case "sender":
            if let senderInstance = senderInstance {
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
            } else {
                DopeLog.error("No sender object", visual: true)
                return nil
            }
            
        case "target":
            if let viewController = targetInstance as? UIViewController,
                let view = viewController.view {
                viewsAndLocations = [(view, view.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else if let view = targetInstance as? UIView {
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
            } else if let view = targetInstance as? UIView,
                let superview = view.superview {
                viewsAndLocations = [(superview, superview.pointWithMargins(x: viewMarginX, y: viewMarginY))]
            } else {
                DopeLog.error("Could not find superview", visual: true)
                return nil
            }
            
        default:
            DopeLog.error("Unsupported ViewOption <\(viewOption)> for ApplicationEvent", visual: true)
            return nil
        }
        
        return viewsAndLocations
    }
}
