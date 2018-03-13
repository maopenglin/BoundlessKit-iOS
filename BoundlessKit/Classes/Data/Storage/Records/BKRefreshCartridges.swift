//
//  BKRefreshCartridges.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridges : SynchronizedDictionary<String, BKRefreshCartridge>, NSCoding {
    
    var delegate: BKSyncAPIDelegate?
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: BKRefreshCartridge] else {
                return nil
        }
        self.init(dictValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: copy()), forKey: "dictValues")
    }
    
    func decision(forActionID actionID: String, completion: @escaping ((BoundlessDecision)->Void)) {
        if self[actionID] == nil {
            self[actionID] = BKRefreshCartridge()
        }
        self[actionID]?.removeFirst(completion: { (decision) in
            completion(decision ?? BoundlessDecision.neutral(for: actionID))
        })
    }
}

extension BKRefreshCartridges {
    func sync(for actionID: String, completion: @escaping ()->Void = {}) {
        guard var payload = delegate?.properties.apiCredentials else {
            completion()
            return
        }
        print("Refreshing \(actionID)...")
        
        payload["actionID"] = actionID
        delegate?.httpClient.post(url: HTTPClient.BoundlessAPI.refresh.url, jsonObject: payload) { response in
            if let responseStatusCode = response?["status"] as? Int {
                if responseStatusCode == 200,
                    let reinforcementCartridge = response?["reinforcementCartridge"] as? [String],
                    let expiresIn = response?["expiresIn"] as? Int {
                    let values = reinforcementCartridge.map({ (reinforcementDecision) -> BoundlessDecision in
                        BoundlessDecision.init(reinforcementDecision, actionID)
                    })
                    let expirationUTC = Int64(Date().addingTimeInterval(TimeInterval(1000*expiresIn)).timeIntervalSince1970)
                    self[actionID] = BKRefreshCartridge.init(expirationUTC: expirationUTC, values: values)
                    print("\(actionID) refreshed!")
                } else if responseStatusCode == 400 {
                    print("Cartridge contained outdated actionID. Flushing.")
                    self.removeValue(forKey: actionID)
                }
            }
            completion()
        }.start()
    }
}
