//
//  CodelessIntegrationController.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

internal class CodelessIntegrationController : NSObject {
    
    enum State : String {
        case unintegrated, integrating, integrated
    }
    
    static let shared: CodelessIntegrationController = {
        let _shared = CodelessIntegrationController()
        _shared.setStateForIntegrationMethodType()
        CodelessAPI.boot() {
            if !DopamineProperties.productionMode && _shared.state != .unintegrated {
                CodelessAPI.promptPairing()
            }
        }
        return _shared
    }()
    
    fileprivate override init() {
        super.init()
    }
    
    internal fileprivate(set) var state: State = .unintegrated {
        didSet {
            DopeLog.print("State changed from \(oldValue) to \(state)")
            switch state {
            case .unintegrated:
                if oldValue != .unintegrated {
                    SelectorReinforcement.unregisterMethods()
                    codelessIntegratingMethods(false)
                }
                
            case .integrating:
                if oldValue != .integrating {
                    codelessIntegratingMethods(true)
                }
                SelectorReinforcement.registerMethods(actionIDs: DopamineVersion.current.visualizerActionIDs)
                
            case .integrated:
                if oldValue == .integrating {
                    codelessIntegratingMethods(false)
                }
                SelectorReinforcement.registerMethods(actionIDs: DopamineVersion.current.actionIDs)
            }
            DopamineDefaults.current.codelessIntegrationSavedState = state.rawValue
        }
    }
    
    internal func setStateForIntegrationMethodType() {
        if DopamineConfiguration.current.integrationMethodType == .codeless {
            if let savedStateString = DopamineDefaults.current.codelessIntegrationSavedState,
                State(rawValue: savedStateString) == .integrating {
                state = .integrating
            } else {
                state = .integrated
            }
        } else {
            state = .unintegrated
        }
    }
    
    internal var connectionInfo: (String, String)? {
        didSet {
            if oldValue?.1 != connectionInfo?.1 { DopeLog.debug("🔍 \(connectionInfo != nil ? "C" : "Disc")onnected to visualizer") }
            
            if let _ = connectionInfo {
                state = .integrating
                submitQueue.isSuspended = false
            } else if DopamineConfiguration.current.integrationMethodType == .codeless {
                state = .integrated
                submitQueue.cancelAllOperations()
                submitQueue.isSuspended = false
            } else {
                state = .unintegrated
            }
        }
    }
    
    fileprivate lazy var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    func submitSelectorReinforcement(selectorReinforcement: SelectorReinforcement, senderInstance: AnyObject?) {
        guard state == .integrating else { return }
        
        submitQueue.addOperation {
            guard let connectionID = self.connectionInfo?.1 else { return }
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
        DopeLog.print("Enhancing methods:\(shouldEnhance)")
        // Enhance - UIApplication
        DopamineApp.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIApplicationDelegate
        DopamineAppDelegate.enhanceSelectors(shouldEnhance)
        
        // Enhance - UIViewController
        DopamineViewController.enhanceSelectors(shouldEnhance)
    }
}
