//
//  BKReportBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKReportBatch : SynchronizedDictionary<String, SynchronizedArray<BoundlessReinforcement>>, NSCoding {
    
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxSizeUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         dict: [String: [BoundlessReinforcement]] = [:]) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxSizeUntilSync = sizeUntilSync
        super.init(dict.mapValues({ (reinforcements) -> SynchronizedArray<BoundlessReinforcement> in
            return SynchronizedArray(reinforcements)
        }))
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "dictValues") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: [BoundlessReinforcement]] else {
                return nil
        }
        let desiredMaxTimeUntilSync = aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync")
        let desiredMaxSizeUntilSync = aDecoder.decodeInteger(forKey: "desiredMaxSizeUntilSync")
        self.init(timeUntilSync: desiredMaxTimeUntilSync,
                  sizeUntilSync: desiredMaxSizeUntilSync,
                  dict: dictValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(desiredMaxSizeUntilSync, forKey: "desiredMaxSizeUntilSync")
        aCoder.encode(desiredMaxSizeUntilSync, forKey: "desiredMaxSizeUntilSync")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: copy()), forKey: "dictValues")
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
    
    func add(reinforcement: BoundlessReinforcement) {
        if self[reinforcement.actionID] == nil {
            self[reinforcement.actionID] = SynchronizedArray()
        }
        self[reinforcement.actionID]?.append(reinforcement)
    }
    
}


