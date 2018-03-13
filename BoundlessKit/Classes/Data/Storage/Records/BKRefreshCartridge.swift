//
//  BKRefreshCartridge.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridge : SynchronizedArray<BoundlessDecision>, NSCoding {
    
    let expirationUTC: Int64
    var desiredMinSizeUntilSync: Int
    
    init(expirationUTC: Int64 = Int64(Date().timeIntervalSince1970),
         sizeUntilSync: Int = 2,
         values: [BoundlessDecision] = []) {
        self.expirationUTC = expirationUTC
        self.desiredMinSizeUntilSync = sizeUntilSync
        super.init(values)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let arrayData = aDecoder.decodeObject(forKey: "arrayValues") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BoundlessDecision] else {
                return nil
        }
        let expirationUTC = aDecoder.decodeInt64(forKey: "expirationUTC")
        let desiredMinSizeUntilSync = aDecoder.decodeInteger(forKey: "desiredMinSizeUntilSync")
        self.init(expirationUTC: expirationUTC,
                  sizeUntilSync: desiredMinSizeUntilSync,
                  values: arrayValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(expirationUTC, forKey: "expirationUTC")
        aCoder.encode(desiredMinSizeUntilSync, forKey: "desiredMinSizeUntilSync")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: values), forKey: "arrayValues")
    }
    
    var needsSync: Bool {
        return count <= desiredMinSizeUntilSync || Int64(1000*Date().timeIntervalSince1970) >= expirationUTC
    }
    
}



