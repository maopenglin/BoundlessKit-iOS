//
//  BoundlessDecision.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal class BoundlessDecision : NSObject {
    
    static func neutral(for actionID: String) -> BoundlessDecision {
        return BoundlessDecision.init("neutralResponse", actionID)
    }
    
    let name: String
    let actionID: String
    
    init(_ name: String,
         _ actionID: String) {
        self.name = name
        self.actionID = actionID
    }
    
    var asReinforcement: BoundlessReinforcement {
        return BoundlessReinforcement.init(name, actionID)
    }
}

extension BoundlessDecision {
    
    var notification: Notification.Name {
        return NSNotification.Name.init(actionID + name)
    }
    
    func notifyObservers(userInfo: [AnyHashable : Any]?) {
        NotificationCenter.default.post(name: notification, object: nil, userInfo: userInfo)
        print("Posted notification with name:\(notification.rawValue)")
    }
    
}
