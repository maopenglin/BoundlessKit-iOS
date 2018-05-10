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
        
    }
    
    func testActionOracleWithFutureReinforcements() {
        
    }
    
    
    
    func testCodelessReinforcementParse() {
        let reinforcementString = "{"
            + "\"primitive\": \"Emojisplosion\","
            + "\"SystemSound\": 1109,"
            + "\"HapticFeedback\": true,"
            + "\"Delay\": 0,"
            + "\"ViewCustom\": \"\","
            + "\"ViewMarginY\": 0.5,"
            + "\"ViewMarginX\": 0.5,"
            + "\"ViewOption\": \"sender\","
            + "\"AccelY\": -200,"
            + "\"AccelX\": 0,"
            + "\"ScaleSpeed\": 0.5,"
            + "\"ScaleRange\": 0.2,"
            + "\"Scale\": 1,"
            + "\"Bursts\": 1,"
            + "\"FadeOut\": 1,"
            + "\"Spin\": 20,"
            + "\"EmissionRange\": 45,"
            + "\"EmissionAngle\": 90,"
            + "\"LifetimeRange\": 0.5,"
            + "\"Lifetime\": 2,"
            + "\"Quantity\": 1,"
            + "\"Velocity\": 20,"
            + "\"Content\": \"👍\"" +
        "}"
        
        let cr = try! CodelessReinforcement(from: JSONSerialization.jsonObject(with: reinforcementString.data(using: .utf8)!) as! [String: Any])
        
        let promise = expectation(description: "Show reward")
        cr!.show(targetInstance: UIWindow.topWindow!, senderInstance: UIWindow.topWindow!) {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
}

