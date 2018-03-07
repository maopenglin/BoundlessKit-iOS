//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//



import Foundation


public class BoundlessKit : NSObject {
    
    var actionOracles = [String: ActionOracle]()
    var codelessVisuals = [CodelessVisual]()
    
    public func launch(arguements: [String: Any]) {
        if let mappings = arguements["mappings"] as? [String: [String: Any]] {
            for (actionID, value) in mappings {
                let actionOracle = ActionOracle(actionID)
                actionOracles[actionID] = actionOracle
                if let observer = InstanceMethodSwizzle.init(actionID: actionID) {
                    observer.register()
                }
                if let codeless = value["codeless"] as? [String: Any],
                    let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                    for reinforcementDict in reinforcements {
                        if let codelessVisual = CodelessVisual.convert(from: reinforcementDict) {
                            let futureReinforcement = FutureReinforcement.init(actionID, BoundlessReinforcement.init(codelessVisual.primitive))
                            print("Future reinforcement:\(futureReinforcement.notification.rawValue)")
                            codelessVisual.register(for: futureReinforcement)
                            actionOracle.manifest.knownReinforcements.append(futureReinforcement)
                            codelessVisuals.append(codelessVisual)
                        }
                    }
                }
            }
        }
    }
    
    @objc
    public func track(actionID: String) {
        let action = BoundlessAction(actionID)
        BoundlessAction.addContext(to: action)
    }
    
    @objc
    public func reinforce(actionID: String) -> String {
        let action = BoundlessAction(actionID)
        BoundlessAction.addContext(to: action)
        return reinforce(action: action).name
    }
    internal func reinforce(action: BoundlessAction) -> BoundlessReinforcement {
        let reinforcement: BoundlessReinforcement
        if let oracle = actionOracles[action.name] {
            reinforcement = oracle.reinforce()
        } else {
            let actionOracle = ActionOracle(action.name)
            actionOracles[action.name] = actionOracle
            reinforcement = actionOracle.reinforce()
        }
        return reinforcement
    }
    
    
}

