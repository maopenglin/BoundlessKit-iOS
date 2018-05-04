//
//  BKRefreshCartridgeContainer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridgeContainer : SynchronizedDictionary<String, BKRefreshCartridge>, BKData, BoundlessAPISynchronizable {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKRefreshCartridgeContainer.self, forClassName: "BKRefreshCartridgeContainer")
        NSKeyedArchiver.setClassName("BKRefreshCartridgeContainer", for: BKRefreshCartridgeContainer.self)
    }()
    
    var storage: BKDatabase.Storage?
    var enabled = true
    
    class func initWith(database: BKDatabase, forKey key: String) -> BKRefreshCartridgeContainer {
        let container: BKRefreshCartridgeContainer
        if let archived: BKRefreshCartridgeContainer = database.unarchive(key) {
            container = archived
        } else {
            container = BKRefreshCartridgeContainer()
        }
        container.storage = (database, key)
        return container
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: BKRefreshCartridge] else {
                return nil
        }
        self.init(dictValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self.valuesForKeys), forKey: "dictValues")
    }
    
    func decision(forActionID actionID: String, completion: @escaping ((BKDecision)->Void)) {
        guard enabled else {
            completion(BKDecision.neutral(for: actionID))
            return
        }
        
        let cartridge: BKRefreshCartridge = self[actionID] ?? {
            let cartridge = BKRefreshCartridge(actionID: actionID)
            self[actionID] = cartridge
            return cartridge
        }()
        
        cartridge.removeFirst(completion: { (decision) in
            if let decision = decision {
                BKLog.debug("Cartridge for actionID <\(actionID)> unloaded decision <\(decision.name)>")
                completion(decision)
            } else {
                let defaultDecision = BKDecision.neutral(for: actionID)
                BKLog.debug("Cartridge for actionID <\(actionID)> is empty! Using default decision <\(defaultDecision.name)>")
                completion(defaultDecision)
            }
            self.storage?.0.archive(self, forKey: self.storage!.1)
        })
    }
    
    func commit(actionID: String, with apiClient: BoundlessAPIClient) {
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge(actionID: actionID)
            BKLog.debug("Committed actionID <\(actionID)>")
        }
        if self[actionID]?.needsSync ?? false {
            self.synchronize(forActionID: actionID, with:
            apiClient) { success in
                self.storage?.0.archive(self, forKey: self.storage!.1)
            }
        } else {
            self.storage?.0.archive(self, forKey: self.storage!.1)
        }
    }
    
    var needsSync : Bool {
        for cartridge in values {
            if cartridge.needsSync { return true }
        }
        return false
    }
    
    let syncQueue = DispatchQueue(label: "boundless.kit.cartridgecontainer")
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        syncQueue.async {
            for actionID in apiClient.version.mappings.keys {
                if self[actionID] == nil {
                    self[actionID] = BKRefreshCartridge(actionID: actionID)
                }
            }
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
                self.storage?.0.archive(self, forKey: self.storage!.1)
                successful(completeSuccess)
            }
        }
    }
    
    private func synchronize(forActionID actionID: String, with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge(actionID: actionID)
        }
        guard let cartridge = self[actionID] else {
                successful(false)
                return
        }
        var payload = apiClient.apiCredentials
        BKLog.debug("Refreshing cartridge for actionID <\(cartridge.actionID)>...")
        
        payload["actionID"] = cartridge.actionID
        apiClient.post(url: BoundlessAPIEndpoint.refresh.url, jsonObject: payload) { response in
            var success = false
            defer { successful(success) }
            if let responseStatusCode = response?["status"] as? Int {
                if responseStatusCode == 200,
                    let reinforcementCartridge = response?["reinforcementCartridge"] as? [String],
                    let expiresIn = response?["expiresIn"] as? TimeInterval {
                    let values = reinforcementCartridge.map({ (reinforcementDecision) -> BKDecision in
                        BKDecision.init(reinforcementDecision, cartridge.actionID)
                    })
                    cartridge.removeAll()
                    cartridge.append(values)
                    cartridge.expirationUTC = Int64( 1000*Date().addingTimeInterval(expiresIn).timeIntervalSince1970 )
                    BKLog.print(confirmed: "Cartridge refresh for actionID <\(cartridge.actionID)> succeeded!")
                    success = true
                    return
                } else if responseStatusCode == 400 {
                    self.removeValue(forKey: actionID)
                    BKLog.print(confirmed: "Cartridge refresh determined actionID<\(cartridge.actionID)> is no longer a valid actionID. Cartridge deleted.")
                    success = true
                    return
                }
            }
            BKLog.print(error: "Cartridge refresh for actionID <\(cartridge.actionID)> failed!")
        }.start()
        
    }
    
}
