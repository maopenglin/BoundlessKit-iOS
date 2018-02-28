//
//  CIController.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

internal class CIController : NSObject {
    
    enum State {
        case manual, integrating, integrated
    }
    
    static let shared: CIController = CIController()
    
    var state: State = .manual {
        didSet {
            DopeLog.print("State changed from \(oldValue) to \(state)")
//            if oldValue == state && state != .integrating { return }
            switch state {
            case .manual:
                SelectorReinforcement.unregisterMethods()
                codelessIntegratingMethods(false)
                
            case .integrating:
                SelectorReinforcement.registerMethods()
                codelessIntegratingMethods(true)
                
            case .integrated:
                SelectorReinforcement.registerMethods()
                codelessIntegratingMethods(false)
            }
        }
    }
    
    fileprivate override init() {
        super.init()
    }
    
    func codelessIntegratingMethods(_ shouldEnhance: Bool) {
        // Enhance - UIApplication
        DopamineApp.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIApplicationDelegate
        DopamineAppDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIViewController
        DopamineViewController.enhanceSelectors(shouldEnhance)
        
        // Enhance - UICollectionViewController
        DopamineCollectionViewDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - SKPaymentTransactionObserver
        DopaminePaymentTransactionObserver.enhanceSelectors(shouldEnhance)
        
        // Enhance - UITapGestureRecognizer
        DopamineTapGestureRecognizer.enhanceSelectors(shouldEnhance)
    }
    
}
