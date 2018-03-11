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
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testAddAction() {
        let client = MockManualClient(boundlessAPI: nil)
        client.clearData()
        let kit = BoundlessKit.init()
        
        let promise = expectation(description: "added 2 tracks")
        let previousTrackCount = client.trackedActions.count
        
        promise.assertForOverFulfill = false
        client.onPublishTrack = {
            print("Track count:\(client.trackedActions.count)")
            if client.trackedActions.count == previousTrackCount + 2 {
                promise.fulfill()
            }
        }
        
        kit.launch(delegate: client, dataSource: client)
        kit.track(actionID: "track1")
        kit.track(actionID: "track2")
        
        waitForExpectations(timeout: 3)
    }
    
    func testSavedData() {
        let client = MockManualClient(boundlessAPI: nil)
        client.clearData()
        let kit = BoundlessKit.init()
        
        let didTrackAction = expectation(description: "tracked action")
        client.onPublishTrack = {
            client.saveData()
            didTrackAction.fulfill()
        }
        
        kit.launch(delegate: client, dataSource: client)
        kit.track(actionID: "track1")
        
        waitForExpectations(timeout: 3)
        
        
        let client2 = MockManualClient(boundlessAPI: nil)
        client2.loadData()
        XCTAssert(client2.trackedActions.count == client.trackedActions.count)
        
    }
    
    
    func testTrackAPICallMock() {
        let properites = BoundlessProperties.fromFile!
        let api = MockBoundlessAPI.init(properties: properites)
        let promise = expectation(description: "reached track api callback")
        api.send(actions: [[String : Any]]()) { (result) in
            print("In here with result:\(result)")
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testReportAPICallMock() {
        let properites = BoundlessProperties.fromFile!
        let api = MockBoundlessAPI.init(properties: properites)
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
        let client = ManualClient.init(boundlessAPI: api)
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
