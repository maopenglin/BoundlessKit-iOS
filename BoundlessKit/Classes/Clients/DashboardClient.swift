//
//  DashboardClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

class DashboardClient : NSObject {
    
    var actionIDs = ["action1"]
    var futureReinforcements = [String: [BoundlessReinforcement]]()
    
    func loadKit() {
        
        loadCodelessReinforcements(mappings: [String : [String : Any]]())
        
        let kit = BoundlessKit()
        kit.launch(delegate: self, dataSource: self, arguements: [:])
    }
    
    func loadCodelessReinforcements(mappings:[String: [String: Any]]) {
        for (actionID, value) in mappings {
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                for reinforcementDict in reinforcements {
                    if let codelessVisual = CodelessVisual.convert(from: reinforcementDict) {
                        let reinforcement = BoundlessReinforcement.init(actionID, codelessVisual.primitive)
                        print("Future reinforcement:\(reinforcement.notification.rawValue)")
                        codelessVisual.register(for: reinforcement.notification)
                        if futureReinforcements[actionID] == nil {
                            futureReinforcements[actionID] = []
                        }
                        futureReinforcements[actionID]?.append(reinforcement)
                    }
                }
            }
        }
    }
    
    
}

extension DashboardClient : BoundlessKitDelegate, BoundlessKitDataSource {
    
    func kitActionIDs() -> [String] {
        return actionIDs
    }
    
    func kitReinforcements(for actionID: String) -> [String] {
        return futureReinforcements[actionID]?.map({ (reinforcement) -> String in
            return reinforcement.name
        }) ?? []
    }
    
    func kitPublish(actionInfo: [String : Any]) {
        
    }
    
    func kitPublish(reinforcementInfo: [String : Any]) {
        
    }
}
