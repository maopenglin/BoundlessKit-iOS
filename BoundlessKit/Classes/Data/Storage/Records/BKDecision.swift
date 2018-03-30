//
//  BKDecision.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal class BKDecision : NSObject, BKData {
    
    static func neutral(for actionID: String) -> BKDecision {
        return BKDecision.init("neutralResponse", actionID)
    }
    
    let name: String
    let actionID: String
    
    init(_ name: String,
         _ actionID: String) {
        self.name = name
        self.actionID = actionID
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let actionID = aDecoder.decodeObject(forKey: "actionID") as? String else {
                return nil
        }
        self.init(name,
                  actionID)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(actionID, forKey: "actionID")
    }
}
