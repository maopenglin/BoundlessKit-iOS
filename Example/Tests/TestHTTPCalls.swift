//
//  TestHTTPCalls.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestHTTPCalls: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    
    func testTrackAPICallMock() {
        let kit = MockBoundlessKit()
        let promise = expectation(description: "reached track api callback")
        
        kit.trackBatch.sync {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReportAPICallMock() {
        let kit = MockBoundlessKit()
        let promise = expectation(description: "reached report api callback")
        
        kit.reportBatch.sync {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testAPIRefreshCallMock() {
        let kit = MockBoundlessKit()
        let promise = expectation(description: "did get to send function")
        
        kit.refreshContainer.refresh(actionID: "a1") {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testRefreshAndReinforceReal() {
        let kit = BoundlessKit()
        let promise = expectation(description: "Different reinforcements")
        
        var reinforcement1: String?
        var reinforcement2: String?
        kit.refreshReinforcements(forActionID: "a1") {
            kit.reinforce(actionID: "a1") { reinforcement in
                reinforcement1 = reinforcement
                print("Got reinforcmement1:\(reinforcement)")
                kit.reinforce(actionID: "a1") { reinforcement in
                    reinforcement2 = reinforcement
                    print("Got reinforcmement2:\(reinforcement)")
                    if reinforcement1 != reinforcement2 {
                        promise.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
}

