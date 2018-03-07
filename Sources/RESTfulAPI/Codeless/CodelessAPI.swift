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
            case .boot: return .boot
            case .identify: return .identify
            case .accept: return .accept
            case .submit: return .submit
            }
        }
    }
    
    static var logCalls = false
    
    internal static let shared = CodelessAPI()
    
    private override init() {
        super.init()
    }
    
    internal static func boot(completion: @escaping () -> () = {}) {
        guard let dopaProps = DopamineProperties.current else { return }
        
        var payload = dopaProps.apiCredentials
        payload["inProduction"] = dopaProps.inProduction
        payload["currentVersion"] = DopamineVersion.current.versionID ?? "nil"
        payload["currentConfig"] = DopamineConfiguration.current.configID ?? "nil"
        payload["initialBoot"] = (DopamineDefaults.current.initialBootDate == nil)
        shared.send(call: .boot, with: payload){ response in
            if let status = response["status"] as? Int {
                if status == 205 {
                    if let versionDict = response["version"] as? [String: Any],
                        let version = DopamineVersion.convert(from: versionDict) {
                        DopamineProperties.current?.version = version
                    }
                    if let configDict = response["config"] as? [String: Any],
                        let config = DopamineConfiguration.convert(from: configDict) {
                        DopamineProperties.current?.configuration = config
                    }
                }
            }
            
            completion()
        }
    }
    
    internal static func promptPairing() {
        guard var payload = DopamineProperties.current?.apiCredentials else {
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
                                    CodelessIntegrationController.shared.connectionInfo = (adminName, connectionID)
                                } else {
                                    CodelessIntegrationController.shared.connectionInfo = nil
                                }
                            }
                        }))
                        
                        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                            CodelessIntegrationController.shared.connectionInfo = nil
                        }))
                        
                        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
                    } else {
                        CodelessIntegrationController.shared.connectionInfo = nil
                    }
                    
                case 208:
                    if let connectionID = response["connectionUUID"] as? String {
                        CodelessIntegrationController.shared.connectionInfo = ("reconnected", connectionID)
                    }
                    
                case 204:
//                    CodelessIntegrationController.shared.connectionInfo = nil
                    break
                case 500:
                    CodelessIntegrationController.shared.connectionInfo = nil
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    internal static func submit(payloadModifier: (inout [String: Any]) -> Void) {
        guard var payload = DopamineProperties.current?.apiCredentials else { return }
        payloadModifier(&payload)
        
        shared.send(call: .submit, with: payload){ response in
            if response["status"] as? Int != 200 {
                CodelessIntegrationController.shared.connectionInfo = nil
            } else if let visualizerMappings = response["mappings"] as? [String:Any] {
                DopamineVersion.current.update(visualizer: visualizerMappings)
            } else {
                DopeLog.debug("No visualizer mappings found")
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


