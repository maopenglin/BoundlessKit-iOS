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
    var reinforcers = [String: Reinforcer]()
    
    override var version: BoundlessVersion {
        didSet {
            database.set(version.encode(), forKey: "codelessVersion")
            didSetVersion(oldValue: oldValue)
        }
    }
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
    
    convenience init(boundlessClient: BoundlessAPIClient) {
        self.init(credentials: boundlessClient.credentials, version: boundlessClient.version, database: boundlessClient.database)
    }
    
    override init(credentials: BoundlessCredentials, version: BoundlessVersion, database: BKUserDefaults, session: URLSessionProtocol = URLSession.shared) {
        var codelessVersion = version
        if let versionData = database.object(forKey: "codelessVersion") as? Data,
            let version = BoundlessVersion(data: versionData) {
            codelessVersion = version
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
        
        super.init(credentials: credentials, version: codelessVersion, database: database, session: session)
        
        didSetVersion(oldValue: nil)
        didSetConfiguration(oldValue: nil)
        didSetVisualizerSession(oldValue: nil)
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
        let initialBoot = (database.initialBootDate == nil)
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
            if let status = response?["status"] as? Int {
                if status == 205 {
                    if let configDict = response?["config"] as? [String: Any],
                        let config = BoundlessConfiguration.convert(from: configDict) {
                        self.boundlessConfig = config
                    }
                    if let versionDict = response?["version"] as? [String: Any],
                        let version = BoundlessVersion.convert(from: versionDict) {
                        self.version = version
                    }
                }
            }
            self.syncIfNeeded()
            completion()
        }.start()
    }
    
    func promptPairing() { _promptPairing() }
    
    fileprivate let serialQueue = DispatchQueue(label: "CodelessAPIClientSerial")
    fileprivate let concurrentQueue = DispatchQueue(label: "CodelessAPIClientConcurrent", attributes: .concurrent)
}

//// Adhering to BoundlessConfiguration
//
//
fileprivate extension CodelessAPIClient {
    func didSetVersion(oldValue: BoundlessVersion?) {
        if oldValue?.name != version.name {
            mountVersion()
        }
    }
    
    func mountVersion() {
        serialQueue.async {
            var mappings = self.version.mappings
            if let visualizer = self.visualizerSession {
                Reinforcer.scheduleSetting = .random
                for (actionID, value) in visualizer.mappings {
                    mappings[actionID] = value
                }
            } else {
                Reinforcer.scheduleSetting = .reinforcement
                self.refreshContainer.synchronize(with: self)
            }
            
            for (actionID, value) in mappings {
                var reinforcer: Reinforcer
                if let r = self.reinforcers[actionID] {
                    reinforcer = r
                    reinforcer.reinforcementIDs = []
                } else {
                    reinforcer = Reinforcer(forActionID: actionID)
                    self.reinforcers[actionID] = reinforcer
                }
                
                if let manual = value["manual"] as? [String: Any],
                    let reinforcements = manual["reinforcements"] as? [String],
                    !reinforcements.isEmpty {
//                    BKLog.debug("Manual reinforcement found for actionID <\(actionID)>")
                    reinforcer.reinforcementIDs.append(contentsOf: reinforcements)
                }
                
                if let codeless = value["codeless"] as? [String: Any],
                    let reinforcements = codeless["reinforcements"] as? [[String: Any]],
                    !reinforcements.isEmpty {
//                    BKLog.debug("Codeless reinforcement found for actionID <\(actionID)>")
                    let codelessReinforcer: CodelessReinforcer = reinforcer as? CodelessReinforcer ?? {
                        let codelessReinforcer = CodelessReinforcer(copy: reinforcer)
                        switch actionID {
                        case CodelessReinforcer.UIApplicationDidLaunch:
                            NotificationCenter.default.addObserver(codelessReinforcer, selector: #selector(codelessReinforcer.receive(notification:)), name: Notification.Name.UIApplicationDidFinishLaunching, object: nil)
                            
                        case CodelessReinforcer.UIApplicationDidBecomeActive:
                            NotificationCenter.default.addObserver(codelessReinforcer, selector: #selector(codelessReinforcer.receive(notification:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
                            
                        default:
                            InstanceSelectorNotificationCenter.default.addObserver(codelessReinforcer, selector: #selector(codelessReinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                        }
                        reinforcer = codelessReinforcer
                        self.reinforcers[actionID] = codelessReinforcer
                        return codelessReinforcer
                    }()
                    for reinforcementDict in reinforcements {
                        if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                            codelessReinforcer.codelessReinforcements[codelessReinforcement.primitive] = codelessReinforcement
                        }
                    }
                }
            }
            
            for (actionID, value) in self.reinforcers.filter({mappings[$0.key] == nil}) {
                InstanceSelectorNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
                self.reinforcers.removeValue(forKey: actionID)
            }
        }
    }
}

fileprivate extension CodelessAPIClient {
    func didSetConfiguration(oldValue: BoundlessConfiguration?) {
        let newValue = boundlessConfig
        self.refreshContainer.enabled = newValue.reinforcementEnabled
        self.trackBatch.enabled = newValue.trackingEnabled
        self.reportBatch.desiredMaxCountUntilSync = newValue.reportBatchSize
        self.trackBatch.desiredMaxCountUntilSync = newValue.trackBatchSize
        
        BoundlessContext.locationEnabled = newValue.locationObservations
        BKLogPreferences.printEnabled = newValue.consoleLoggingEnabled
        
        if credentials.identity.source.rawValue != newValue.identityType {
            switch  BoundlessUserIdentity.Source(rawValue: newValue.identityType) {
            case .idfv?:
                credentials.identity.source = .idfv
            case .idfa?:
                credentials.identity.source = .idfa
            case .custom?:
                credentials.identity.source = .custom
            default:
                credentials.identity.source = .idfv
            }
        }
        
        if (oldValue?.applicationState != newValue.applicationState) {
            if (newValue.applicationState) {
                NotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationState(_:)), names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            }
        }
        
        if (oldValue?.applicationViews != newValue.applicationViews) {
            if (newValue.applicationViews) {
                InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationViews(_:)), names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
            } else {
                InstanceSelectorNotificationCenter.default.removeObserver(self, names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
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
        
        trackBatch.store(BKAction(actionID, metadata))
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
            
            trackBatch.store(BKAction(actionID, metadata))
        }
    }
}

//// Dashboard Visualizer Connection
//
//
fileprivate extension CodelessAPIClient {
    func didSetVisualizerSession(oldValue: CodelessVisualizerSession?) {
        serialQueue.async {
            if oldValue == nil && self.visualizerSession != nil {
                InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.doNothing(notification:)), names: .visualizerNotifications, object: nil)
                // listen for all notifications sent
                InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(CodelessAPIClient.submitToDashboard(notification:)), name: nil, object: nil)
            } else if oldValue != nil && self.visualizerSession == nil {
                InstanceSelectorNotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    func _promptPairing() {
        var payload = credentials.json
        payload["deviceName"] = UIDevice.current.name
        
        post(url: CodelessAPIEndpoint.identify.url, jsonObject: payload) { response in
            guard let response = response else { return }
            
            switch response["status"] as? Int {
            case 202?:
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    self._promptPairing()
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
                self.submitToDashboard(actionID: CodelessReinforcer.UIApplicationDidBecomeActive)
                self.submitToDashboard(actionID: CodelessReinforcer.UIApplicationDidLaunch)
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
        guard let connectionUUID = dict["connectionUUID"] as? String else { BKLog.print(error: "Bad parameter"); return nil }
        guard let mappings = dict["mappings"] as? [String: [String: Any]] else { BKLog.print(error: "Bad parameter"); return nil }
        
        return CodelessVisualizerSession(connectionUUID: connectionUUID, mappings: mappings)
    }
}
