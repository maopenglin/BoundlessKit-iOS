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
        let session: CodelssVisualizerSession?
        
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
        if let sessionData = database.object(forKey: "codelssSession") as? Data,
            let savedSession = CodelssVisualizerSession(data: sessionData) {
            session = savedSession
        } else {
            session = nil
        }
        
        self.apiClient = CodelessAPIClient.init(properties: boundlessProperties,
                                                boundlessConfig: boundlessConfig,
                                                visualizerSession: session)
        super.init()
        
        loadVersion()
        apiClient.boot {
            
        }
    }
    
    func loadVersion() {
        var mappings = apiClient.properties.version.mappings
        for (actionID, value) in apiClient.visualizerSession?.mappings ?? [:] {
            mappings[actionID] = value
        }
        for (actionID, value) in mappings {
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

