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
        let reinforcementString = "{\n              \"primitive\": \"Emojisplosion\",\n              \"SystemSound\": 1109,\n              \"HapticFeedback\": true,\n              \"Delay\": 0,\n              \"ViewCustom\": \"\",\n              \"ViewMarginY\": 0.5,\n              \"ViewMarginX\": 0.5,\n              \"ViewOption\": \"sender\",\n              \"AccelY\": -200,\n              \"AccelX\": 0,\n              \"ScaleSpeed\": 0.5,\n              \"ScaleRange\": 0.2,\n              \"Scale\": 1,\n              \"Bursts\": 1,\n              \"FadeOut\": 1,\n              \"Spin\": 20,\n              \"EmissionRange\": 45,\n              \"EmissionAngle\": 90,\n              \"LifetimeRange\": 0.5,\n              \"Lifetime\": 2,\n              \"Quantity\": 1,\n              \"Velocity\": 20,\n              \"Content\": \"👍\"\n            }"
        
        let _ = try! CodelessReinforcement(from: JSONSerialization.jsonObject(with: reinforcementString.data(using: .utf8)!) as! [String: Any])
    }
    
}
