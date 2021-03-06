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
        
        let previousTrackCount = kit.apiClient.version.trackBatch.count
        
        kit.track(actionID: "track1")
        kit.track(actionID: "track2")
        
        XCTAssert(kit.apiClient.version.trackBatch.count == previousTrackCount + 2)
    }
    
    func testSavedData() {
        let properties = BoundlessProperties.fromTestFile()!
        
        let client = BoundlessAPIClient(credentials: properties.credentials, version: properties.version)
        let kit = MockBoundlessKit.init(apiClient: client)
        kit.track(actionID: "track1")
        
        let client2 = BoundlessAPIClient(credentials: properties.credentials, version: properties.version)
        let kit2 = MockBoundlessKit.init(apiClient: client2)
        
        XCTAssert(kit2.apiClient.version.trackBatch.count == kit.apiClient.version.trackBatch.count)
    }
    
    
    
}

