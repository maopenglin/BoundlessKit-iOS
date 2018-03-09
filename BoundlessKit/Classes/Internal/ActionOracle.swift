//
//  ActionOracle.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation


internal class ActionOracle : NSObject {
    
    let actionID: String
    var reinforcementDecisions: [BoundlessDecision]
    
    init(_ actionID: String, _ reinforcementDecisions: [BoundlessDecision]) {
        self.actionID = actionID
        self.reinforcementDecisions = reinforcementDecisions
    }

    func reinforce() -> BoundlessReinforcement {
        let decision: BoundlessDecision
        
        if let reinforcementDecision = reinforcementDecisions.first {
            reinforcementDecisions.remove(at: 0)
            decision = reinforcementDecision
        } else {
            decision = BoundlessDecision.neutral(for: actionID)
        }
        
        decision.notifyObservers(userInfo: nil)
        return decision.asReinforcement
    }
    
}
