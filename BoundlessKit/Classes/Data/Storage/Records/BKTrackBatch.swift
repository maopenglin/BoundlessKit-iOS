//
//  BKTrackBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKTrackBatch : SynchronizedArray<BKAction>, NSCoding {
    
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxSizeUntilSync: Int
    
    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         values: [BKAction] = []) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxSizeUntilSync = sizeUntilSync
        super.init(values)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let arrayData = aDecoder.decodeObject(forKey: "arrayValues") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BKAction] else {
                return nil
        }
        let desiredMaxTimeUntilSync = aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync")
        let desiredMaxSizeUntilSync = aDecoder.decodeInteger(forKey: "desiredMaxSizeUntilSync")
        self.init(timeUntilSync: desiredMaxTimeUntilSync,
                  sizeUntilSync: desiredMaxSizeUntilSync,
                  values: arrayValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(desiredMaxSizeUntilSync, forKey: "desiredMaxSizeUntilSync")
        aCoder.encode(desiredMaxSizeUntilSync, forKey: "desiredMaxSizeUntilSync")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: values), forKey: "arrayValues")
    }
    
    var needsSync: Bool {
        if count >= desiredMaxSizeUntilSync {
            return true
        }
        
        if let startTime = self.first?.utc {
            return Int64(1000*NSDate().timeIntervalSince1970) >= (startTime + desiredMaxTimeUntilSync)
        }
        
        return false
    }
    
//    func add(action: BKAction) {
//        self.append(action)
//    }
    
    
}
