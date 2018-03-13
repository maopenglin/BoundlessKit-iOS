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
    
    let properties: BoundlessProperties
    var httpClient = HTTPClient()
    
    let database: BKDatabase
    let delegate: BoundlessKitDelegateProtocol
    
    var trackedActions: BKTrackBatch
    var reportedActions: BKReportBatch
    var cartridgeReinforcements: BKRefreshCartridgeContainer
    
    init(properties: BoundlessProperties = BoundlessProperties.fromFile!,
         database: BKDatabase = UserDefaults.init(suiteName: "boundless.kit.database")!,
         delegate: BoundlessKitDelegateProtocol) {
        self.properties = properties
        self.database = database
        self.delegate = delegate
        self.trackedActions = BKTrackBatch()
        self.reportedActions = BKReportBatch()
        self.cartridgeReinforcements = BKRefreshCartridgeContainer()
        super.init()
        self.trackedActions.delegate = self
        self.reportedActions.delegate = self
        self.cartridgeReinforcements.delegate = self
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        self.trackedActions.store(action)
        print("Tracked action <\(actionID)>")
        self.database.archive(self.trackedActions, forKey: "trackedActions")
    }
    
    @objc
    public func reinforce(actionID: String, completion: @escaping (String)->Void) {
        cartridgeReinforcements.decision(forActionID: actionID) { reinforcementDecision in
            let reinforcement = reinforcementDecision.asReinforcement
            completion(reinforcement.name)
            self.reportedActions.store(reinforcement)
            print("Reported action <\(actionID)> with reinforcement <\(reinforcement.name)>")
            self.database.archive(self.reportedActions, forKey: "reportedActions")
        }
    }
}
