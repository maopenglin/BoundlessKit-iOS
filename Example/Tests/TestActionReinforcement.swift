//
//  TestActionReinforcement.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestActionReinforcement: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testActionOracleWithoutReinforcements() {
        let actionID = "testAction1"
        
        let oracle = ActionOracle.init(actionID, [])
        
        XCTAssert(oracle.reinforce().name == BoundlessDecision.neutral(for: actionID).name)
        sleep(1)
    }
    
    func testActionOracleWithFutureReinforcements() {
        let actionID = "testAction1"
        let reinforcementID1 = "testReinforcement1"
        let reinforcementID2 = "testReinforcement2"
        
        let oracle = ActionOracle.init(actionID, [
            BoundlessDecision.init(reinforcementID1, actionID),
            BoundlessDecision.init(reinforcementID2, actionID)
            ])
        
        XCTAssert(oracle.reinforce().name == reinforcementID1)
        XCTAssert(oracle.reinforce().name == reinforcementID2)
    }
    
    
    
}
