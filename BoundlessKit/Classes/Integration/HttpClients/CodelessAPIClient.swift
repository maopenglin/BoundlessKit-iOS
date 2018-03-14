//
//  CodelessAPIClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/14/18.
//

import Foundation

internal enum CodelessAPIEndpoint {
    case boot, identify, accept, submit
    
    var url: URL! { return URL(string: path)! }
    
    var path:String{ switch self{
    case .boot: return "https://dashboard-api.usedopamine.com/v5/app/boot"
    case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
    case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
    case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
        }
    }
}

internal class CodelessAPIClient : HTTPClient {
    
    var properties: BoundlessProperties
    var boundlessVersion: BoundlessVersion
    var boundlessConfig: BoundlessConfiguration
    
    var visualizerConnection: CodelessDashboardSession?
    
    init(properties: BoundlessProperties,
         boundlessVersion: BoundlessVersion,
         boundlessConfig: BoundlessConfiguration,
         visualizerConnection: CodelessDashboardSession? = nil,
         session: URLSessionProtocol = URLSession.shared) {
        self.properties = properties
        self.boundlessVersion = boundlessVersion
        self.boundlessConfig = boundlessConfig
        self.visualizerConnection = visualizerConnection
        super.init(session: session)
    }
    
    func boot(completion: @escaping () -> () = {}) {
        properties.versionID = boundlessVersion.versionID
        guard var payload = properties.apiCredentials else {
            completion()
            return
        }
        payload["inProduction"] = properties.inProduction
        payload["currentVersion"] = boundlessVersion.versionID ?? "nil"
        payload["currentConfig"] = boundlessConfig.configID ?? "nil"
        payload["initialBoot"] = (BKUserDefaults.standard.initialBootDate == nil)
        post(url: CodelessAPIEndpoint.boot.url, jsonObject: payload) { response in
            if let status = response?["status"] as? Int {
                if status == 205 {
                    if let configDict = response?["config"] as? [String: Any],
                        let config = BoundlessConfiguration.convert(from: configDict) {
                        self.boundlessConfig = config
                    }
                    if let versionDict = response?["version"] as? [String: Any],
                        let version = BoundlessVersion.convert(from: versionDict) {
                        if let visualizerConnection = self.visualizerConnection,
                        let visualizerMappings = versionDict["visualizerMappings"] as? [String: [String: Any]]
                            {
                            visualizerConnection.visualizerMappings = visualizerMappings
                        }
                        self.boundlessVersion = version
                    }
                }
            }
            
            completion()
        }.start()
    }
    
    
//    internal func promptPairing() {
//        guard var payload = properties.apiCredentials else {
//            return
//        }
//        
//        payload["deviceName"] = UIDevice.current.name
//        
//        shared.send(call: .identify, with: payload){ response in
//            if let status = response["status"] as? Int {
//                switch status {
//                case 202:
//                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//                        promptPairing()
//                    }
//                    break
//                    
//                case 200:
//                    if let adminName = response["adminName"] as? String,
//                        let connectionID = response["connectionUUID"] as? String {
//                        
//                        let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
//                        
//                        pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
//                            guard var payload = DopamineProperties.current?.apiCredentials else { return }
//                            payload["deviceName"] = UIDevice.current.name
//                            payload["connectionUUID"] = connectionID
//                            shared.send(call: .accept, with: payload) {response in
//                                if response["status"] as? Int == 200 {
//                                    CodelessIntegrationController.shared.connectionInfo = (adminName, connectionID)
//                                } else {
//                                    CodelessIntegrationController.shared.connectionInfo = nil
//                                }
//                            }
//                        }))
//                        
//                        pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
//                            CodelessIntegrationController.shared.connectionInfo = nil
//                        }))
//                        
//                        UIWindow.presentTopLevelAlert(alertController: pairingAlert)
//                    } else {
//                        CodelessIntegrationController.shared.connectionInfo = nil
//                    }
//                    
//                case 208:
//                    if let connectionID = response["connectionUUID"] as? String {
//                        CodelessIntegrationController.shared.connectionInfo = ("reconnected", connectionID)
//                    }
//                    
//                case 204:
//                    //                    CodelessIntegrationController.shared.connectionInfo = nil
//                    break
//                case 500:
//                    CodelessIntegrationController.shared.connectionInfo = nil
//                    break
//                    
//                default:
//                    break
//                }
//            }
//        }
//    }
    
    
}
