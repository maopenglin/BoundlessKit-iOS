//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//



import Foundation


public protocol BoundlessKitDataSource {
    func kitActions() -> [String]
    func kitReinforcements(for action: String) -> [String]
}
public protocol BoundlessKitDelegate {
    func kitPublish(actionInfo: [String:Any])
    func kitPublish(reinforcementInfo: [String:Any])
}

public class BoundlessKit : NSObject {
    
    var delegate: BoundlessKitDelegate?
    var dataSource: BoundlessKitDataSource?
    
    var actionOracles = [String: ActionOracle]()
    
    public func launch(delegate: BoundlessKitDelegate, dataSource: BoundlessKitDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
        
        for actionID in dataSource.kitActions() {
            let reinforcements = dataSource.kitReinforcements(for: actionID).map({ (reinforcementID) -> BoundlessDecision in
                return BoundlessDecision.init(reinforcementID, actionID)
            })
            actionOracles[actionID] = ActionOracle.init(actionID, reinforcements)
        }
    }
    
    @objc
    public func track(actionID: String, metadata: [String: Any] = [:]) {
        let action = BoundlessAction(actionID, metadata)
        print("Adding context to tracked action <\(actionID)>")
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                action.metadata[key] = value
            }
            print("Publishing tracked action <\(actionID)>...")
            self.delegate?.kitPublish(actionInfo: action.toJSONType())
        }
    }
    
    @objc
    public func reinforce(actionID: String, completion: @escaping (String)->Void ) {
        let action = BoundlessAction(actionID)
        let reinforcementID = reinforce(action: action).name
        completion(reinforcementID)
    }
    internal func reinforce(action: BoundlessAction) -> BoundlessReinforcement {
        let oracle: ActionOracle
        if let actionOracle = actionOracles[action.name] {
            oracle = actionOracle
        } else {
            oracle = ActionOracle(action.name, [])
            actionOracles[action.name] = oracle
        }
        let reinforcement = oracle.reinforce()
        BoundlessContext.getContext() { contextInfo in
            for (key, value) in contextInfo {
                reinforcement.metadata[key] = value
            }
            self.delegate?.kitPublish(reinforcementInfo: reinforcement.toJSONType())
        }
        
        return reinforcement
    }
    
    
}

