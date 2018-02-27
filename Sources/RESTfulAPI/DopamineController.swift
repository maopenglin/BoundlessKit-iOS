//
//  DopamineController.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

internal class DopamineController : NSObject {
    
    static let shared: DopamineController = DopamineController()
    
    fileprivate override init() {
        super.init()
        if DopamineDefaults.current.wakeOnLoad {
            wake()
        }
    }
    
    func wake() {
        _ = DopeBluetooth.shared
        if DopamineConfiguration.current.integrationMethod == "codeless" {
            registerMethods()
        }
        CodelessAPI.boot {
            CodelessAPI.promptPairing()
        }
    }
    
    func sleep() {
        unregisterMethods()
    }
    
    func integrationModeMethods(_ shouldEnhance: Bool) {
        // Enhance - UIApplicationDelegate
        DopamineAppDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIViewController
        DopamineViewController.enhanceSelectors(shouldEnhance)
        
        // Enhance - UICollectionViewController
        DopamineCollectionViewDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - SKPaymentTransactionObserver
        DopaminePaymentTransactionObserver.enhanceSelectors(shouldEnhance)
//    }
//
//    @objc
//    open func integrationModeMethods(_ shouldEnhance: Bool) {
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
