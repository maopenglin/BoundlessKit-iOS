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

internal class CodelessAPIClient : BoundlessAPIClient {
    
    var codelessReinforcers = [String: CodelessReinforcer]()
    
    override var properties: BoundlessProperties {
        didSet {
            database.set(properties.version.encode(), forKey: "codelessVersion")
        }
    }
    var boundlessConfig: BoundlessConfiguration {
        didSet {
            database.set(boundlessConfig.encode(), forKey: "codelessConfig")
        }
    }
    var visualizerSession: CodelessVisualizerSession? {
        didSet {
            database.set(visualizerSession?.encode(), forKey: "codelessSession")
            didSetVisualizerSession(oldValue: oldValue)
        }
    }
    
    convenience init(boundlessClient: BoundlessAPIClient) {
        self.init(properties: boundlessClient.properties, database: boundlessClient.database)
    }
    
    override init(properties: BoundlessProperties, database: BKUserDefaults, session: URLSessionProtocol = URLSession.shared) {
        var codelessProperties = properties
        if let versionData = database.object(forKey: "codelessVersion") as? Data,
            let version = BoundlessVersion(data: versionData) {
            codelessProperties.version = version
        }
        if let configData = database.object(forKey: "codelessConfig") as? Data,
            let config = BoundlessConfiguration.init(data: configData) {
            self.boundlessConfig = config
        } else {
            self.boundlessConfig = BoundlessConfiguration()
        }
        if let sessionData = database.object(forKey: "codelessSession") as? Data,
            let savedSession = CodelessVisualizerSession(data: sessionData) {
            self.visualizerSession = savedSession
        } else {
            self.visualizerSession = nil
        }
        
        super.init(properties: codelessProperties, database: database, session: session)
        
        didSetVisualizerSession(oldValue: nil)
    }
    
    func boot(completion: @escaping () -> () = {}) {
        var payload = properties.bootCredentials
        payload["inProduction"] = properties.inProduction
        payload["currentVersion"] = properties.version.versionID ?? "nil"
        payload["currentConfig"] = boundlessConfig.configID ?? "nil"
        payload["initialBoot"] = (database.initialBootDate == nil)
        post(url: CodelessAPIEndpoint.boot.url, jsonObject: payload) { response in
            if let status = response?["status"] as? Int {
                if status == 205 {
                    if let configDict = response?["config"] as? [String: Any],
                        let config = BoundlessConfiguration.convert(from: configDict) {
                        self.boundlessConfig = config
                    }
                    if let versionDict = response?["version"] as? [String: Any],
                        let version = BoundlessVersion.convert(from: versionDict) {
                        if let visualizerMappings = versionDict["visualizerMappings"] as? [String: [String: Any]] {
                            self.visualizerSession?.mappings = visualizerMappings
                        }
                        self.properties.version = version
                    }
                }
            }
            self.mountVersion()
            self.syncIfNeeded()
            completion()
        }.start()
    }
    
    let mountVersionQueue = DispatchQueue.init(label: "versionQueue")
    func mountVersion() {
        mountVersionQueue.async {
            var mappings = self.properties.version.mappings
            let visualizer = self.visualizerSession
            
            for (key, value) in visualizer?.mappings ?? [:] {
                mappings[key] = value
            }
            CodelessReinforcer.scheduleSetting = (visualizer == nil) ? .reinforcement : .random
//            BKLog.debug("ActionIDs:<\(Array(mappings.keys))>")
        
            for (actionID, value) in mappings {
                if visualizer == nil {
                    self.refreshContainer.commit(actionID: actionID, with: self)
                }
                if let codeless = value["codeless"] as? [String: Any],
                    let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                    let reinforcer: CodelessReinforcer
                    if let r = self.codelessReinforcers[actionID] {
                        reinforcer = r
                        reinforcer.reinforcements.removeAll()
                        BKLog.debug("Modifying codeless reinforcer for actionID <\(actionID)>")
                    } else {
                        reinforcer = CodelessReinforcer(forActionID: actionID)
                        InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name.init(actionID), object: nil)
                        self.codelessReinforcers[actionID] = reinforcer
                        BKLog.debug("Created codeless reinforcer for actionID <\(actionID)>")
                    }
                    for reinforcementDict in reinforcements {
                        if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                            reinforcer.reinforcements[codelessReinforcement.primitive] = codelessReinforcement
                        }
                    }
                }
                else {
                    BKLog.debug("Manual reinforcement selected for actionID <\(actionID)>")
                }
            }
            
            for (actionID, value) in self.codelessReinforcers.filter({mappings[$0.key] == nil}) {
                InstanceSelectorNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
                self.codelessReinforcers.removeValue(forKey: actionID)
//                BKLog.debug("Removed codeless reinforcer for actionID <\(actionID)>")
            }
        }
    }
    
    func promptPairing() {
        guard var payload = properties.apiCredentials else {
            return
        }
        payload["deviceName"] = UIDevice.current.name

        post(url: CodelessAPIEndpoint.identify.url, jsonObject: payload) { response in
            switch response?["status"] as? Int {
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
                            self.visualizerSession = CodelessVisualizerSession(adminName: adminName, connectionUUID: connectionUUID, mappings: [:])
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
                    self.visualizerSession = CodelessVisualizerSession(adminName: "reconnected", connectionUUID: connectionUUID, mappings: [:])
                } else {
                    self.visualizerSession = nil
                }
                
            default:
                self.visualizerSession = nil
                break
            }
        }.start()
    }
    
    
    fileprivate lazy var submitQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func didSetVisualizerSession(oldValue: CodelessVisualizerSession?) {
        submitQueue.addOperation {
            if oldValue == nil && self.visualizerSession != nil {
                BKLog.debug("Visualizer session connected")
                for visualizerNotification in InstanceSelectorNotificationCenter.visualizerNotifications {
                    InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.doNothing(notification:)), name: visualizerNotification, object: nil)
                }
                // listen for all notifications sent
                InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.submitToDashboard(notification:)), name: nil, object: nil)
            } else if oldValue != nil && self.visualizerSession == nil {
                BKLog.debug("Visualizer session disconnected")
                InstanceSelectorNotificationCenter.default.removeObserver(self)
            }
            self.mountVersion()
        }
    }
    
    @objc
    func doNothing(notification: Notification) {
        BKLog.debug("Got notification:\(notification.name.rawValue) ")
    }
    
    @objc
    func submitToDashboard(notification: Notification) {
        self.submitQueue.addOperation {
            guard let session = self.visualizerSession,
                let targetClass = notification.userInfo?["classType"] as? AnyClass,
                let selector = notification.userInfo?["selector"] as? Selector,
                var payload = self.properties.apiCredentials else {
                    BKLog.debug("Failed to send notification <\(notification.name.rawValue)> to dashboard")
                    return
            }
            
            let actionID = notification.name.rawValue
            let sender = notification.userInfo?["sender"] as AnyObject
            payload["connectionUUID"] = session.connectionUUID
            payload["sender"] = (type(of: sender) == NSNull.self) ? "nil" : NSStringFromClass(type(of: sender))
            payload["target"] = NSStringFromClass(targetClass)
            payload["selector"] = NSStringFromSelector(selector)
            payload["actionID"] = actionID
            payload["senderImage"] = ""
            let sema = DispatchSemaphore(value: 0)
            self.post(url: CodelessAPIEndpoint.submit.url, jsonObject: payload) { response in
                defer { sema.signal() }
                guard response?["status"] as? Int == 200 else {
                    self.visualizerSession = nil
                    return
                }
                BKLog.print("Sent to dashboard actionID:<\(actionID)>")
                if let visualizerMappings = response?["mappings"] as? [String: [String: Any]] {
                    self.visualizerSession?.mappings = visualizerMappings
                }
            }.start()
            _ = sema.wait(timeout: .now() + 2)
        }
    }
}

internal struct CodelessVisualizerSession {
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
