//
//  BKRefreshCartridges.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridges : SynchronizedDictionary<String, BKRefreshCartridge>, NSCoding {
    
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
