//
//  MockCartridge.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import DopamineKit

extension Cartridge {
    
    static var mockGoodActionID: String { return "action1" }
    static var mockGoodReinforcementID: String { return "Confetti" }
    static var mockGoodCartridgeResponse: [String: Any] { return
        [ "status": 200,
          "expiresIn": 86400000,
          "reinforcementCartridge": [ mockGoodReinforcementID,
                                      defaultReinforcementDecision,
                                      mockGoodReinforcementID,
                                      defaultReinforcementDecision,
                                      mockGoodReinforcementID,
                                      defaultReinforcementDecision,
                                      mockGoodReinforcementID,
                                      defaultReinforcementDecision,
                                      mockGoodReinforcementID,
                                      defaultReinforcementDecision
            ]
        ]
    }
    
    static var mockBadActionID: String { return "someUnpublishedAction" }
    static var mockBadCartridgeResponse: [String: Any] { return
        [ "status": 400 ]
    }
}
