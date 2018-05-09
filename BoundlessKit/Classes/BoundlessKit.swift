//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import Foundation

open class BoundlessKit : NSObject {
    
    internal static var _standard: BoundlessKit?
    open class var standard: BoundlessKit {
        guard _standard == nil else {
            return _standard!
        }
        _standard = BoundlessKit()
        return _standard!
    }
    
    internal let apiClient: BoundlessAPIClient
    
    public convenience override init() {
        guard let properties = BoundlessProperties.fromFile else {
            fatalError("Missing <BoundlessProperties.plist> file")
        }
        self.init(apiClient: BoundlessAPIClient(credentials: properties.credentials, version: properties.version, database: BKUserDefaults.standard))
    }
    
    init(apiClient: BoundlessAPIClient) {
        self.apiClient = apiClient
        super.init()
    }
    
    @objc
    open class func track(actionID: String, metadata: [String: Any] = [:]) {
        standard.track(actionID: actionID, metadata: metadata)
    }
    
    @objc
    open class func reinforce(actionID: String, metadata: [String: Any] = [:], completion: @escaping (String)->Void) {
        standard.reinforce(actionID: actionID, metadata: metadata, completion: completion)
    }
    
    @objc
    open func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        apiClient.trackBatch.store(action)
        apiClient.syncIfNeeded()
    }
    
    @objc
    open func reinforce(actionID: String, metadata: [String: Any] = [:], completion: @escaping (String)->Void) {
        apiClient.refreshContainer.decision(forActionID: actionID) { reinforcementDecision in
            let reinforcement = BKReinforcement(reinforcementDecision, metadata)
            completion(reinforcement.name)
            self.apiClient.reportBatch.store(reinforcement)
            self.apiClient.syncIfNeeded()
        }
    }
    
    @objc
    open func setCustomUserID(_ id: String?) {
        apiClient.setCustomUserIdentity(id)
    }
}
