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
