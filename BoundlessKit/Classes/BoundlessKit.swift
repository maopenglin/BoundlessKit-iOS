//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//



import Foundation

public protocol BoundlessKitDelegateProtocol {
//    func kitActionIDs() -> [String]
//    func kitReinforcement(for actionID: String, completion: @escaping (String)->Void)
//    func kitPublish(actionInfo: [String:Any])
//    func kitPublish(reinforcementInfo: [String:Any])
}

public class BoundlessKit : NSObject {
    
    let properties: BoundlessProperties?
    var httpClient = HTTPClient()
    
    let database: BKDatabase
    let delegate: BoundlessKitDelegateProtocol
    
    var trackedActions: BKTrackBatch
    var reportedActions: BKReportBatch
    var cartridgeReinforcements: BKRefreshCartridges
    
    init(properties: BoundlessProperties? = BoundlessProperties.fromFile,
         database: BKDatabase = BKDatabase.init(suiteName: "boundless.kit.database")!,
         delegate: BoundlessKitDelegateProtocol) {
        self.properties = properties
        self.database = database
        self.delegate = delegate
        self.trackedActions = BKTrackBatch()
        self.reportedActions = BKReportBatch()
        self.cartridgeReinforcements = BKRefreshCartridges()
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        print("Adding context to tracked action <\(actionID)>")
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                action.metadata[key] = value
            }
            self.trackedActions.append(action)
            self.database.archive(self.trackedActions, forKey: "trackedActions")
        }
    }
    
    @objc
    public func reinforce(actionID: String, completion: ((String)->Void)?) {
        cartridgeReinforcements.decision(forActionID: actionID) { reinforcementDecision in
            let reinforcement = reinforcementDecision.asReinforcement
            BoundlessContext.getContext() { contextInfo in
                for (key, value) in contextInfo {
                    reinforcement.metadata[key] = value
                }
                self.reportedActions.store(reinforcement)
            }
        }
    }
    
    
}
