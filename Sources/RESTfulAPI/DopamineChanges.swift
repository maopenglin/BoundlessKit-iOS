//
//  DopamineChanges.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

public protocol DopamineChangesDelegate {
    func attemptingReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String)
    func reinforcing(actionID: String, with reinforcementDecision: String)
}

open class DopamineChanges : NSObject {
    
    open static let shared = DopamineChanges()
    
    open var delegate: DopamineChangesDelegate? {
        didSet {
            print("Did set delegate")
        }
    }
    
    public override init() {
        super.init()
    }
    
    open func setSwizzling(_ enable: Bool) {
        UserDefaults.dopamine.setValue(!enable, forKey: "disableSwizzlingForAll")
        DTMethodSwizzling.swizzleSelectedMethods()
    }
}
