//
//  DopamineChanges.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

@objc
public protocol DopamineChangesDelegate {
    func didAttemptReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String, reinforcements: [String: Any]?)
    func isReinforcing(actionID: String, with reinforcementDecision: String?)
    func didShowReward()
}

public class DopamineChangesDelegateTester : DopamineChangesDelegate {
    public func didAttemptReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String, reinforcements: [String: Any]?) {
        DopeLog.debug("AttemptedReinforcement for selector:\(actionSelector)")
    }
    public func isReinforcing(actionID: String, with reinforcementDecision: String?) {
        DopeLog.debug("Reinforcing actionID:\(actionID) with reinforcementDecision:\(reinforcementDecision)")
    }
    public func didShowReward() {
        DopeLog.debug("Did show reward")
    }
}

open class DopamineChanges : NSObject {
    
    @objc
    open static let shared = DopamineChanges()
    
    open var delegate: DopamineChangesDelegate = DopamineChangesDelegateTester()
    
    @objc
    open func wake() {
        _ = DopeBluetooth.shared
        
        enhanceMethods(DopamineDefaults.enableEnhancement)
        registerMethods()
        if let dopaProps = DopamineProperties.current,
            !dopaProps.inProduction {
            registerVisualizerMethods()
        }
        
    }
    
    @objc
    open func enhanceMethods(_ shouldEnhance: Bool) {
        // Enhance - UIApplicationDelegate
        DopamineAppDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIViewController
        DopamineViewController.enhanceSelectors(shouldEnhance)
        
        // Enhance - UICollectionViewController
        DopamineCollectionViewDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - SKPaymentTransactionObserver
        DopaminePaymentTransactionObserver.enhanceSelectors(shouldEnhance)
    }
    
    @objc
    open func visualizeMethods(_ shouldEnhance: Bool) {
        // Enhance - UIApplication
        DopamineApp.enhanceSelectors(shouldEnhance)
        
        // Enhance - UITapGestureRecognizer
        DopamineTapGestureRecognizer.enhanceSelectors(shouldEnhance)
    }
    
    
    public func registerVisualizerMethods() {
        for actionID in DopamineVersion.current.visualizerActionIDs {
            let _ = SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public func registerMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            let _ = SelectorReinforcement(actionID: actionID)?.registerMethod()
        }
    }
    
    public func registerSimpleMethod(classType: AnyClass, selector: Selector, reinforcement: [String: Any]) -> (Bool) {
        guard DopamineObject.templateAvailable(for: classType, selector) else {
            DopeLog.error("No template support for class <\(classType)> method <\(selector)>")
            return false
        }
        let newReinforcement = SelectorReinforcement(targetClass: classType, selector: selector)
        return newReinforcement.registerMethod()
    }
    
    public func unregisterMethods() {
        for actionID in DopamineVersion.current.actionIDs {
            let _ = SelectorReinforcement(actionID: actionID)?.unregisterMethod()
        }
    }
    
    public func unregisterSimpleMethod(classType: AnyClass, selector: Selector) -> Bool {
        return SelectorReinforcement(targetClass: classType, selector: selector).unregisterMethod()
    }
    
}
