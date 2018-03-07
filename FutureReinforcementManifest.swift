//
//  FutureReinforcementManifest.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

struct FutureEventManifest {
    let actionID: String
    var knownReinforcements: [FutureReinforcement]
    
    init(_ actionID: String) {
        self.actionID = actionID
        self.knownReinforcements = []
        // look at version and laod
    }
}
