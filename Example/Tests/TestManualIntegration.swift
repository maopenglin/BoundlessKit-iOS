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
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testAddAction() {
        let kit = MockBoundlessKit()
        
        let previousTrackCount = kit.apiClient.trackBatch.count
        
        kit.track(actionID: "track1")
        kit.track(actionID: "track2")
        
        XCTAssert(kit.apiClient.trackBatch.count == previousTrackCount + 2)
    }
    
    func testSavedData() {
        let database = MockBKuserDefaults()
        
        let client = BoundlessAPIClient(credentials: BoundlessCredentials.fromTestFile!, database: database)
        let kit = MockBoundlessKit.init(apiClient: client)
        kit.track(actionID: "track1")
        
        let client2 = BoundlessAPIClient(credentials: BoundlessCredentials.fromTestFile!, database: database)
        let kit2 = MockBoundlessKit.init(apiClient: client2)
        
        XCTAssert(kit2.apiClient.trackBatch.count == kit.apiClient.trackBatch.count)
    }
    
    
    
}

