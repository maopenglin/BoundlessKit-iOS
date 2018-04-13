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
    public static var standard: BoundlessKit = {
        guard _standard == nil else {
            return _standard!
        }
        _standard = BoundlessKit()
        return _standard!
    }()
    
    internal var apiClient: BoundlessAPIClient
    
    private override convenience init() {
        guard let properties = BoundlessProperties.fromFile else {
            fatalError("Missing <BoundlessProperties.plist> file")
        }
        self.init(apiClient: BoundlessAPIClient(properties: properties, database: BKUserDefaults.standard))
    }
    
    init(apiClient: BoundlessAPIClient) {
        self.apiClient = apiClient
        super.init()
    }
    
    @objc
    public class func track(actionID: String, metadata: [String: Any] = [:]) {
        standard.track(actionID: actionID, metadata: metadata)
    }
    
    @objc
    public class func reinforce(actionID: String, metadata: [String: Any] = [:], completion: @escaping (String)->Void) {
        standard.reinforce(actionID: actionID, metadata: metadata, completion: completion)
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        apiClient.trackBatch.store(action)
//        BKLog.debug("Tracked actionID <\(actionID)>")
        BKLog.print(confirmed: "Track #<\(apiClient.trackBatch.count)> actionID:<\(actionID)>")
        apiClient.syncIfNeeded()
    }
    
    
    @objc
    public func reinforce(actionID: String, metadata: [String: Any] = [:], completion: @escaping (String)->Void) {
        apiClient.refreshContainer.decision(forActionID: actionID) { reinforcementDecision in
            let reinforcement = BKReinforcement.init(reinforcementDecision, metadata)
            completion(reinforcement.name)
            self.apiClient.reportBatch.store(reinforcement)
//            BKLog.print(confirmed: "Reinforcing actionID <\(actionID)> with reinforcement <\(reinforcement.name)>")
            BKLog.print(confirmed: "Report #<\(self.apiClient.reportBatch.count)> actionID:<\(actionID)> reinforcementID:<\(reinforcement.name)>")
            self.apiClient.syncIfNeeded()
        }
    }
    
    @objc
    public func setID(_ id: String) -> Bool {
        if !id.isEmpty && id.count <= 36 && id.range(of: "[^a-zA-Z0-9\\-]", options: .regularExpression) == nil {
            apiClient.properties.primaryIdentity = id
            return true
        } else {
            return false
        }
    }
}
