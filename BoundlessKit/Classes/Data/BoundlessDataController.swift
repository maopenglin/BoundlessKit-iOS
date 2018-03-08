//
//  BoundlessDataController.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation


protocol BoundlessData : NSCoding {}

class BoundlessDataController : NSObject {
    
    var trackedActions = [BoundlessAction]()
    var reportedActions = [BoundlessAction]()
    var cartridgeReinforcements = [String:[BoundlessReinforcement]]()
    let d = UIViewController()
}

class DefaultsDataController : BoundlessDataController {
    
}
