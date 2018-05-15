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
            let cartridge = BKRefreshCartridge.initNeutral(actionID: actionID)
            self[actionID] = cartridge
            return cartridge
        }()
        
        cartridge.removeFirst(completion: { (decision) in
            if let decision = decision {
                BKLog.print("Cartridge for actionID <\(actionID)> unloaded decision <\(decision.name)>")
                completion(decision)
            } else {
                let defaultDecision = BKDecision.neutral(for: actionID)
                BKLog.print("Cartridge for actionID <\(actionID)> is empty! Using default decision <\(defaultDecision.name)>")
                completion(defaultDecision)
            }
            self.storage?.0.archive(self, forKey: self.storage!.1)
        })
    }
    
    func erase() {
        self.valuesForKeys = [:]
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }
    
    var needsSync : Bool {
        guard enabled else { return false }
        for cartridge in values {
            if cartridge.needsSync { return true }
        }
        return false
    }
    
    let syncQueue = DispatchQueue(label: "boundless.kit.cartridgecontainer")
    let group = DispatchGroup()
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        guard enabled else {
            successful(true)
            return
        }
        syncQueue.async {
            guard self.group.wait(timeout: .now()) == .success else {
                successful(false)
                return
            }
            self.group.enter()
            
            var validCartridges = [String: BKRefreshCartridge]()
            for actionID in apiClient.version.mappings.keys {
                validCartridges[actionID] = self[actionID] ?? BKRefreshCartridge.initNeutral(actionID: actionID)
            }
            self.valuesForKeys = validCartridges
            
            var completeSuccess = true
            for (actionID, cartridge) in self.valuesForKeys where cartridge.needsSync {
                self.group.enter()
                BKLog.debug("Refreshing cartridge for actionID <\(cartridge.actionID)>...")
                
                var payload = apiClient.credentials.json
                payload["versionId"] = apiClient.version.name
                payload["actionName"] = cartridge.actionID
                apiClient.post(url: BoundlessAPIEndpoint.refresh.url, jsonObject: payload) { response in
                    var success = false
                    defer {
                        completeSuccess = completeSuccess && success
                        self.group.leave()
                    }
                    if let errors = response?["errors"] as? [String: Any] {
                        BKLog.debug(error: "Cartridge refresh for actionID <\(cartridge.actionID)> failed with error type <\(errors["type"] ?? "nil")> message <\(errors["msg"] ?? "nil")>")
                        return
                    }
                    if let cartridgeId = response?["cartridgeId"] as? String,
                        let ttl = response?["ttl"] as? Double,
                        let reinforcements = response?["reinforcements"] as? [[String: Any]] {
                        self[cartridge.actionID] = BKRefreshCartridge(
                            cartridgeID: cartridgeId,
                            actionID: cartridge.actionID,
                            expirationUTC: Int64( 1000*Date().timeIntervalSince1970 + ttl),
                            values: reinforcements.flatMap({$0["reinforcementName"] as? String}).flatMap({BKDecision.init($0, cartridgeId, cartridge.actionID)})
                        )
                        BKLog.debug(confirmed: "Cartridge refresh for actionID <\(cartridge.actionID)> succeeded!")
                        success = true
                        return
                    }
                }.start()
            }
            self.group.notify(queue: .global()) {
                self.storage?.0.archive(self, forKey: self.storage!.1)
                successful(completeSuccess)
            }
            self.group.leave()
        }
    }
    
}
