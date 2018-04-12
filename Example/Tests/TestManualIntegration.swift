//
//  TestManualIntegration.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestManualIntegration: XCTestCase {
    
    override func setUp() {
        super.setUp()
        BKUserDefaults.standard.removePersistentDomain()
        BKUserDefaults.standardTest.removePersistentDomain()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testAddAction() {
        let kit = MockBoundlessKit()
        
        let previousTrackCount = kit.trackBatch.count
        
        kit.track(actionID: "track1")
        kit.track(actionID: "track2")
        
        XCTAssert(kit.trackBatch.count == previousTrackCount + 2)
    }
    
    func testSavedData() {
        let mockDatabase = MockBKDatabase()
        
        let kit = MockBoundlessKit.init(database: mockDatabase)
        kit.track(actionID: "track1")
        
        let kit2 = MockBoundlessKit.init(database: mockDatabase)
        XCTAssert(kit2.trackBatch.count == kit.trackBatch.count)
    }
    
    
    
}

