//
//  BoundlessKitClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation


internal class BoundlessKitClient : NSObject {
    
    let trackedActionsKey = "boundless.kit.client.trackedactions"
    let reportedActionsKey = "boundless.kit.client.reportedactions"
    let cartridgeReinforcementsKey = "boundless.kit.client.cartridgereinforcements"
    
    var trackedActions = SynchronizedArray<[String : Any]>()
    var reportedActions = SynchronizedArray<[String : Any]>()
    var cartridgeReinforcements = SynchronizedDictionary<String, SynchronizedArray<String>>()
    
    let properties: BoundlessProperties?
    var httpClient = HTTPClient()
    
    init(properties: BoundlessProperties?) {
        self.properties = properties
        super.init()
    }
    
}

extension BoundlessKitClient : BoundlessKitDataSource, BoundlessKitDelegate {
    public func kitActions() -> [String] {
        return cartridgeReinforcements.keys
    }
    
    public func kitReinforcements(for actionID: String) -> [String] {
        return cartridgeReinforcements[actionID]?.filter({ _ in return true }) ?? []
    }
    
    @objc
    public func kitPublish(actionInfo: [String : Any]) {
        trackedActions += actionInfo
    }
    
    public func kitPublish(reinforcementInfo: [String : Any]) {
        reportedActions += reinforcementInfo
    }
}

// MARK: - BoundlessAPI Synchronization
extension BoundlessKitClient {
    func syncTrackedActions(completion: @escaping ()->Void = {}) {
        guard var payload = properties?.apiCredentials else {
            completion()
            return
        }
        
        let actions = trackedActions.filter({ _ in return true })
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
        
        let actions = reportedActions.filter({ _ in return true })
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

// MARK: - Data Storage
extension BoundlessKitClient {
    func loadData() {
        if let savedTrack: [[String : Any]] = UserDefaults.boundless.unarchive(trackedActionsKey) {
            trackedActions += savedTrack
        }
        if let savedReport: [[String : Any]] = UserDefaults.boundless.unarchive(reportedActionsKey) {
            reportedActions += savedReport
        }
        if let savedCartridges: [String : [String]] = UserDefaults.boundless.unarchive(cartridgeReinforcementsKey) {
            for (actionID, cartridge) in savedCartridges {
                if cartridgeReinforcements[actionID] == nil { cartridgeReinforcements[actionID] = SynchronizedArray() }
                cartridgeReinforcements[actionID]? += cartridge
            }
        }
    }
    
    func saveData() {
        UserDefaults.boundless.archive(trackedActions.filter({ _ in return true }), forKey: trackedActionsKey)
        UserDefaults.boundless.archive(reportedActions.filter({ _ in return true }), forKey: reportedActionsKey)
        UserDefaults.boundless.archive(cartridgeReinforcements.flatMap({ (actionID, cartridge) -> (String, [String])? in
            return (actionID, cartridge.filter({ _ in return true }))
        }), forKey: cartridgeReinforcementsKey)
    }
    
    func clearData() {
        UserDefaults.boundless.archive(nil, forKey: trackedActionsKey)
        UserDefaults.boundless.archive(nil, forKey: reportedActionsKey)
        UserDefaults.boundless.archive(nil, forKey: cartridgeReinforcementsKey)
        trackedActions = SynchronizedArray()
        reportedActions = SynchronizedArray()
        cartridgeReinforcements = SynchronizedDictionary()
    }
}
