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
    
    static let shared = CodelessIntegrationController()
    
    fileprivate override init() {
        super.init()
    }
    
    internal fileprivate(set) var state: State = .unintegrated {
        didSet {
            DopeLog.debug("State changed from \(oldValue) to \(state)")
            DopamineSelector.registerMethods()
            DopamineDefaults.current.codelessIntegrationSavedState = state.rawValue
        }
    }
    
    internal func setState(for integrationMethodType: DopamineConfiguration.IntegrationMethodType) {
        if integrationMethodType == .codeless {
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
    
    func submitToDashboard(selectorReinforcement: DopamineSelector, senderInstance: AnyObject?) {
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
