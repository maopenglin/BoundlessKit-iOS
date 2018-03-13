//
//  BKReportBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKReportBatch : SynchronizedDictionary<String, SynchronizedArray<BKReinforcement>>, NSCoding {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKReportBatch.self, forClassName: "BKReportBatch")
        NSKeyedArchiver.setClassName("BKReportBatch", for: BKReportBatch.self)
    }()
    
    var apiClient: BoundlessAPIClient?
    
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxSizeUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         dict: [String: [BKReinforcement]] = [:]) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxSizeUntilSync = sizeUntilSync
        super.init(dict.mapValues({ (reinforcements) -> SynchronizedArray<BKReinforcement> in
            return SynchronizedArray(reinforcements)
        }))
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: [BKReinforcement]] else {
                return nil
        }
        let desiredMaxTimeUntilSync = aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync")
        let desiredMaxSizeUntilSync = aDecoder.decodeInteger(forKey: "desiredMaxSizeUntilSync")
        self.init(timeUntilSync: desiredMaxTimeUntilSync,
                  sizeUntilSync: desiredMaxSizeUntilSync,
                  dict: dictValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self.valuesForKeys.mapValues({ (synchronizedArray) -> [BKReinforcement] in
            return synchronizedArray.values
        })), forKey: "dictValues")
        aCoder.encode(desiredMaxTimeUntilSync, forKey: "desiredMaxTimeUntilSync")
        aCoder.encode(desiredMaxSizeUntilSync, forKey: "desiredMaxSizeUntilSync")
    }
    
    func store(_ reinforcement: BKReinforcement) {
        if self[reinforcement.actionID] == nil {
            self[reinforcement.actionID] = SynchronizedArray()
        }
        self[reinforcement.actionID]?.append(reinforcement)
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                reinforcement.metadata[key] = value
            }
        }
    }
    
    var needsSync: Bool {
        if values.map({ report -> Int in
            return report.count
        }).reduce(0, +) >= desiredMaxSizeUntilSync {
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
    
    func sync(completion: @escaping ()->Void = {}) {
        guard var payload = apiClient?.properties.apiCredentials else {
                completion()
                return
        }
        
        let reportCopy = self.valuesForKeys
        payload["actions"] = reportCopy.values.flatMap({$0.values}).map({$0.toJSONType()})
        apiClient?.post(url: BoundlessAPIEndpoint.track.url, jsonObject: payload) { response in
            if let status = response?["status"] as? Int {
                if status == 200 || status == 400 {
                    for (actionID, actions) in reportCopy {
                        self[actionID]?.removeFirst(actions.count)
                    }
                    print("Cleared reported actions.")
                }
            }
            completion()
        }.start()
    }
    
//    func syncReport(forActionID actionID: String, completion: @escaping ()->Void = {}) {
//        guard var payload = apiClient?.properties.apiCredentials,
//            let actions = self[actionID]?.values else {
//                completion()
//                return
//        }
//
//
//        payload["actions"] = actions.map({ (reinforcement) -> [String: Any] in
//            reinforcement.toJSONType()
//        })
//        apiClient?.httpClient.post(url: BoundlessAPI.track.url, jsonObject: payload) { response in
//            if let status = response?["status"] as? Int {
//                if status == 200 || status == 400 {
//                    self.removeValue(forKey: actionID)
//                    print("Cleared reported actions.")
//                }
//            }
//            completion()
//        }.start()
//    }
    
}


