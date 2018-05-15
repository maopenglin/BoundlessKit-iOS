//
//  MockBKRefreshCartridge.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 5/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBKRefreshCartridge : BKRefreshCartridge {
    
    static var actionID = "action"
    static var nuetralID = "nuetral"
    static var rewardID = "reward"
    
    static var allRewards: BKRefreshCartridge {
        return BKRefreshCartridge.init(cartridgeID: "TEST", actionID: actionID, values: Array(repeating: BKDecision(rewardID, "TEST", actionID), count: 10))
    }
    
    var _needsSync: Bool = false
    override var needsSync: Bool {
        return _needsSync
    }
    
}
