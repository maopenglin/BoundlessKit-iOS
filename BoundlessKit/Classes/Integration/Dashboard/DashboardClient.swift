//
//  DashboardClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

class DashboardClient : NSObject {
    
    var apiClient: CodelessAPIClient
    var dashboardSession: CodelessDashboardSession?
    let database = BKUserDefaults.standard
    
    var codelessReinforcers = [String: CodelessReinforcer]()
    
    override init() {
        let boundlessProperties: BoundlessProperties
        let boundlessVersion: BoundlessVersion
        let boundlessConfig: BoundlessConfiguration
        var visualizerConnection: CodelessDashboardSession?
        
        if let versionData = database.object(forKey: "codelessversion") as? Data,
            let version = BoundlessVersion(data: versionData) {
            BoundlessKit.standard.apiClient.properties.versionID = version.versionID
            boundlessVersion = version
        } else {
            let versionID = BoundlessKit.standard.apiClient.properties.versionID
            boundlessVersion = BoundlessVersion(versionID)
        }
        if let configData = database.object(forKey: "codelessconfig") as? Data,
            let config = BoundlessConfiguration.init(data: configData) {
            boundlessConfig = config
        } else {
            boundlessConfig = BoundlessConfiguration()
        }
        if let savedConnection: CodelessDashboardSession = database.unarchive("visualizerconnection") {
            visualizerConnection = savedConnection
        }
        boundlessProperties = BoundlessKit.standard.apiClient.properties
        
        self.apiClient = CodelessAPIClient.init(properties: boundlessProperties,
                                                boundlessVersion: boundlessVersion,
                                                boundlessConfig: boundlessConfig,
                                                visualizerConnection: visualizerConnection)
        self.dashboardSession = visualizerConnection
        super.init()
        
        loadVersion()
        apiClient.boot {
            
        }
    }
    
    func loadVersion() {
        for (actionID, value) in apiClient.boundlessVersion.mappings {
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

