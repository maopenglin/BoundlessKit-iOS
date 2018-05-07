//
//  BKTrackBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKTrackBatch : SynchronizedArray<BKAction>, BKData, BoundlessAPISynchronizable {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKTrackBatch.self, forClassName: "BKTrackBatch")
        NSKeyedArchiver.setClassName("BKTrackBatch", for: BKTrackBatch.self)
    }()
    
    var enabled = true
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxCountUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         values: [BKAction] = []) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxCountUntilSync = sizeUntilSync
        super.init(values)
    }
    
    var storage: BKDatabase.Storage?
    
    class func initWith(database: BKDatabase, forKey key: String) -> BKTrackBatch {
        let batch: BKTrackBatch
        if let archived: BKTrackBatch = database.unarchive(key) {
            batch = archived
        } else {
            batch = BKTrackBatch()
        }
        batch.storage = (database, key)
        return batch
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
    
    let storeGroup = DispatchGroup()
    
    func store(_ action: BKAction) {
        //        BKLog.debug("Tracked action:\(action.name) metadata:\(action.metadata as AnyObject)")
        guard enabled else {
            return
        }
        self.append(action)
        storeGroup.enter()
        self.storage?.0.archive(self, forKey: self.storage!.1)
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                action.metadata[key] = value
            }
            self.storage?.0.archive(self, forKey: self.storage!.1)
            self.storeGroup.leave()
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
        storeGroup.wait()
        let trackCopy = self.values
        guard trackCopy.count > 0 else {
            successful(true)
            return
        }
        BKLog.debug("Sending track batch with \(trackCopy.count) actions...")
        
        var payload = apiClient.credentials.json
        payload["versionID"] = apiClient.version.name
        payload["actions"] = trackCopy.map({$0.toJSONType()})
        apiClient.post(url: BoundlessAPIEndpoint.track.url, jsonObject: payload) { response in
            var success = false
            defer { successful(success) }
            if let status = response?["status"] as? Int {
                if status == 200 {
                    self.removeFirst(trackCopy.count)
                    self.storage?.0.archive(self, forKey: self.storage!.1)
                    BKLog.print(confirmed: "Sent track batch!")
                    success = true
                    return
                }
            }
            BKLog.print(error: "Sending track batch failed")
        }.start()
    }
}
