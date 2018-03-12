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
    var cartridgeReinforcements: BKRefreshCartridge
    
    init(properties: BoundlessProperties? = BoundlessProperties.fromFile,
         database: BKDatabase = BKDatabase.init("boundless.kit.database"),
         delegate: BoundlessKitDelegateProtocol) {
        self.properties = properties
        self.database = database
        self.delegate = delegate
        self.trackedActions = BKTrackBatch()
        self.reportedActions = BKReportBatch()
        self.cartridgeReinforcements = BKRefreshCartridge()
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BKAction(actionID, metadata)
        print("Adding context to tracked action <\(actionID)>")
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                action.metadata[key] = value
            }
            
            self.trackedActions.append(BKRecord.init(recordType: "track", recordID: action.hash))
            self.delegate.kitPublish(actionInfo: action.toJSONType())
        }
    }
    
    @objc
    public func reinforce(actionID: String, completion: ((String)->Void)?) {
        let action = BKAction(actionID)
        delegate.kitReinforcement(for: action.name) { reinforcementDecision in
            let reinforcement = BoundlessReinforcement.init(reinforcementDecision, action.name)
            BoundlessContext.getContext() { contextInfo in
                for (key, value) in contextInfo {
                    reinforcement.metadata[key] = value
                }
                self.delegate.kitPublish(reinforcementInfo: reinforcement.toJSONType())
            }
        }
    }
    
    
}

// MARK: - BoundlessAPI Synchronization
extension BoundlessKit {
    func syncTrackedActions(completion: @escaping ()->Void = {}) {
        guard var payload = properties?.apiCredentials else {
            completion()
            return
        }
        
        let actions = trackedActions.values
        payload["actions"] = actions
        httpClient.post(url: HTTPClient.BoundlessAPI.track.url, jsonObject: payload) { response in
            if let status = response?["status"] as? Int {
                if status == 200 {
                    self.trackedActions.removeFirst(actions.count)
                    print("Cleared tracked actions.")
                }
            }
            completion()
            }.start()
    }
    
    func syncReportedActions(completion: @escaping ()->Void = {}) {
        guard var payload = properties?.apiCredentials else {
            completion()
            return
        }
        
        let actions = reportedActions.values
        payload["actions"] = actions
        httpClient.post(url: HTTPClient.BoundlessAPI.track.url, jsonObject: payload) { response in
            if let status = response?["status"] as? Int {
                if status == 200 {
                    self.reportedActions.removeFirst(actions.count)
                    print("Cleared reported actions.")
                }
            }
            completion()
            }.start()
    }
    
    func syncReinforcementDecisions(for actionID: String, completion: @escaping ()->Void = {}) {
        guard var payload = properties?.apiCredentials else {
            completion()
            return
        }
        print("Refreshing \(actionID)...")
        
        payload["actionID"] = actionID
        httpClient.post(url: HTTPClient.BoundlessAPI.refresh.url, jsonObject: payload) { response in
            if let responseStatusCode = response?["status"] as? Int {
                if responseStatusCode == 200,
                    let cartridgeDecisions = response?["reinforcementCartridge"] as? [String],
                    let expiresIn = response?["expiresIn"] as? Int {
                    self.cartridgeReinforcements[actionID] = SynchronizedArray(cartridgeDecisions)
                    print("\(actionID) refreshed!")
                } else if responseStatusCode == 400 {
                    print("Cartridge contained outdated actionID. Flushing.")
                    self.cartridgeReinforcements.removeValue(forKey: actionID)
                }
            }
            completion()
            }.start()
    }
}

