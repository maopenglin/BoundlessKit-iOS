//
//  DopamineSelector.swift
//  DopamineKit
//
//  Created by Akash Desai on 12/12/17.
//

import Foundation

public protocol DopamineSelectorDelegate {
    func willTryReinforce(actionID: String)
    func didReinforce(actionID: String, reinforcementDecision: String)
}

@objc
public class DopamineSelector : NSObject {
    
    enum SelectorType : String {
        case
        sendViewDidAppearToDashboard = "sendViewDidAppearToDashboard",
        sendActionToDashboard = "sendActionToDashboard",
        custom = "customSelector"
        
        init?(for classType: AnyClass, _ selector: Selector) {
            if classType == UIViewController.self && selector == #selector(UIViewController.viewDidAppear(_:)) {
                self = .sendActionToDashboard
            } else if classType == UIApplication.self && selector == #selector(UIApplication.sendAction(_:to:from:for:)) {
                self = .sendActionToDashboard
            } else if DopamineObject.templateAvailable(for: classType, selector) {
                self = .custom
            } else {
                DopeLog.debug("No template support for class <\(classType)> method <\(selector)>")
                return nil
            }
        }
    }
    
    var reinforcedCounterparts: (AnyClass, Selector)? {
//        DopeLog.debug("Getting reinforced method for \(NSStringFromClass(targetClass)) \(NSStringFromSelector(selector))")
        if selectorType == .sendViewDidAppearToDashboard {
            return (DopamineViewController.self, #selector(DopamineViewController.dashboardIntegration_viewDidAppear(_:)))
        } else if selectorType == .sendActionToDashboard {
            return (DopamineApp.self, #selector(DopamineApp.dashboardIntegration_sendAction(_:to:from:for:)))
        } else if let createdSelector = self.reinforcer ?? DopamineSelector.registered[actionID]?.reinforcer ?? DopamineSelector.unregistered[actionID]?.reinforcer {
            return (targetClass, createdSelector)
        } else if let newSelector = DopamineObject.createReinforcedMethod(for: targetClass, selector, selector.withRandomString()) {
            return (targetClass, newSelector)
        } else {
            DopeLog.error("Could not create runtime method for (<\(NSStringFromClass(targetClass))>) copying method (<\(selector)>)")
            return nil
        }
    }
    
    public static var delegate: DopamineSelectorDelegate?
    
    internal static let dashboardIntegratingSelectors = [
        DopamineSelector(selectorType: .sendViewDidAppearToDashboard, targetClass: UIViewController.self, selector: #selector(UIViewController.viewDidAppear(_:))).actionID,
        DopamineSelector(selectorType: .sendActionToDashboard, targetClass: UIApplication.self, selector: #selector(UIApplication.sendAction(_:to:from:for:))).actionID
    ]
    
    
    fileprivate static var registered = [String:DopamineSelector]()
    fileprivate static var unregistered = [String:DopamineSelector]()
    
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
    
    private init(selectorType: SelectorType, targetClass: AnyClass, selector: Selector) {
        self.selectorType = selectorType
        self.targetClass = targetClass
        self.selector = selector
        super.init()
        self.reinforcer = DopamineSelector.registered[actionID]?.reinforcer ?? DopamineSelector.unregistered[actionID]?.reinforcer
    }
    
    
    // MARK: - Convenience initializers
    internal convenience init?(actionID: String) {
        let components:[String] = actionID.components(separatedBy: "-")
        if components.count == 3,
            let selectorType = SelectorType(rawValue: components[0]),
            let targetClass = NSClassFromString(components[1]),
            targetClass.instancesRespond(to: NSSelectorFromString(components[2])) {
            self.init(selectorType: selectorType, targetClass: targetClass, selector: NSSelectorFromString(components[2]))
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
extension DopamineSelector {
    func registerMethod() {
//        DopeLog.debug("Attempting to register <\(self.actionID)>...")
        
        guard DopamineSelector.registered[actionID] == nil else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) already registered.")
            return
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            DopamineSelector.registered[actionID] = self
            self.reinforcer = reinforcedSelector
            DopamineSelector.unregistered.removeValue(forKey: actionID)
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
        
        guard let _ = DopamineSelector.registered[actionID]?.reinforcer else {
            DopeLog.debug("Reinforcement for class:\(NSStringFromClass(targetClass)) method:\(NSStringFromSelector(selector)) not registered.")
            return
        }
        
        if let (reinforcedClass, reinforcedSelector) = reinforcedCounterparts {
            DopamineSelector.registered.removeValue(forKey: actionID)
            self.reinforcer = reinforcedSelector
            DopamineSelector.unregistered[actionID] = self
            SwizzleHelper.injectSelector(reinforcedClass, reinforcedSelector, targetClass, selector)
            DopeLog.debug("Unregistered reinforcer for class \(targetClass) selector \(selector) with reinforced selector \(reinforcedSelector)")
            return
        } else {
            DopeLog.debug("Could not unregister reinforcer for class \(targetClass) selector \(selector)")
            return
        }
    }
    
    public static func registerMethods() {
        let actionIDs: [String]
        switch CodelessIntegrationController.shared.state {
        case .unintegrated:
            actionIDs = []
        case .integrated:
            actionIDs = DopamineVersion.current.actionIDs
        case .integrating:
            actionIDs = DopamineVersion.current.visualizerActionIDs
        }
        DopeLog.print("Registering \(actionIDs)...")
        let obseleteActions = Set(registered.keys).subtracting(actionIDs)
        for actionID in obseleteActions {
            DopamineSelector(actionID: actionID)?.unregisterMethod()
        }
        for actionID in actionIDs {
            DopamineSelector(actionID: actionID)?.registerMethod()
        }
    }
    
    public static func unregisterMethods() {
        for (_, selectorReinforcement) in registered {
            selectorReinforcement.unregisterMethod()
        }
    }
}

extension DopamineSelector {
    
    @objc
    public static func attemptReinforcement(senderInstance: AnyObject?, targetInstance: NSObject, action: Selector) {
        if let selectorReinforcement = DopamineSelector(target: targetInstance, selector: action) {
            DopamineSelector.delegate?.willTryReinforce(actionID: selectorReinforcement.actionID)
            DopamineKit.reinforce(selectorReinforcement.actionID) { reinforcementDecision in
                CodelessReinforcement.show(actionID: selectorReinforcement.actionID, reinforcementDecision: reinforcementDecision, senderInstance: senderInstance, targetInstance: targetInstance) {
                    DopamineSelector.delegate?.didReinforce(actionID: selectorReinforcement.actionID, reinforcementDecision: reinforcementDecision)
                }
            }
        } else {
            DopeLog.error("No support for class <\(type(of: targetInstance))> method <\(action)>")
        }
    }
    
    @objc
    public static func attemptIntegration(senderInstance: AnyObject?, targetInstance: AnyObject, action: Selector) {
        guard let targetInstance = targetInstance as? NSObject,
            let selectorReinforcement = DopamineSelector(target: targetInstance, selector: action) else {
                return
        }
        CodelessIntegrationController.shared.submitToDashboard(selectorReinforcement: selectorReinforcement, senderInstance: senderInstance)
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
    
}
