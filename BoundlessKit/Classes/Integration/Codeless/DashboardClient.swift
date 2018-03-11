//
//  DashboardClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

class DashboardClient : NSObject {
    
    var boundlessVersion: BoundlessVersion
    var boundlessConfig: BoundlessConfiguration
    let boundlessClient: BoundlessKitClient
    
    let kit = BoundlessKit()
    
    var codelessReinforcements = [CodelessReinforcement]()
    
    override init() {
        if let versionData = UserDefaults.boundless.object(forKey: "codelessversion") as? Data,
            let version = BoundlessVersion.init(data: versionData) {
            self.boundlessVersion = version
        } else if let properties = BoundlessProperties.fromFile {
            self.boundlessVersion = BoundlessVersion.init(properties.versionID, [String : [String]]())
        } else {
            self.boundlessVersion = BoundlessVersion.init(nil, [String : [String]]())
        }
        
        if let configData = UserDefaults.boundless.object(forKey: "codelessconfig") as? Data,
            let config = BoundlessConfiguration.init(data: configData) {
            self.boundlessConfig = config
        } else {
            self.boundlessConfig = BoundlessConfiguration.init()
        }
        
        self.boundlessClient = BoundlessKitClient.init(properties: BoundlessProperties.fromFile!)
        
        super.init()
        
        loadCodelessReinforcements(mappings: [String : [String : Any]]())
        
        kit.launch(delegate: boundlessClient, dataSource: boundlessClient)
    }
    
    func loadCodelessReinforcements(mappings:[String: [String: Any]]) {
        for (actionID, value) in mappings {
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                
                for reinforcementDict in reinforcements {
                    if let codelessReinforcement = CodelessReinforcement.convert(from: reinforcementDict) {
                        codelessReinforcements.append(codelessReinforcement)
                        InstanceSelectorNotificationCenter.default.addObserver(codelessReinforcement, selector: #selector(codelessReinforcement.receive(notification:)), name: NSNotification.Name.init(actionID), object: nil)
                    }
                }
            }
        }
    }
    
    func loadCartridge() {
        
    }
    
    @objc
    func selectorInstance(notification: Notification) {
//        kit.reinforce(actionID: notification.name.rawValue) { reinforcement in
//            print("Got selector reinforcement:\(reinforcement)")
//        }
    }
    
}

extension DashboardClient : BoundlessKitDelegate, BoundlessKitDataSource {
    
    func kitActions() -> [String] {
        let actionIDs = ["action1"]
        return actionIDs
    }
    
    func kitReinforcements(for actionID: String) -> [String] {
        var cartridge = [String: [BoundlessDecision]]()
        cartridge[actionID] = [BoundlessDecision.init("decision1", actionID)]
        
        return cartridge[actionID]?.map({ (reinforcement) -> String in
            return reinforcement.name
        }) ?? []
    }
    
    func kitPublish(actionInfo: [String : Any]) {
        
    }
    
    func kitPublish(reinforcementInfo: [String : Any]) {
        
    }
}
