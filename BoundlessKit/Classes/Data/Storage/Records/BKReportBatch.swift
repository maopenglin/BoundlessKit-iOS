//
//  BKReportBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKReportBatch : SynchronizedDictionary<String, SynchronizedArray<BKReinforcement>>, BKData, BoundlessAPISynchronizable {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKReportBatch.self, forClassName: "BKReportBatch")
        NSKeyedArchiver.setClassName("BKReportBatch", for: BKReportBatch.self)
    }()
    
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxCountUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         dict: [String: [BKReinforcement]] = [:]) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxCountUntilSync = sizeUntilSync
        super.init(dict.mapValues({ (reinforcements) -> SynchronizedArray<BKReinforcement> in
            return SynchronizedArray(reinforcements)
        }))
    }
    
    var storage: BKDatabase.Storage?
    
    class func initWith(database: BKDatabase, forKey key: String) -> BKReportBatch {
        let batch: BKReportBatch
        if let archived: BKReportBatch = database.unarchive(key) {
            batch = archived
        } else {
            batch = BKReportBatch()
        }
        batch.storage = (database, key)
        return batch
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: [BKReinforcement]] else {
                return nil
        }
        let desiredMaxTimeUntilSync = aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync")
        let desiredMaxCountUntilSync = aDecoder.decodeInteger(forKey: "desiredMaxCountUntilSync")
        self.init(timeUntilSync: desiredMaxTimeUntilSync,
                  sizeUntilSync: desiredMaxCountUntilSync,
                  dict: dictValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self.valuesForKeys.mapValues({ (synchronizedArray) -> [BKReinforcement] in
            return synchronizedArray.values
        })), forKey: "dictValues")
        aCoder.encode(desiredMaxTimeUntilSync, forKey: "desiredMaxTimeUntilSync")
        aCoder.encode(desiredMaxCountUntilSync, forKey: "desiredMaxCountUntilSync")
    }
    
    let storeGroup = DispatchGroup()
    
    func store(_ reinforcement: BKReinforcement) {
        if self[reinforcement.actionID] == nil {
            self[reinforcement.actionID] = SynchronizedArray()
        }
        self[reinforcement.actionID]?.append(reinforcement)
        BKLog.debug(confirmed: "Report #<\(count)> actionID:<\(reinforcement.actionID)> with reinforcementID:<\(reinforcement.name)>")
        storeGroup.enter()
        self.storage?.0.archive(self, forKey: self.storage!.1)
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                reinforcement.metadata[key] = value
            }
            self.storage?.0.archive(self, forKey: self.storage!.1)
            self.storeGroup.leave()
        }
    }
    
    var needsSync: Bool {
        if count >= desiredMaxCountUntilSync {
            return true
        }
        
        let timeNow = Int64(1000*Date().timeIntervalSince1970)
        for reports in values {
            if let startTime = reports.first?.utc,
                startTime + desiredMaxTimeUntilSync <= timeNow {
                return true
            }
        }
        
        return false
    }
    
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool)->Void = {_ in}) {
        storeGroup.wait()
        let reportCopy = self.valuesForKeys
        let reportCount = reportCopy.values.reduce(0, {$0 + $1.count})
        guard reportCount > 0 else {
            successful(true)
            return
        }
//        BKLog.debug("Sending report batch with \(reportCount) actions...")
        
        var payload = apiClient.credentials.json
        payload["versionID"] = apiClient.version.name
        payload["actions"] = reportCopy.values.flatMap({$0.values}).map({$0.toJSONType()})
        apiClient.post(url: BoundlessAPIEndpoint.report.url, jsonObject: payload) { response in
            var success = false
            defer { successful(success) }
            if let status = response?["status"] as? Int {
                if status == 200 || status == 400 {
                    for (actionID, actions) in reportCopy {
                        self[actionID]?.removeFirst(actions.count)
                    }
                    self.storage?.0.archive(self, forKey: self.storage!.1)
                    BKLog.debug(confirmed: "Sent report batch!")
                    success = true
                    return
                }
            }
            BKLog.debug(error: "Sending report batch failed")
        }.start()
    }
    
    override var count: Int {
        var count = 0
        queue.sync {
            count = values.reduce(0, {$0 + $1.count})
        }
        return count
    }
}


