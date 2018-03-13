//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import Foundation

//public protocol BoundlessKitDelegateProtocol {
////    func kitActionIDs() -> [String]
////    func kitReinforcement(for actionID: String, completion: @escaping (String)->Void)
////    func kitPublish(actionInfo: [String:Any])
////    func kitPublish(reinforcementInfo: [String:Any])
//}

public class BoundlessKit : NSObject {
    
//    let delegate: BoundlessKitDelegateProtocol
    
    let database: BKDatabase
    
    var trackBatch: BKTrackBatch
    var reportBatch: BKReportBatch
    var refreshContainer: BKRefreshCartridgeContainer
    
    func set(apiClient: BoundlessAPIClient?) {
        self.trackBatch.apiClient = apiClient
        self.reportBatch.apiClient = apiClient
        self.refreshContainer.apiClient = apiClient
    }
    
    init(apiClient: BoundlessAPIClient? = BoundlessAPIClient.init(properties: BoundlessProperties.fromFile!),
         database: BKDatabase = BKUserDefaults.standard) {
        self.database = database
        self.trackBatch = database.unarchive("trackBatch") ?? BKTrackBatch()
        self.reportBatch = database.unarchive("reportBatch") ?? BKReportBatch()
        self.refreshContainer = database.unarchive("refreshContainer") ?? BKRefreshCartridgeContainer()
        super.init()
        set(apiClient: apiClient)
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        self.trackBatch.store(action)
        print("Tracked action <\(actionID)>")
        self.database.archive(self.trackBatch, forKey: "trackBatch")
    }
    
    @objc
    public func reinforce(actionID: String, completion: @escaping (String)->Void) {
        refreshContainer.decision(forActionID: actionID) { reinforcementDecision in
            self.database.archive(self.refreshContainer, forKey: "refreshContainer")
            let reinforcement = reinforcementDecision.asReinforcement
            completion(reinforcement.name)
            self.reportBatch.store(reinforcement)
            print("Reported action <\(actionID)> with reinforcement <\(reinforcement.name)>")
            self.database.archive(self.reportBatch, forKey: "reportBatch")
        }
    }
    
    @objc
    public func refreshReinforcements(forActionID actionID: String, completion: @escaping ()->Void = {}) {
        refreshContainer.refresh(actionID: actionID) {
            self.database.archive(self.refreshContainer, forKey: "refreshContainer")
            completion()
        }
    }
}
