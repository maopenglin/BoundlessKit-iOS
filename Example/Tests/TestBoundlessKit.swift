//
//  TestBoundlessKit.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestBoundlessKit: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrack() {
        let actionID = "testTrack1"
        
        let kit = BoundlessKit.init()
        kit.track(actionID: actionID)
        
        sleep(1)
        
    }
    
}
