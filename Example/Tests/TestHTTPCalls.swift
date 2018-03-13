////
////  TestHTTPCalls.swift
////  BoundlessKit_Tests
////
////  Created by Akash Desai on 3/10/18.
////  Copyright © 2018 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import BoundlessKit
//
//class TestHTTPCalls: XCTestCase {
//    
//    override func setUp() {
//        super.setUp()
//        
//    }
//    
//    override func tearDown() {
//        
//        super.tearDown()
//    }
//    
//    
//    func testTrackAPICallMock() {
//        let client = BoundlessKitDelegate.init(properties: BoundlessProperties.fromFile!)
//        client.httpClient = MockHTTPClient()
//        let promise = expectation(description: "reached track api callback")
//        
//        client.syncTrackedActions {
//            promise.fulfill()
//        }
//        
//        waitForExpectations(timeout: 3)
//    }
//    
//    func testReportAPICallMock() {
//        let client = BoundlessKitDelegate.init(properties: BoundlessProperties.fromFile!)
//        client.httpClient = MockHTTPClient()
//        let promise = expectation(description: "reached report api callback")
//        
//        client.syncReportedActions {
//            promise.fulfill()
//        }
//        
//        waitForExpectations(timeout: 3)
//    }
//    
//    func testAPIRefreshCallMock() {
//        let client = BoundlessKitDelegate.init(properties: BoundlessProperties.fromFile!)
//        client.httpClient = MockHTTPClient()
//        let promise = expectation(description: "did get to send function")
//        
//        client.syncReinforcementDecisions(for: "a1") {
//            promise.fulfill()
//        }
//        
//        waitForExpectations(timeout: 3)
//    }
//    
//    func testRefreshAndReinforce() {
//        let client = BoundlessKitDelegate.init(properties: BoundlessProperties.fromFile!)
//        let kit = BoundlessKit()
//        let promise = expectation(description: "Different reinforcements")
//        
//        var reinforcement1: String?
//        var reinforcement2: String?
//        client.syncReinforcementDecisions(for: "a1") {
//            kit.launch(delegate: client)
//            
//            kit.reinforce(actionID: "a1") { reinforcement in
//                reinforcement1 = reinforcement
//                print("Got reinforcmement1:\(reinforcement)")
//                kit.reinforce(actionID: "a1") { reinforcement in
//                    reinforcement2 = reinforcement
//                    print("Got reinforcmement2:\(reinforcement)")
//                    if reinforcement1 != reinforcement2 {
//                        promise.fulfill()
//                    }
//                }
//            }
//        }
//        
//        waitForExpectations(timeout: 3)
//    }
//    
//}

