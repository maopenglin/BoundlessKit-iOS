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
            let cartridge = BKRefreshCartridge(cartridgeID: nil, actionID: actionID)
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
                validCartridges[actionID] = self[actionID] ?? BKRefreshCartridge(cartridgeID: nil, actionID: actionID)
            }
            self.valuesForKeys = validCartridges
            
            var completeSuccess = true
            for (actionID, cartridge) in self.valuesForKeys where cartridge.needsSync {
                self.group.enter()
                BKLog.debug("Refreshing cartridge for actionID <\(cartridge.actionID)>...")
                
                var payload = apiClient.credentials.json
                payload["versionID"] = apiClient.version.name
                payload["actionID"] = cartridge.actionID
                apiClient.post(url: BoundlessAPIEndpoint.refresh.url, jsonObject: payload) { response in
                    var success = false
                    defer {
                        completeSuccess = completeSuccess && success
                        self.group.leave()
                    }
                    if let responseStatusCode = response?["status"] as? Int {
                        if responseStatusCode == 200,
                            let decisionNames = response?["reinforcementCartridge"] as? [String],
                            let expiresIn = response?["expiresIn"] as? TimeInterval {
                            self[cartridge.actionID] = BKRefreshCartridge(
                                cartridgeID: nil,
                                actionID: cartridge.actionID,
                                expirationUTC: Int64( 1000*Date().addingTimeInterval(expiresIn).timeIntervalSince1970 ),
                                values: decisionNames.map({BKDecision($0, cartridge.actionID)})
                            )
                            BKLog.debug(confirmed: "Cartridge refresh for actionID <\(cartridge.actionID)> succeeded!")
                            success = true
                            return
                        } else if responseStatusCode == 400 {
                            self.removeValue(forKey: actionID)
                            BKLog.debug(confirmed: "Cartridge refresh determined actionID<\(actionID)> is no longer a valid actionID. Cartridge deleted.")
                            success = true
                            return
                        }
                    }
                    BKLog.debug(error: "Cartridge refresh for actionID <\(cartridge.actionID)> failed!")
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
