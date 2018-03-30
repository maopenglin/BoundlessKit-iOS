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
    
    fileprivate static var _standard: BoundlessKit?
    public class var standard: BoundlessKit {
        if let _ = _standard {
            return _standard!
        }
        guard let properties = BoundlessProperties.fromFile else {
            fatalError("Missing <BoundlessProperties.plist> file")
        }
        _standard = BoundlessKit.init(apiClient: BoundlessAPIClient.init(properties: properties), database: BKUserDefaults.standard)
        return _standard!
    }
    
    
    internal var launcher: BoundlessKitLauncher?
    internal let apiClient: BoundlessAPIClient
    internal let database: BKDatabase
    
    internal var trackBatch: BKTrackBatch
    internal var reportBatch: BKReportBatch
    internal var refreshContainer: BKRefreshCartridgeContainer
    
    init(apiClient: BoundlessAPIClient, database: BKDatabase) {
        self.apiClient = apiClient
        self.database = database
        self.trackBatch = BKTrackBatch.initWith(database: database, forKey: "trackBatch")
        self.reportBatch = BKReportBatch.initWith(database: database, forKey: "reportBatch")
        self.refreshContainer = BKRefreshCartridgeContainer.initWith(database: database, forKey: "refreshContainer")
        super.init()
        apiClient.trackBatch = self.trackBatch
        apiClient.reportBatch = self.reportBatch
        apiClient.refreshContainer = self.refreshContainer
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        trackBatch.store(action)
        BKLog.debug("Tracked actionID <\(actionID)>")
        apiClient.syncIfNeeded()
    }
    
    @objc
    public func reinforce(actionID: String, metadata: [String: Any] = [:], completion: @escaping (String)->Void) {
        refreshContainer.decision(forActionID: actionID) { reinforcementDecision in
            let reinforcement = BKReinforcement.init(reinforcementDecision, metadata)
            completion(reinforcement.name)
            self.reportBatch.store(reinforcement)
            BKLog.print("Reported actionID <\(actionID)> with reinforcementID <\(reinforcement.name)>")
            self.apiClient.syncIfNeeded()
        }
    }
}
