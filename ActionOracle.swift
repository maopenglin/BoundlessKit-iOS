//
//  ActionOracle.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation


class ActionOracle : NSObject {
    
    let actionID: String
    var manifest: FutureEventManifest
    var futureReinforcements: [FutureReinforcement]
    
    init(_ actionID: String) {
        self.actionID = actionID
        self.manifest = FutureEventManifest.init(actionID)
        self.futureReinforcements = []
        // look at storage and load
    }

    func reinforce() -> BoundlessReinforcement {
        if let futureReinforcement = futureReinforcements.first {
            futureReinforcements.remove(at: 0)
            futureReinforcement.use()
            return futureReinforcement.reinforcement
        } else if let futureReinforcement = manifest.knownReinforcements.first {
            futureReinforcement.use()
            return futureReinforcement.reinforcement
        } else {
            // request futures refresh
            let future = FutureReinforcement.defaultFor(actionID: actionID)
            future.use()
            return future.reinforcement
        }
    }
}


struct FutureEventManifest {
    let actionID: String
    var knownReinforcements: [FutureReinforcement]
    
    init(_ actionID: String) {
        self.actionID = actionID
        self.knownReinforcements = []
        // look at version and laod
    }
}

struct FutureReinforcement {
    
    static func defaultFor(actionID: String) -> FutureReinforcement {
        return FutureReinforcement(actionID, BoundlessReinforcement(name: "neutralResponse"))
    }
    
    let actionID: String
    let reinforcement: BoundlessReinforcement
    
    init(_ actionID: String, _ reinforcement: BoundlessReinforcement) {
        self.actionID = actionID
        self.reinforcement = reinforcement
    }
    var notification: Notification.Name { return NSNotification.Name.init(actionID + reinforcement.name) }
    func use() {
        NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
        print("Posted notification with name:\(notification.rawValue)")
        // store reinforcement
    }
}
