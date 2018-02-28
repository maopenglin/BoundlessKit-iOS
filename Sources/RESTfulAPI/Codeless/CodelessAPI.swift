//
//  CodelessAPI.swift
//  Pods
//
//  Created by Akash Desai on 9/9/17.
//
//

import Foundation

internal class CodelessAPI : NSObject {
    
    enum APICallTypes {
        case identify, accept, submit, boot
        
        var clientType: HTTPClient.CallType {
            switch self {
            case .identify: return .identify
            case .accept: return .accept
            case .submit: return .submit
            case .boot: return .boot
            }
        }
    }
    
    static var logCalls = false
    
    internal static let shared = CodelessAPI()
    
    private static var stashSubmits = true {
        didSet {
            if !stashSubmits {
                submitQueue.cancelAllOperations()
            }
        }
    }
    private static var connectionID: String? {
        didSet {
            if connectionID != oldValue {
                DopeLog.debug("🔍 \(connectionID != nil ? "C" : "Disc")onnected to visualizer")
            }
            
            if connectionID != nil { CodelessIntegrationController.shared.state = .integrating }
            
            if submitQueue.isSuspended {
                submitQueue.isSuspended = false
            }
        }
    }
    
    private override init() {
        super.init()
    }
    
    internal static func boot(completion: @escaping () -> () = {}) {
        guard let dopaProps = DopamineProperties.current else { return }
        guard ProcessInfo.processInfo.environment["debugNoBoot"] != "true" else { return }
        
        if DopamineConfiguration.current.integrationMethod == "codeless" {
            CodelessIntegrationController.shared.state = .integrated
        }
        
        var payload = dopaProps.apiCredentials
        payload["inProduction"] = dopaProps.inProduction
        payload["currentVersion"] = DopamineVersion.current.versionID ?? "nil"
        payload["currentConfig"] = DopamineConfiguration.current.configID ?? "nil"
        payload["initialBoot"] = (DopamineDefaults.current.initialBootDate == nil)
        shared.send(call: .boot, with: payload){ response in
            if let status = response["status"] as? Int {
                if status == 205 {
                    if let configDict = response["config"] as? [String: Any],
                        let config = DopamineConfiguration.convert(from: configDict) {
                        DopamineProperties.current?.configuration = config
                    }
                    if let versionDict = response["version"] as? [String: Any],
                        let version = DopamineVersion.convert(from: versionDict) {
                        DopamineProperties.current?.version = version
                    }
                }
            }
            
            completion()
            if DopamineConfiguration.current.integrationMethod == "codeless" {
                promptPairing()
            }
        }
    }
    
    internal static func promptPairing() {
        guard !DopamineProperties.productionMode && DopamineConfiguration.current.integrationMethod == "codeless",
            var payload = DopamineProperties.current?.apiCredentials
            else {
                stashSubmits = false
                return
        }
        
        payload["deviceName"] = UIDevice.current.name
        
        shared.send(call: .identify, with: payload){ response in
            if let status = response["status"] as? Int {
                switch status {
                case 202:
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        promptPairing()
                    }
                    break
                    
                case 200:
                    if let adminName = response["adminName"] as? String,
                        let connectionID = response["connectionUUID"] as? String {
                        
                        let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
                        
                        pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
                            guard var payload = DopamineProperties.current?.apiCredentials else { return }
                            payload["deviceName"] = UIDevice.current.name
                            payload["connectionUUID"] = connectionID
                            shared.send(call: .accept, with: payload) {response in
                                if response["status"] as? Int == 200 {
                                    CodelessAPI.connectionID = connectionID
                                }
                            }
                        }))
                        
                        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                            
                        }))
                        
                        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
                    }
                    
                case 208:
                    CodelessAPI.connectionID = response["connectionUUID"] as? String
                    
                case 204:
                    CodelessAPI.connectionID = nil
                    stashSubmits = false
                    
                case 500:
                    stashSubmits = false
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    internal static let visualizerDashboardQueue = DispatchQueue(label: "DopamineKit.VisualizerDashboardQueue", qos: .background)
    internal static func submitSelectorReinforcement(selectorReinforcement: SelectorReinforcement, senderInstance: AnyObject?) {
        visualizerDashboardQueue.async {
            submit { payload in
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
    
    fileprivate static var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    fileprivate static func submit(payloadModifier: (inout [String: Any]) -> Void) {
        if stashSubmits {
            guard var payload = DopamineProperties.current?.apiCredentials else { return }
            payloadModifier(&payload)
            
            submitQueue.addOperation {
                if let connectionID = self.connectionID {
                    payload["connectionUUID"] = connectionID
                    
                    submitQueue.isSuspended = true
                    shared.send(call: .submit, with: payload){ response in
                        defer { submitQueue.isSuspended = false }
                        
                        if response["status"] as? Int != 200 {
                            CodelessAPI.connectionID = nil
                        } else if let visualizerMappings = response["mappings"] as? [String:Any] {
                            DopamineVersion.current.update(visualizer: visualizerMappings)
                        } else {
                            DopeLog.debug("No visualizer mappings found")
                        }
                    }
                }
            }
        }
    }
    
    internal lazy var httpClient = HTTPClient()
    
    /// This function sends a request to the CodelessAPI
    ///
    /// - parameters:
    ///     - callType: The type of call to send.
    ///     - payload: A JSON compatible dictionary to send.
    ///     - timeout: A timeout, in seconds, for the request. Defaults to 3 seconds.
    ///     - completion: A closure with a JSON formatted dictionary.
    ///
    private func send(call type: APICallTypes, with payload: [String:Any], completion: @escaping ([String: Any]) -> Void) {
        
        let task = httpClient.post(type: type.clientType, jsonObject: payload) { response in
            if CodelessAPI.logCalls { DopeLog.debug("got response:\(response as AnyObject)") }
            
            completion(response ?? [:])
        }
        
        // send request
        if CodelessAPI.logCalls { DopeLog.debug("with payload: \(payload as AnyObject)") }
        task.start()
    }
}


