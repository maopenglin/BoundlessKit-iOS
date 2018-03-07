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
//            if (true /*actionID is instance method*/) {
//                let instanceMethodCallListener = InstanceMethodCallListener(actionID: actionID)
//                instanceMethodCallListeners[actionID] = instanceMethodCallListener
//            }
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
    
    public func track(actionID: String) {
        _ = BoundlessAction(actionID)
    }
    
    public func reinforce(actionID: String) -> String {
        if let oracle = actionOracles[actionID] {
            return oracle.reinforce().name
        } else {
            let actionOracle = ActionOracle(actionID)
            actionOracles[actionID] = actionOracle
            return actionOracle.reinforce().name
        }
    }
    
    
}


struct BoundlessAction {
    let name: String
    init(_ name: String) {
        self.name = name
    }
}

struct BoundlessReinforcement {
    let name: String
    init(_ name: String) {
        self.name = name
    }
}

