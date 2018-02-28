//
//  CodelessIntegrationController.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

internal class CodelessIntegrationController : NSObject {
    
    enum State : String {
        case manual, integrating, integrated
    }
    
    static let shared: CodelessIntegrationController = {
        let _shared = CodelessIntegrationController()
        if let savedStateString = DopamineDefaults.current.codelessIntegrationSavedState,
            let savedState = State(rawValue: savedStateString) {
            _shared.state = savedState
        } else if DopamineConfiguration.current.integrationMethod == "codeless" {
            _shared.state = .integrated
        } else {
            _shared.state = .manual
        }
        CodelessAPI.boot() {
            if !DopamineProperties.productionMode && _shared.state != .manual {
                CodelessAPI.promptPairing()
            }
        }
        return _shared
    }()
    
    fileprivate override init() {
        super.init()
    }
    
    internal var connectionInfo: (String, String)? {
        didSet {
            DopeLog.debug("🔍 \(connectionInfo != nil ? "C" : "Disc")onnected to visualizer")
            if let _ = connectionInfo {
                state = .integrating
                if submitQueue.isSuspended { submitQueue.isSuspended = false }
            } else {
                state = DopamineConfiguration.current.integrationMethod == "codeless" ? .integrated : .manual
                submitQueue.cancelAllOperations()
                submitQueue.isSuspended = true
            }
        }
    }
    
    internal fileprivate(set) var state: State = .manual {
        didSet {
            DopeLog.print("State changed from \(oldValue) to \(state)")
            switch state {
            case .manual:
                if oldValue != .manual {
                    SelectorReinforcement.unregisterMethods()
                    codelessIntegratingMethods(false)
                }
                
            case .integrating:
                SelectorReinforcement.registerMethods(actionIDs: DopamineVersion.current.visualizerActionIDs, unregisterOthers: true)
                codelessIntegratingMethods(true)
                
            case .integrated:
                SelectorReinforcement.registerMethods(actionIDs: DopamineVersion.current.actionIDs, unregisterOthers: true)
                codelessIntegratingMethods(false)
            }
            DopamineDefaults.current.codelessIntegrationSavedState = state.rawValue
        }
    }
    
    fileprivate var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    func submitSelectorReinforcement(selectorReinforcement: SelectorReinforcement, senderInstance: AnyObject?) {
        guard let connectionID = self.connectionInfo?.1 else { return }
        submitQueue.addOperation {
            CodelessAPI.submit { payload in
                payload["connectionUUID"] = connectionID
                payload["sender"] = selectorReinforcement.selectorType.rawValue
                payload["target"] = NSStringFromClass(selectorReinforcement.targetClass)
                payload["selector"] = NSStringFromSelector(selectorReinforcement.selector)
                payload["actionID"] = selectorReinforcement.actionID
                if let view = senderInstance as? UIView,
                    let imageString = view.snapshotImage()?.base64EncodedPNGString() {
                    payload["senderImage"] = imageString
                } else if let barItem = senderInstance as? UIBarItem,
                    let image = barItem.image,
                    let imageString = image.base64EncodedPNGString() {
                    payload["senderImage"] = imageString
                } else if let senderInstance = senderInstance as? NSObject,
                    senderInstance.responds(to: NSSelectorFromString("view")),
                    let senderView = senderInstance.value(forKey: "view") as? UIView,
                    let imageString = senderView.snapshotImage()?.base64EncodedPNGString() {
                    payload["senderImage"] = imageString
                } else {
                    payload["senderImage"] = ""
                }
            }
        }
    }
}

extension CodelessIntegrationController {
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
