//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//



import Foundation


class BoundlessKit : NSObject, BoundlessActionResponder {
    var instanceMethodCallListeners: [String:InstanceMethodCallListener] = [:]
    var actionOracles: [String:BoundlessActionOracle] = [:]
    var actionReinforcementResponders: [String: [String: BoundlessReinforcementResponder]] = [:]
    
    func launch() {
        BoundlessAction.responder = self
        let mappings = [String: [String:Any]]()
        for (key, value) in mappings {
            let actionOracle = BoundlessActionOracle(actionID: key)
            actionOracles[key] = actionOracle
            if (true /*actionID is instance method*/) {
                let instanceMethodCallListener = InstanceMethodCallListener(actionID: key)
                instanceMethodCallListeners[key] = instanceMethodCallListener
            }
            if (true /*value is codeless reinforcement*/) {
                if let codelessReinforcements = value[key] as? [[String: Any]] {
                    for _ in codelessReinforcements {
                        let reinforcement = CodelessReinforcement(primitive:"confetti")
                        if actionReinforcementResponders[key] == nil {
                            actionReinforcementResponders[key] = [reinforcement.primitive:reinforcement]
                        } else {
                            actionReinforcementResponders[key]![reinforcement.primitive] = reinforcement
                        }
                    }
                }
            }
        }
    }
    
    func track(actionID: String) {
        _ = BoundlessAction.create(name: actionID)
    }
    
    func reinforce(actionID: String, completion: ((String) -> ())? = nil) {
        _ = BoundlessAction.create(name: actionID, shouldReinforce: {(action, reinforcement) in
            completion?(reinforcement.name)
        })
    }
    
    func on(action: BoundlessAction, shouldReinforce: ShouldReinforce) {
        if shouldReinforce != nil || actionReinforcementResponders[action.name] != nil,
            let actionOracle = actionOracles[action.name] {
            let reinforcement = BoundlessReinforcement(name: actionOracle.reinforcementDecision())
            shouldReinforce?((action, reinforcement))
            actionReinforcementResponders[action.name]?[reinforcement.name]?.on(actionReinforcement: (action,reinforcement))
        }
    }
    
}

class InstanceMethodCallListener : NSObject {
    let actionID: String
    init(actionID: String) {
        self.actionID = actionID
    }
}

struct CodelessReinforcement : BoundlessReinforcementResponder {
    let primitive: String
    func on(actionReinforcement: ActionReinforcement) { }
}

typealias ActionReinforcement = (BoundlessAction, BoundlessReinforcement)
typealias ShouldReinforce = ((ActionReinforcement) ->())?

protocol BoundlessActionResponder {
    func on(action: BoundlessAction, shouldReinforce: ShouldReinforce)
}
struct BoundlessAction {
    static var responder: BoundlessActionResponder?
    let name: String
    private init(_ name: String) {
        self.name = name
    }
    static func create(name: String, shouldReinforce: ShouldReinforce = nil) -> BoundlessAction {
        let action = BoundlessAction(name)
        BoundlessAction.responder?.on(action: action, shouldReinforce: shouldReinforce)
        return action
    }
}

protocol BoundlessReinforcementResponder {
    func on(actionReinforcement: ActionReinforcement)
}
struct BoundlessReinforcement {
    let name: String
}


class BoundlessActionOracle : NSObject {
    let actionID: String
    init(actionID: String) {
        self.actionID = actionID
    }
    
    func reinforcementDecision() -> String {
        return "reward"
    }
}
