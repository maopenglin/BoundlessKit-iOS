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
            default:
                if DopamineObject.templateAvailable(for: classType, selector) {
                    self = .custom
                } else {
                    DopeLog.debug("No template support for class <\(classType)> method <\(selector)>")
                    return nil
                }
            }
        }
    }
    
    var reinforcedCounterparts: (AnyClass, Selector)? {
        switch selectorType {
        case .appLaunch:
            return (DopamineAppDelegate.self, #selector(DopamineAppDelegate.reinforcedAction_application(_:didFinishLaunchingWithOptions:)))
        case .appActive:
            return (DopamineAppDelegate.self, #selector(DopamineAppDelegate.reinforcedAction_applicationDidBecomeActive(_:)))
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
}

// MARK: - Methods
extension SelectorReinforcement {
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
    
    static func registerMethods(actionIDs: [String]) {
        DopeLog.print("Registering \(actionIDs)...")
        let obseleteActions = Set(registered.keys).subtracting(actionIDs)
        for actionID in obseleteActions {
            SelectorReinforcement(actionID: actionID)?.unregisterMethod()
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
}

extension SelectorReinforcement {
    
    @objc
    public static func recordActionFor(senderInstance: AnyObject?, targetInstance: AnyObject, action: Selector) {
        guard let targetInstance = targetInstance as? NSObject,
            let selectorReinforcement = SelectorReinforcement(target: targetInstance, selector: action) else {
                return
        }
        
        switch action {
        case #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)):
            if DopamineConfiguration.current.applicationState {
                DopamineKit.track("ApplicationState",
                                  metaData: ["tag": "didBecomeActive",
                                             "classname": NSStringFromClass(type(of: targetInstance)),
                                             "time": DopeInfo.trackStartTime(for: targetInstance.description)
                    ])
            }
            
        case #selector(UIApplicationDelegate.applicationWillResignActive(_:)):
            if DopamineConfiguration.current.applicationState {
                DopamineKit.track("ApplicationState",
                                  metaData: ["tag": "willResignActive",
                                             "classname": NSStringFromClass(type(of: targetInstance)),
                                             "time": DopeInfo.timeTracked(for: targetInstance.description)
                    ])
            }
            
        case #selector(UIViewController.viewDidAppear(_:)):
            if DopamineConfiguration.current.applicationViews || DopamineConfiguration.current.customViews[NSStringFromClass(type(of: targetInstance))] != nil {
                DopamineKit.track("ApplicationView",
                                  metaData: ["tag": "didAppear",
                                             "classname": NSStringFromClass(type(of: targetInstance)),
                                             "time": DopeInfo.trackStartTime(for: targetInstance.description)
                    ])
            }
            
        case #selector(UIViewController.viewDidDisappear(_:)):
            if DopamineConfiguration.current.applicationViews || DopamineConfiguration.current.customViews[NSStringFromClass(type(of: targetInstance))] != nil {
                DopamineKit.track("ApplicationView",
                                  metaData: ["tag": "didDisappear",
                                             "classname": NSStringFromClass(type(of: targetInstance)),
                                             "time": DopeInfo.timeTracked(for: targetInstance.description)
                    ])
            }
            
        default:
            break
        }
        
        CodelessIntegrationController.shared.ifIntegratingSubmit(selectorReinforcement: selectorReinforcement, senderInstance: senderInstance)
    }
    
    // note: don't call this from the main thread if the object is also on the main thread
    func toJSONType(senderInstance: AnyObject?) -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["sender"] = selectorType.rawValue
        jsonObject["target"] = NSStringFromClass(targetClass)
        jsonObject["selector"] = NSStringFromSelector(selector)
        jsonObject["actionID"] = actionID
        if let view = senderInstance as? UIView,
            let imageString = view.snapshotImage()?.base64EncodedPNGString() {
            jsonObject["senderImage"] = imageString
        } else if let barItem = senderInstance as? UIBarItem,
            let image = barItem.image,
            let imageString = image.base64EncodedPNGString() {
            jsonObject["senderImage"] = imageString
        } else if let senderInstance = senderInstance as? NSObject,
            senderInstance.responds(to: NSSelectorFromString("view")),
            let senderView = senderInstance.value(forKey: "view") as? UIView,
            let imageString = senderView.snapshotImage()?.base64EncodedPNGString() {
            jsonObject["senderImage"] = imageString
        } else {
            jsonObject["senderImage"] = ""
        }
        
        return jsonObject
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
