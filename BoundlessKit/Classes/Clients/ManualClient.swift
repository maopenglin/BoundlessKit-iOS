//
//  ManualClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation


class ManualClient : NSObject {
    
}

extension ManualClient : BoundlessKitDataSource, BoundlessKitDelegate {
    func kitActions() -> [String] {
        return ["action1"]
    }
    
    func kitReinforcements(for actionID: String) -> [String] {
        return ["reward1", "reward2"]
    }
    
    func kitPublish(actionInfo: [String : Any]) {
        
    }
    
    func kitPublish(reinforcementInfo: [String : Any]) {
        
    }
    
    
}
