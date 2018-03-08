//
//  ActionOracle.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation


internal class ActionOracle : NSObject {
    
    let actionID: String
    var futureReinforcements: [BoundlessReinforcement]
    
    init(_ actionID: String, _ futureReinforcements: [BoundlessReinforcement]) {
        self.actionID = actionID
        self.futureReinforcements = futureReinforcements
    }

    func reinforce() -> BoundlessReinforcement {
        let reinforcement: BoundlessReinforcement
        
        if let futureReinforcement = futureReinforcements.first {
            futureReinforcements.remove(at: 0)
            reinforcement = futureReinforcement
        } else {
            reinforcement = BoundlessReinforcement.neutral(for: actionID)
        }
        
        reinforcement.notifyObservers()
        return reinforcement
    }
}
