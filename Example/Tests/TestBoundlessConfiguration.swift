//
//  TestBoundlessConfiguration.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 5/2/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestBoundlessConfiguration: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReinforcementEnabled() {
        let enabled = BoundlessConfiguration(reinforcementEnabled: true)
        let disabled = BoundlessConfiguration(reinforcementEnabled: false)
        let apiClient = MockCodelessAPIClient()
        
        let gotReward = expectation(description: "Got a reward")
        apiClient.boundlessConfig = enabled
        apiClient.refreshContainer.decision(forActionID: MockBKRefreshCartridge.actionID) { decision in
            if decision.name == MockBKRefreshCartridge.rewardID {
                gotReward.fulfill()
            } else {
                XCTFail()
            }
        }
        
        let gotNeutral = expectation(description: "Got neutral")
        apiClient.boundlessConfig = disabled
        apiClient.refreshContainer.decision(forActionID: MockBKRefreshCartridge.actionID) { decision in
            if decision.name == BKDecision.neutral {
                gotNeutral.fulfill()
            } else {
                XCTFail()
            }
        }
        
        let gotRewardAgain = expectation(description: "Got a reward after reenabling reinforcement")
        apiClient.boundlessConfig = enabled
        apiClient.refreshContainer.decision(forActionID: MockBKRefreshCartridge.actionID) { decision in
            if decision.name == MockBKRefreshCartridge.rewardID {
                gotRewardAgain.fulfill()
            } else {
                XCTFail()
            }
        }
        
        
        waitForExpectations(timeout: 3)
    }
    
}
