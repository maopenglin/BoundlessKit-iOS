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
    case .boot: return "https://api.usedopamine.com/v5/app/boot"
    case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
    case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
    case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
        }
    }
}

internal struct CodelssVisualizerSession {
    var adminName: String
    var connectionUUID: String
    var mappings: [String: [String: Any]]
    
    init(adminName: String, connectionUUID: String, mappings: [String: [String: Any]]) {
        self.adminName = adminName
        self.connectionUUID = connectionUUID
        self.mappings = mappings
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let adminName = unarchiver.decodeObject(forKey: "adminName") as? String else { return nil }
        guard let connectionUUID = unarchiver.decodeObject(forKey: "connectionUUID") as? String else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String: Any]] else { return nil }
        self.init(adminName: adminName, connectionUUID: connectionUUID, mappings: mappings)
    }
    
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(adminName, forKey: "adminName")
        archiver.encode(connectionUUID, forKey: "connectionUUID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
}

internal class CodelessAPIClient : HTTPClient {
    
    var properties: BoundlessProperties {
        didSet {
            BKUserDefaults.standard.set(properties.version.encode(), forKey: "codelessVersion")
        }
    }
    var boundlessConfig: BoundlessConfiguration {
        didSet {
            BKUserDefaults.standard.set(boundlessConfig.encode(), forKey: "codelessConfig")
        }
    }
    var visualizerSession: CodelssVisualizerSession? {
        didSet {
            BKUserDefaults.standard.set(visualizerSession?.encode(), forKey: "codelessSession")
        }
    }
    
    fileprivate lazy var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        return queue
    }()
    
    init(properties: BoundlessProperties,
         boundlessConfig: BoundlessConfiguration,
         visualizerSession: CodelssVisualizerSession?,
         session: URLSessionProtocol = URLSession.shared) {
        self.properties = properties
        self.boundlessConfig = boundlessConfig
        self.visualizerSession = visualizerSession
        super.init(session: session)
    }
    
    func boot(completion: @escaping () -> () = {}) {
        var payload = properties.bootCredentials
        payload["inProduction"] = properties.inProduction
        payload["currentVersion"] = properties.version.versionID ?? "nil"
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
                        if let visualizerMappings = versionDict["visualizerMappings"] as? [String: [String: Any]]
                            {
                            self.visualizerSession?.mappings = visualizerMappings
                        }
                        self.properties.version = version
                    }
                }
            }
            
            completion()
        }.start()
    }
    
    
    internal func promptPairing() {
        guard var payload = properties.apiCredentials else {
            return
        }
        payload["deviceName"] = UIDevice.current.name

        post(url: CodelessAPIEndpoint.identify.url, jsonObject: payload) { response in
            switch response?["status"] as? Int ?? nil {
            case 202?:
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    self.promptPairing()
                }
                break
                
            case 200?:
                guard let adminName = response?["adminName"] as? String,
                    let connectionUUID = response?["connectionUUID"] as? String else {
                        self.visualizerSession = nil
                        return
                }
                
                let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
                pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
                    payload["connectionUUID"] = connectionUUID
                    self.post(url: CodelessAPIEndpoint.accept.url, jsonObject: payload) { response in
                        if response?["status"] as? Int == 200 {
                            self.visualizerSession = CodelssVisualizerSession(adminName: adminName, connectionUUID: connectionUUID, mappings: [:])
                        } else {
                            self.visualizerSession = nil
                        }
                    }.start()
                }))
                pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                    self.visualizerSession = nil
                }))
                UIWindow.presentTopLevelAlert(alertController: pairingAlert)
                
            case 208?:
                if let connectionUUID = response?["connectionUUID"] as? String {
                    self.visualizerSession = CodelssVisualizerSession(adminName: "reconnected", connectionUUID: connectionUUID, mappings: [:])
                } else {
                    self.visualizerSession = nil
                }
                
            default:
                self.visualizerSession = nil
                break
            }
        }.start()
    }
    
    
}

