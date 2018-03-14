//
//  BKRefreshCartridgeContainer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridgeContainer : SynchronizedDictionary<String, BKRefreshCartridge>, NSCoding {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKRefreshCartridgeContainer.self, forClassName: "BKRefreshCartridgeContainer")
        NSKeyedArchiver.setClassName("BKRefreshCartridgeContainer", for: BKRefreshCartridgeContainer.self)
    }()
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: BKRefreshCartridge] else {
                return nil
        }
        self.init(dictValues)
    }
    
    func encode(with aCoder: NSCoder) {aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self.valuesForKeys), forKey: "dictValues")
    }
    
    func decision(forActionID actionID: String, completion: @escaping ((BKDecision)->Void)) {
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge(actionID: actionID)
        }
        self[actionID]?.removeFirst(completion: { (decision) in
            completion(decision ?? BKDecision.neutral(for: actionID))
        })
    }
    
    var needsSync : Bool {
        for cartridge in values {
            if cartridge.needsSync { return true }
        }
        return false
    }
    
    func commit(actionID: String, with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge(actionID: actionID)
        }
        if self[actionID]?.needsSync ?? false {
            self.synchronize(forActionID: actionID, with:
                apiClient, successful: successful)
        } else {
            successful(true)
        }
    }
    
    let syncQueue = DispatchQueue(label: "boundless.kit.cartridgecontainer")
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        syncQueue.async {
            let group = DispatchGroup()
            var completeSuccess = true
            for cartridge in self.values where cartridge.needsSync {
                group.enter()
                self.synchronize(forActionID: cartridge.actionID, with: apiClient) { success in
                    completeSuccess = completeSuccess && success
                    group.leave()
                }
            }
            group.notify(queue: .global()) {
                successful(completeSuccess)
            }
        }
    }
    
    func synchronize(forActionID actionID: String, with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge(actionID: actionID)
        }
        guard let cartridge = self[actionID],
            var payload = apiClient.properties.apiCredentials else {
                successful(false)
                return
        }
        print("Refreshing \(cartridge.actionID)...")
        
        payload["actionID"] = cartridge.actionID
        apiClient.post(url: BoundlessAPIEndpoint.refresh.url, jsonObject: payload) { response in
            var success = false
            defer { successful(success) }
            if let responseStatusCode = response?["status"] as? Int {
                if responseStatusCode == 200,
                    let reinforcementCartridge = response?["reinforcementCartridge"] as? [String],
                    let expiresIn = response?["expiresIn"] as? Int {
                    let values = reinforcementCartridge.map({ (reinforcementDecision) -> BKDecision in
                        BKDecision.init(reinforcementDecision, cartridge.actionID)
                    })
                    cartridge.removeAll()
                    cartridge.append(values)
                    cartridge.expirationUTC = Int64(Date().addingTimeInterval(TimeInterval(1000*expiresIn)).timeIntervalSince1970)
                    print("\(cartridge.actionID) refreshed!")
                    success = true
                } else if responseStatusCode == 400 {
                    print("Cartridge contained outdated actionID. Removing cartridge.")
                    self.removeValue(forKey: actionID)
                    success = true
                }
            }
        }.start()
        
    }
    
}

