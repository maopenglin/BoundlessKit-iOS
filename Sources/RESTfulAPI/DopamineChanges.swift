//
//  DopamineChanges.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

@objc
public protocol DopamineChangesDelegate {
    @objc optional func attemptingReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String)
    @objc optional func reinforcing(actionID: String, with reinforcementDecision: String)
}

open class DopamineChanges : NSObject {
    
    @objc
    open static let shared = DopamineChanges()
    
    open var delegate: DopamineChangesDelegate? {
        didSet {
            print("Did set delegate")
        }
    }
    
    @objc
    open func setStandardTracking() {
        let defaultsKey = "disableStandardEnhancement"
        let disableStandardEnhancement = UserDefaults.dopamine.bool(forKey: defaultsKey)
        DopeLog.debug("Value for \(defaultsKey):\(disableStandardEnhancement)")
        setEnhancement(!disableStandardEnhancement)
    }
    
    @objc
    open func setEnhancement(_ shouldEnhance: Bool) {
        // Enhance - UIApplication
        DopamineApp.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIApplicationDelegate
        DopamineAppDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIViewController
        DopamineViewController.enhanceSelectors(shouldEnhance)
        
        // Enhance - UITapGestureRecognizer
        DopamineTapGestureRecognizer.enhanceSelectors(shouldEnhance)
        
        // Enhance - SKPaymentTransactionObserver
        DopaminePaymentTransactionObserver.enhanceSelectors(shouldEnhance)
        
        // Enhance - UICollectionViewController
        DopamineCollectionViewDelegate.enhanceSelectors(shouldEnhance)
        
        registerMethods()
    }
    
    
    public func registerVisualizerMethods() {
        for actionID in DopamineVersion.current.visualizerActionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public func registerMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public func registerSimpleMethod(classType: AnyClass, selector: Selector, reinforcement: [String: Any]) {
        let numParams = NSStringFromSelector(selector).components(separatedBy: ":").count - 1
        if numParams > 1 {
            DopeLog.error("Cannot register method with 2 or more parameters")
            return
        }
        let newReinforcement = SelectorReinforcement(targetClass: classType, selector: selector)
        DopamineVersion.current.update(visualizer: [newReinforcement.actionID: ["test":["Hello!"]]])
    }
    
    public func unregisterMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.unregisterMethod()
        }
    }
    public func unregisterMethod(classType: AnyClass, selector: Selector) {
        for actionID in DopamineVersion.current.actionIDs {
            SelectorReinforcement(actionID: actionID)?.unregisterMethod()
        }
    }
    
}
