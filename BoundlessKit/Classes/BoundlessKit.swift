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
        _standard = BoundlessKit.init(apiClient: BoundlessAPIClient.init(properties: properties),
                                      database: BKUserDefaults.standard)
        return _standard!
    }
    
    
    internal var launcher: BoundlessKitLauncher?
    internal var apiClient: BoundlessAPIClient {
        didSet {
            apiClient.trackBatch = trackBatch
            apiClient.reportBatch = reportBatch
            apiClient.refreshContainer = refreshContainer
        }
    }
    internal let database: BKDatabase
    
    internal var trackBatch: BKTrackBatch
    internal var reportBatch: BKReportBatch
    internal var refreshContainer: BKRefreshCartridgeContainer
    
    init(apiClient: BoundlessAPIClient, database: BKDatabase) {
        self.apiClient = apiClient
        self.database = database
        self.trackBatch = database.unarchive("trackBatch") ?? BKTrackBatch()
        self.reportBatch = database.unarchive("reportBatch") ?? BKReportBatch()
        self.refreshContainer = database.unarchive("refreshContainer") ?? BKRefreshCartridgeContainer()
        self.apiClient = apiClient
        super.init()
        apiClient.trackBatch = trackBatch
        apiClient.reportBatch = reportBatch
        apiClient.refreshContainer = refreshContainer
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        self.trackBatch.store(action)
        print("Tracked action <\(actionID)>")
        self.database.archive(self.trackBatch, forKey: "trackBatch")
        self.apiClient.syncIfNeeded()
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
            self.apiClient.syncIfNeeded()
        }
    }
}
