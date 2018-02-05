//
//  DopamineChanges.swift
//  DopamineKit
//
//  Created by Akash Desai on 1/28/18.
//

import Foundation

protocol DopamineChangesDelegate {
    func attemptingReinforcement()
    func showingReward()
}

open class DopamineChanges : NSObject {
    
    open static let shared = DopamineChanges()
    var delegate: DopamineChangesDelegate? {
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
