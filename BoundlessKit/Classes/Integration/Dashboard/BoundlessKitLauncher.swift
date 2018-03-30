//
//  BoundlessKitLauncher.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

public class BoundlessKitLauncherObjc : NSObject {
    @objc
    public static var launch: Bool = {
        let launcher = BoundlessKitLauncher()
        BoundlessKit.standard.launcher = launcher
        return true
    }()
}

class BoundlessKitLauncher : NSObject {
    
    var apiClient: CodelessAPIClient
    let database = BKUserDefaults.standard
    
    var codelessReinforcers = [String: CodelessReinforcer]()
    
    override init() {
        let boundlessProperties: BoundlessProperties
        let boundlessConfig: BoundlessConfiguration
        let session: CodelessVisualizerSession?
        
        if let versionData = database.object(forKey: "codelessVersion") as? Data,
            let version = BoundlessVersion(data: versionData) {
            BoundlessKit.standard.apiClient.properties.version = version
        }
        boundlessProperties = BoundlessKit.standard.apiClient.properties
        if let configData = database.object(forKey: "codelessConfig") as? Data,
            let config = BoundlessConfiguration.init(data: configData) {
            boundlessConfig = config
        } else {
            boundlessConfig = BoundlessConfiguration()
        }
        if let sessionData = database.object(forKey: "codelessSession") as? Data,
            let savedSession = CodelessVisualizerSession(data: sessionData) {
            session = savedSession
        } else {
            session = nil
        }
        
        self.apiClient = CodelessAPIClient.init(properties: boundlessProperties,
                                                boundlessConfig: boundlessConfig)
        super.init()
        
        apiClient.visualizerSession = session
        self.didUpdate(session: session)
        apiClient.delegate = self
        
        apiClient.boot {
            BoundlessKit.standard.apiClient.properties = self.apiClient.properties
            self.refreshKit()
            self.apiClient.promptPairing()
        }
        
        refreshKit()
    }
    
    func refreshKit() {
        for (actionID, value) in apiClient.properties.version.mappings {
            BoundlessKit.standard.refreshContainer.commit(actionID: actionID, with: BoundlessKit.standard.apiClient)
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                let reinforcer: CodelessReinforcer
                if let r = codelessReinforcers[actionID] {
                    reinforcer = r
                } else {
                    reinforcer = CodelessReinforcer(forActionID: actionID)
                    InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name.init(actionID), object: nil)
                    codelessReinforcers[actionID] = reinforcer
                }
                for reinforcementDict in reinforcements {
                    if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                        reinforcer.reinforcements[codelessReinforcement.primitive] = codelessReinforcement
                    }
                }
            }
        }
    }
}

extension BoundlessKitLauncher : CodelessApiClientDelegate {
    func didUpdate(session: CodelessVisualizerSession?) {
        var mappings = apiClient.properties.version.mappings
        if let session = session {
            for (key, value) in session.mappings {
                mappings[key] = value
            }
            CodelessReinforcer.showOption = .random
        } else {
            CodelessReinforcer.showOption = .reinforcement
        }
        
        for (actionID, value) in codelessReinforcers.filter({mappings[$0.key] == nil}) {
            InstanceSelectorNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
            codelessReinforcers.removeValue(forKey: actionID)
        }
        for (actionID, value) in mappings {
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                let reinforcer: CodelessReinforcer
                if let r = codelessReinforcers[actionID] {
                    reinforcer = r
                } else {
                    reinforcer = CodelessReinforcer(forActionID: actionID)
                    InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                    codelessReinforcers[actionID] = reinforcer
                }
                reinforcer.reinforcements.removeAll()
                for reinforcementDict in reinforcements {
                    if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                        reinforcer.reinforcements[codelessReinforcement.primitive] = codelessReinforcement
                    }
                }
            }
        }
    }
}

