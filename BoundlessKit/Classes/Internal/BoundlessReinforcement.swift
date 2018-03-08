//
//  BoundlessReinforcement.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BoundlessReinforcement : NSObject {
    
    static func neutral(for actionID: String) -> BoundlessReinforcement {
        return BoundlessReinforcement.init("neutralResponse", actionID)
    }
    
    let name: String
    let actionID: String
    
    
    var notification: Notification.Name {
        return NSNotification.Name.init(actionID + name)
    }
    
    init(_ name: String, _ actionID: String) {
        self.name = name
        self.actionID = actionID
    }
    
    func notifyObservers() {
        NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
        print("Posted notification with name:\(notification.rawValue)")
    }
}
