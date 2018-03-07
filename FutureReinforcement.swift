//
//  FutureReinforcement.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

struct FutureReinforcement {
    
    static func defaultFor(actionID: String) -> FutureReinforcement {
        return FutureReinforcement(actionID, BoundlessReinforcement("neutralResponse"))
    }
    
    let actionID: String
    let reinforcement: BoundlessReinforcement
    var notification: Notification.Name {
        return NSNotification.Name.init(actionID + reinforcement.name)
    }
    
    init(_ actionID: String, _ reinforcement: BoundlessReinforcement) {
        self.actionID = actionID
        self.reinforcement = reinforcement
    }
    
    
    func use() {
        NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
        print("Posted notification with name:\(notification.rawValue)")
    }
}
