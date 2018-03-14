//
//  BKTrackBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKTrackBatch : SynchronizedArray<BKAction>, NSCoding, BoundlessAPISynchronizable {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKTrackBatch.self, forClassName: "BKTrackBatch")
        NSKeyedArchiver.setClassName("BKTrackBatch", for: BKTrackBatch.self)
    }()
    
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxCountUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         values: [BKAction] = []) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxCountUntilSync = sizeUntilSync
        super.init(values)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let arrayData = aDecoder.decodeObject(forKey: "arrayValues") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BKAction] else {
                return nil
        }
        self.init(timeUntilSync: aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync"),
                  sizeUntilSync: aDecoder.decodeInteger(forKey: "desiredMaxCountUntilSync"),
                  values: arrayValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: values), forKey: "arrayValues")
        aCoder.encode(desiredMaxTimeUntilSync, forKey: "desiredMaxTimeUntilSync")
        aCoder.encode(desiredMaxCountUntilSync, forKey: "desiredMaxCountUntilSync")
    }
    
    func store(_ action: BKAction) {
        self.append(action)
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                action.metadata[key] = value
            }
        }
    }
    
    var needsSync: Bool {
        if count >= desiredMaxCountUntilSync {
            return true
        }
        
        if let startTime = self.first?.utc {
            return Int64(1000*NSDate().timeIntervalSince1970) >= (startTime + desiredMaxTimeUntilSync)
        }
        
        return false
    }
    
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        guard var payload = apiClient.properties.apiCredentials else {
            successful(false)
            return
        }
        
        let actions = self.values
        payload["actions"] = actions.map({ (action) -> [String: Any] in
            action.toJSONType()
        })
        apiClient.post(url: BoundlessAPIEndpoint.track.url, jsonObject: payload) { response in
            var success = false
            defer { successful(success) }
            if let status = response?["status"] as? Int {
                if status == 200 {
                    self.removeFirst(actions.count)
                    print("Cleared tracked actions.")
                    success = true
                }
            }
        }.start()
    }
}