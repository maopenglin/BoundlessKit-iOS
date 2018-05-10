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
    
}
