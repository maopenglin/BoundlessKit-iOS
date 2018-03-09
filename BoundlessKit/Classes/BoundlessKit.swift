//
//  BoundlessKit.swift
//  BoundlessKit
//
//  Created by Akash Desai on 4/7/16.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//



import Foundation


public protocol BoundlessKitDataSource {
    func kitActionIDs() -> [String]
    func kitReinforcements(for actionID: String) -> [String]
}
public protocol BoundlessKitDelegate {
    func kitPublish(actionInfo: [String:Any])
    func kitPublish(reinforcementInfo: [String:Any])
}

public class BoundlessKit : NSObject {
    
    var delegate: BoundlessKitDelegate?
    var dataSource: BoundlessKitDataSource?
    
    var actionOracles = [String: ActionOracle]()
    var codelessVisuals = [CodelessVisual]()
    
    public func launch(delegate: BoundlessKitDelegate, dataSource: BoundlessKitDataSource, arguements: [String: Any]) {
        self.delegate = delegate
        self.dataSource = dataSource
        
        for actionID in dataSource.kitActionIDs() {
            let reinforcements = dataSource.kitReinforcements(for: actionID).map({ (reinforcementID) -> BoundlessReinforcement in
                return BoundlessReinforcement.init(reinforcementID, actionID)
            })
            actionOracles[actionID] = ActionOracle.init(actionID, reinforcements)
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
        let oracle: ActionOracle
        if let actionOracle = actionOracles[action.name] {
            oracle = actionOracle
        } else {
            oracle = ActionOracle(action.name, [])
            actionOracles[action.name] = oracle
        }
        return oracle.reinforce()
    }
    
    
}

