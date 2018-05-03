//
//  TestTrackBatch.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 5/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestTrackBatch: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStore() {
        let trackBatch = BKTrackBatch()
        trackBatch.store(BKAction("action"))
        
        XCTAssert(trackBatch.count == 1)
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
        
        let _ = try! CodelessReinforcement(from: JSONSerialization.jsonObject(with: reinforcementString.data(using: .utf8)!) as! [String: Any])
    }
    
}
