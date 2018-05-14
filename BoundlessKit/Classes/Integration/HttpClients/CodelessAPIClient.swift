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
    internal var database: BKUserDefaults = BKUserDefaults.standard
    
    var reinforcers = [String: Reinforcer]()
    
    var boundlessConfig: BoundlessConfiguration {
        didSet {
            database.set(boundlessConfig.encode(), forKey: "codelessConfig")
            didSetConfiguration(oldValue: oldValue)
        }
    }
    fileprivate var visualizerSession: CodelessVisualizerSession? {
        didSet {
            database.set(visualizerSession?.encode(), forKey: "codelessSession")
            didSetVisualizerSession(oldValue: oldValue)
        }
    }
    override var version: BoundlessVersion {
        didSet {
            database.set(version.encode(), forKey: "codelessVersion")
            didSetVersion(oldValue: oldValue)
        }
    }
    
    convenience init(boundlessClient: BoundlessAPIClient) {
        self.init(credentials: boundlessClient.credentials, version: boundlessClient.version)
    }
    
    override init(credentials: BoundlessCredentials, version: BoundlessVersion, session: URLSessionProtocol = URLSession.shared) {
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
        var codelessVersion = version
        if let versionData = database.object(forKey: "codelessVersion") as? Data,
            let version = BoundlessVersion(data: versionData) {
            codelessVersion = version
        }
        
        super.init(credentials: credentials, version: codelessVersion, session: session)
        
        didSetConfiguration(oldValue: nil)
        didSetVisualizerSession(oldValue: nil)
        didSetVersion(oldValue: nil)
    }
    
    override func setCustomUserIdentity(_ id: String?) {
        let oldId = credentials.identity.value
        super.setCustomUserIdentity(id)
        boundlessConfig.identityType = credentials.identity.source.rawValue
        if oldId != credentials.identity.value {
            boot()
        }
    }
    
    func boot(completion: @escaping () -> () = {}) {
        let initialBoot = (version.database.initialBootDate == nil)
        if initialBoot {
            // onInitialBoot erase previous keys
            BoundlessKeychain.buid = nil
        }
        var payload = credentials.json
        payload["inProduction"] = credentials.inProduction
        payload["currentVersion"] = version.name ?? "nil"
        payload["currentConfig"] = boundlessConfig.configID ?? "nil"
        payload["initialBoot"] = initialBoot
        post(url: CodelessAPIEndpoint.boot.url, jsonObject: payload) { response in
            self.checkPairing()
            if let status = response?["status"] as? Int {
                if status == 205 {
                    if let configDict = response?["config"] as? [String: Any],
                        let config = BoundlessConfiguration.convert(from: configDict) {
                        self.boundlessConfig = config
                    }
                    if let versionDict = response?["version"] as? [String: Any] {
                        let updateVersionGroup = DispatchGroup()
                        updateVersionGroup.enter()
                        self.version.reportBatch.synchronize(with: self) { _ in
                            updateVersionGroup.leave()
                        }
                        updateVersionGroup.enter()
                        self.version.trackBatch.synchronize(with: self) { _ in
                            updateVersionGroup.leave()
                        }
                        updateVersionGroup.notify(queue: .global()) {
                            if var newVersion = BoundlessVersion.convert(from: versionDict, database: self.version.database) {
                                newVersion.trackBatch = self.version.trackBatch
                                newVersion.reportBatch = self.version.reportBatch
                                newVersion.refreshContainer = self.version.refreshContainer
                                self.version = newVersion
                                newVersion.refreshContainer.synchronize(with: self)
                            }
                        }
                    }
                } else if status == 200 {
                    self.syncIfNeeded()
                }
            }
            completion()
        }.start()
    }
    
    fileprivate let serialQueue = DispatchQueue(label: "CodelessAPIClientSerial")
    fileprivate let concurrentQueue = DispatchQueue(label: "CodelessAPIClientConcurrent", attributes: .concurrent)
}

//// Adhering to BoundlessConfiguration
//
//
fileprivate extension CodelessAPIClient {
    func didSetConfiguration(oldValue: BoundlessConfiguration?) {
        let newValue = boundlessConfig
        
        self.version.refreshContainer.enabled = newValue.reinforcementEnabled
        self.version.reportBatch.enabled = newValue.reinforcementEnabled
        self.version.trackBatch.enabled = newValue.trackingEnabled
        self.version.reportBatch.desiredMaxCountUntilSync = newValue.reportBatchSize
        self.version.trackBatch.desiredMaxCountUntilSync = newValue.trackBatchSize
        
        BoundlessContext.locationEnabled = newValue.locationObservations
        BoundlessContext.bluetoothEnabled = newValue.bluetoothObservations
        BKLogPreferences.printEnabled = newValue.consoleLoggingEnabled
        
        if credentials.identity.source.rawValue != newValue.identityType {
            switch  BoundlessUserIdentity.Source(rawValue: newValue.identityType) {
            case .idfv?:
                credentials.identity.source = .idfv
            case .idfa?:
                credentials.identity.source = .idfa
            case .custom?:
                credentials.identity.source = .custom
            case nil:
                credentials.identity.source = .idfv
            }
        }
        
        if (oldValue?.applicationState != newValue.applicationState || oldValue?.trackingEnabled != newValue.trackingEnabled) {
            if (newValue.trackingEnabled && newValue.applicationState) {
                NotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationState(_:)), names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            }
        }
        
        if (oldValue?.applicationViews != newValue.applicationViews || oldValue?.trackingEnabled != newValue.trackingEnabled) {
            if (newValue.trackingEnabled && newValue.applicationViews) {
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationViews(_:)), names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
            } else {
                BoundlessNotificationCenter.default.removeObserver(self, names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
            }
        }
        
    }
    
    @objc func trackApplicationState(_ notification: Notification) {
        let tag = "ApplicationState"
        let actionID: String
        var metadata: [String: Any] = ["tag": tag]
        
        switch notification.name {
        case Notification.Name.UIApplicationDidBecomeActive:
            actionID = "UIApplicationDidBecomeActive"
            metadata["time"] = BoundlessTime.start(for: self, tag: tag)
            
        case Notification.Name.UIApplicationWillResignActive:
            actionID = "UIApplicationWillResignActive"
            metadata["time"] = BoundlessTime.end(for: self, tag: tag)
            
        default:
            return
        }
        
        version.trackBatch.store(BKAction(actionID, metadata))
    }
    
    @objc func trackApplicationViews(_ notification: Notification) {
        if let target = notification.userInfo?["target"] as? NSObject,
            let selector = notification.userInfo?["selector"] as? Selector {
            let tag = "ApplicationView"
            let actionID = "\(NSStringFromClass(type(of: target)))-\(NSStringFromSelector(selector))"
            var metadata: [String: Any] = ["tag": tag]
            
            switch selector {
            case #selector(UIViewController.viewDidAppear(_:)):
                metadata["time"] = BoundlessTime.start(for: target)
                
            case #selector(UIViewController.viewDidDisappear(_:)):
                metadata["time"] = BoundlessTime.end(for: target)
                
            default:
                return
            }
            
            version.trackBatch.store(BKAction(actionID, metadata))
        }
    }
}

//// Translate Action-Reward Mappings to Reinforcers
//
//
fileprivate extension CodelessAPIClient {
    func didSetVersion(oldValue: BoundlessVersion?) {
        if oldValue?.name != version.name {
            mountVersion()
            //self.synchronize()
        }
    }
    
    func mountVersion() {
        serialQueue.async {
            var mappings: [String : [String : Any]] = self.boundlessConfig.reinforcementEnabled ? {
                var mappings = self.version.mappings
                if let visualizer = self.visualizerSession {
                    for (actionID, value) in visualizer.mappings {
                        mappings[actionID] = value
                    }
                }
                return mappings
                }() : [:]
            
            for (actionID, value) in mappings {
                var reinforcer: Reinforcer = {
                    self.reinforcers[actionID]?.reinforcementIDs = []
                    return self.reinforcers[actionID]
                    }() ?? {
                        let reinforcer = Reinforcer(forActionID: actionID)
                        self.reinforcers[actionID] = reinforcer
                        return reinforcer
                    }()
                
                if self.boundlessConfig.integrationMethod == "manual" {
                    if let manual = value["manual"] as? [String: Any],
                        let reinforcements = manual["reinforcements"] as? [String],
                        !reinforcements.isEmpty {
                        // BKLog.debug("Manual reinforcement found for actionID <\(actionID)>")
                        reinforcer.reinforcementIDs.append(contentsOf: reinforcements)
                    }
                } else if self.boundlessConfig.integrationMethod == "codeless" {
                    if let codeless = value["codeless"] as? [String: Any],
                        let reinforcements = codeless["reinforcements"] as? [[String: Any]],
                        !reinforcements.isEmpty {
                        let codelessReinforcer: CodelessReinforcer = reinforcer as? CodelessReinforcer ?? {
                            let codelessReinforcer = CodelessReinforcer(copy: reinforcer)
                            BoundlessNotificationCenter.default.addObserver(codelessReinforcer, selector: #selector(codelessReinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                            reinforcer = codelessReinforcer
                            self.reinforcers[actionID] = codelessReinforcer
                            return codelessReinforcer
                            }()
                        // BKLog.debug("Codeless reinforcement found for actionID <\(actionID)>")
                        for reinforcementDict in reinforcements {
                            if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                                codelessReinforcer.codelessReinforcements[codelessReinforcement.primitive] = codelessReinforcement
                            }
                        }
                    }
                }
            }
            
            for (actionID, value) in self.reinforcers.filter({mappings[$0.key] == nil}) {
                if value is CodelessReinforcer {
                    BoundlessNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
                }
                self.reinforcers.removeValue(forKey: actionID)
            }
        }
    }
}

//// Dashboard Visualizer Connection
//
//
extension CodelessAPIClient {
    fileprivate func didSetVisualizerSession(oldValue: CodelessVisualizerSession?) {
        serialQueue.async {
            if oldValue == nil && self.visualizerSession != nil {
                Reinforcer.scheduleSetting = .random
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.doNothing(notification:)), names: .visualizerNotifications, object: nil)
                // listen for all notifications since notification names not known prior
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.submitToDashboard(notification:)), name: nil, object: nil)
            } else if oldValue != nil && self.visualizerSession == nil {
                Reinforcer.scheduleSetting = .reinforcement
                BoundlessNotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    func checkPairing() {
        guard !credentials.inProduction && boundlessConfig.integrationMethod == "codeless" else {
            return
        }
        var payload = credentials.json
        payload["deviceName"] = UIDevice.current.name
        
        post(url: CodelessAPIEndpoint.identify.url, jsonObject: payload) { response in
            guard let response = response else { return }
            
            switch response["status"] as? Int {
            case 202?:
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    self.checkPairing()
                }
                break
                
            case 200?:
                guard let adminName = response["adminName"] as? String,
                    let connectionUUID = response["connectionUUID"] as? String else {
                        self.visualizerSession = nil
                        return
                }
                
                let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
                pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
                    payload["connectionUUID"] = connectionUUID
                    self.post(url: CodelessAPIEndpoint.accept.url, jsonObject: payload) { response in
                        if response?["status"] as? Int == 200 {
                            self.visualizerSession = CodelessVisualizerSession(connectionUUID: connectionUUID, mappings: [:])
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
                self.submitToDashboard(actionID: Notification.Name.CodelessUIApplicationDidBecomeActive)
                self.submitToDashboard(actionID: Notification.Name.CodelessUIApplicationDidFinishLaunching)
                if let _ = response["connectionUUID"] as? String,
                    let reconnectedSession = CodelessVisualizerSession.convert(from: response) {
                    self.visualizerSession = reconnectedSession
                }
//                else { // /identity endpoint gives back wrongly-formatted visualizer mapping
//                    self.visualizerSession = nil
//                }
                
            default:
                self.visualizerSession = nil
            }
        }.start()
    }
    
    @objc
    func submitToDashboard(notification: Notification) {
        serialQueue.async {
            guard let session = self.visualizerSession,
                let targetClass = notification.userInfo?["classType"] as? AnyClass,
                let selector = notification.userInfo?["selector"] as? Selector else {
                    BKLog.debug("Failed to send notification <\(notification.name.rawValue)> to dashboard")
                    return
            }
            let sender = notification.userInfo?["sender"] as AnyObject
            let actionID = notification.name.rawValue
            
            var payload = self.credentials.json
            payload["versionID"] = self.version.name
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
                    DispatchQueue.global().async {
                        self.visualizerSession = nil
                    }
                    return
                }
                BKLog.print("Sent to dashboard actionID:<\(actionID)>")
                if let visualizerMappings = response?["mappings"] as? [String: [String: Any]] {
                    DispatchQueue.global().async {
                        self.visualizerSession?.mappings = visualizerMappings
                        self.mountVersion()
                    }
                }
            }.start()
            _ = sema.wait(timeout: .now() + 2)
        }
    }
    
    @objc
    func doNothing(notification: Notification) {
        BKLog.debug("Got notification:\(notification.name.rawValue) ")
    }
}

extension CodelessAPIClient {
    func submitToDashboard(actionID: String) {
        var components = actionID.components(separatedBy: "-")
        if components.count == 2 {
            let target = components.removeFirst()
            let selector = components.removeFirst()
            var payload = self.credentials.json
            payload["versionID"] = self.version.name
            payload["connectionUUID"] = self.visualizerSession?.connectionUUID
            payload["target"] = target
            payload["selector"] = selector
            payload["actionID"] = actionID
            payload["senderImage"] = ""
            self.post(url: CodelessAPIEndpoint.submit.url, jsonObject: payload) {_ in}.start()
        }
    }
}

fileprivate  struct CodelessVisualizerSession {
    let connectionUUID: String
    var mappings: [String: [String: Any]]
    
    init(connectionUUID: String, mappings: [String: [String: Any]]) {
        self.connectionUUID = connectionUUID
        self.mappings = mappings
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let connectionUUID = unarchiver.decodeObject(forKey: "connectionUUID") as? String else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String: Any]] else { return nil }
        self.init(connectionUUID: connectionUUID, mappings: mappings)
    }
    
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(connectionUUID, forKey: "connectionUUID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
    
    static func convert(from dict: [String: Any]) -> CodelessVisualizerSession? {
        guard let connectionUUID = dict["connectionUUID"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let mappings = dict["mappings"] as? [String: [String: Any]] else { BKLog.debug(error: "Bad parameter"); return nil }
        
        return CodelessVisualizerSession(connectionUUID: connectionUUID, mappings: mappings)
    }
}
