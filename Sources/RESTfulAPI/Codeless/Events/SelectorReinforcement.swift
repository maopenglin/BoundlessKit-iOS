//
//  SelectorReinforcement.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation

public protocol SelectorReinforcementDelegate {
    func willTryReinforce(actionID: String)
    func didReinforce(actionID: String, reinforcementDecision: String)
}

@objc
public class SelectorReinforcement : NSObject {
    
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
        
        init?(for classType: AnyClass, _ selector: Selector) {
            switch selector {
            case #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)):
                self = .appLaunch
            case #selector(UIApplicationDelegate.applicationWillTerminate(_:)):
                self = .appTerminate
            case #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)):
                self = .appActive
            case #selector(UIApplicationDelegate.applicationWillResignActive(_:)):
                self = .appInactive
            case #selector(UIViewController.viewDidAppear(_:)):
                self = .viewControllerDidAppear
            case #selector(UIViewController.viewDidDisappear(_:)):
                self = .viewControllerDidDisappear
            case #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)):
                self = .collectionDidSelect
            default:
                if DopamineObject.templateAvailable(for: classType, selector) {
                    self = .custom
                } else {
//                    DopeLog.error("No template support for class <\(classType)> method <\(selector)>")
                    return nil
                }
            }
        }
    }
    
    public static var delegate: SelectorReinforcementDelegate?
    
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
    
    
    // MARK: - Convenience initializers
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
    
    public convenience init?(targetClass: AnyClass, selector: Selector) {
        if let selectorType = SelectorType(for: targetClass, selector) {
            self.init(selectorType: selectorType, targetClass: targetClass, selector: selector)
        } else {
            return nil
        }
    }

    public convenience init?(target: NSObject, selector: Selector) {
        self.init(targetClass: type(of: target), selector: selector)
    }
    
    
    // MARK: - Methods
    func registerMethod() {
        DopeLog.debug("Attempting to register <\(self.actionID)>...")
        
        guard SelectorReinforcement.registered[actionID] == nil else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) already registered.")
            return
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            SelectorReinforcement.registered[actionID] = self
            self.reinforcer = reinforcedSelector
            SelectorReinforcement.unregistered.removeValue(forKey: actionID)
            SwizzleHelper.injectSelector(reinforcedClass, reinforcedSelector, targetClass, selector)
            DopeLog.debug("Registered reinforcer for class \(targetClass) selector \(selector) with reinforced selector \(reinforcedSelector)")
            return
        } else {
            DopeLog.debug("Could not register reinforcer for class \(targetClass) selector \(selector)")
            return
        }
    }
    
    func unregisterMethod() {
        DopeLog.debug("Attempting to unregister <\(self.actionID)>...")
        
        guard let _ = SelectorReinforcement.registered[actionID]?.reinforcer else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) not registered.")
            return
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            SelectorReinforcement.registered.removeValue(forKey: actionID)
            self.reinforcer = reinforcedSelector
            SelectorReinforcement.unregistered[actionID] = self
            SwizzleHelper.injectSelector(reinforcedClass, reinforcedSelector, targetClass, selector)
            DopeLog.debug("Unregistered reinforcer for class \(targetClass) selector \(selector) with reinforced selector \(reinforcedSelector)")
            return
        } else {
            DopeLog.debug("Could not unregister reinforcer for class \(targetClass) selector \(selector)")
            return
        }
    }
    
    static func registerMethods(actionIDs: [String] = DopamineVersion.current.actionIDs, unregisterOthers: Bool = true) {
        DopeLog.print("Registering \(actionIDs)...")
        if unregisterOthers {
            let obseleteMethods = Set(registered.keys)
            for actionID in obseleteMethods {
                SelectorReinforcement(actionID: actionID)?.unregisterMethod()
            }
        }
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    static func unregisterMethods() {
        for (_, selectorReinforcement) in registered {
            selectorReinforcement.unregisterMethod()
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
    public static func integrationModeSubmit(targetInstance: AnyObject, action: Selector) {
        integrationModeSubmit(senderInstance: nil, targetInstance: targetInstance, action: action)
    }
    
    @objc
    public static func integrationModeSubmit(senderInstance: AnyObject?, targetInstance: AnyObject, action: Selector) {
        guard let targetInstance = targetInstance as? NSObject,
            let selectorReinforcement = SelectorReinforcement(target: targetInstance, selector: action) else {
                return
        }
        CodelessAPI.submitSelectorReinforcement(selectorReinforcement: selectorReinforcement, senderInstance: senderInstance)
    }
    
    @objc
    public static func attemptReinforcement(senderInstance: AnyObject?, targetInstance: NSObject, action: Selector) {
        if let selectorReinforcement = SelectorReinforcement(target: targetInstance, selector: action) {
            selectorReinforcement.attemptReinforcement(senderInstance: senderInstance, targetInstance: targetInstance)
        } else {
            DopeLog.error("No support for class <\(type(of: targetInstance))> method <\(action)>")
        }
    }
    
    func attemptReinforcement(senderInstance: AnyObject?, targetInstance: NSObject) {
        SelectorReinforcement.delegate?.willTryReinforce(actionID: actionID)
        
        DopamineKit.reinforce(actionID) { reinforcementDecision in
            CodelessReinforcement.show(actionID: self.actionID, reinforcementDecision: reinforcementDecision, senderInstance: senderInstance, targetInstance: targetInstance) {
                SelectorReinforcement.delegate?.didReinforce(actionID: self.actionID, reinforcementDecision: reinforcementDecision)
            }
        }
    }
    
}
