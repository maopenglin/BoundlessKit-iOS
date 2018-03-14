//
//  BKRefreshCartridge.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridge : SynchronizedArray<BKDecision>, NSCoding {
    
    static let registerWithNSKeyed: Void = {
        NSKeyedUnarchiver.setClass(BKRefreshCartridge.self, forClassName: "BKRefreshCartridge")
        NSKeyedArchiver.setClassName("BKRefreshCartridge", for: BKRefreshCartridge.self)
    }()
    
    let actionID: String
    var expirationUTC: Int64
    var desiredMinCountUntilSync: Int
    
    init(actionID: String,
         expirationUTC: Int64 = Int64(Date().timeIntervalSince1970),
         sizeUntilSync: Int = 2,
         values: [BKDecision] = []) {
        self.actionID = actionID
        self.expirationUTC = expirationUTC
        self.desiredMinCountUntilSync = sizeUntilSync
        super.init(values)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let actionID = aDecoder.decodeObject(forKey: "actionID") as? String,
            let arrayData = aDecoder.decodeObject(forKey: "arrayValues") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BKDecision] else {
                return nil
        }
        let expirationUTC = aDecoder.decodeInt64(forKey: "expirationUTC")
        let desiredMinCountUntilSync = aDecoder.decodeInteger(forKey: "desiredMinCountUntilSync")
        self.init(actionID: actionID,
                  expirationUTC: expirationUTC,
                  sizeUntilSync: desiredMinCountUntilSync,
                  values: arrayValues)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(actionID, forKey: "actionID")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: values), forKey: "arrayValues")
        aCoder.encode(expirationUTC, forKey: "expirationUTC")
        aCoder.encode(desiredMinCountUntilSync, forKey: "desiredMinCountUntilSync")
    }
    
    var needsSync: Bool {
        return count <= desiredMinCountUntilSync || Int64(1000*Date().timeIntervalSince1970) >= expirationUTC
    }
}



