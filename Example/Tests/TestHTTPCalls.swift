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
        let properites = BoundlessProperties.fromFile!
        let api = BoundlessAPI.init(properties: properites, httpClient: MockHTTPClient())
        let client = BoundlessKitClient.init(properties: BoundlessProperties.fromFile!)
        client.syncTrackedActions()
        let promise = expectation(description: "reached track api callback")
        api.send(actions: [[String : Any]]()) { (result) in
            print("In here with result:\(result)")
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReportAPICallMock() {
        let properites = BoundlessProperties.fromFile!
        let api = BoundlessAPI.init(properties: properites, httpClient: MockHTTPClient())
        let promise = expectation(description: "reached report api callback")
        api.send(reinforcements: [[String : Any]]()) { (result) in
            print("In here with result:\(result)")
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testAPIRefreshCall() {
        let properites = BoundlessProperties.fromFile!
        let api = BoundlessAPI.init(properties: properites)
        
        let promise = expectation(description: "did get to send function")
        api.refresh(actionID: "a1") { result in
            print("Got result:\(result)")
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testRefreshAndReinforce() {
        let properites = BoundlessProperties.fromFile!
        let api = BoundlessAPI.init(properties: properites)
        let client = BoundlessKitClient.init(boundlessAPI: api)
        let kit = BoundlessKit()
        
        let promise = expectation(description: "Different reinforcements")
        var reinforcement1: String?
        var reinforcement2: String?
        
        client.syncReinforcementDecisions(for: "a1") {
            kit.launch(delegate: client, dataSource: client)
            
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
