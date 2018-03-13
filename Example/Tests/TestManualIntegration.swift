////
////  TestManualIntegration.swift
////  BoundlessKit_Tests
////
////  Created by Akash Desai on 3/8/18.
////  Copyright © 2018 CocoaPods. All rights reserved.
////
//
//import XCTest
//@testable import BoundlessKit
//
//class TestManualIntegration: XCTestCase {
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
//    func testAddAction() {
//        let client = MockBoundlessKitClient.init(properties: BoundlessProperties.fromFile!)
//        client.httpClient = MockHTTPClient()
//        client.clearData()
//        let kit = BoundlessKit.init()
//        
//        let promise = expectation(description: "added 2 tracks")
//        let previousTrackCount = client.trackedActions.count
//        
//        promise.assertForOverFulfill = false
//        client.onPublishTrack = {
//            print("Track count:\(client.trackedActions.count)")
//            if client.trackedActions.count == previousTrackCount + 2 {
//                promise.fulfill()
//            }
//        }
//        
//        kit.launch(delegate: client)
//        kit.track(actionID: "track1")
//        kit.track(actionID: "track2")
//        
//        waitForExpectations(timeout: 3)
//    }
//    
//    func testSavedData() {
//        let client = MockBoundlessKitClient(properties: nil)
//        client.clearData()
//        let kit = BoundlessKit.init()
//        
//        let didTrackAction = expectation(description: "tracked action")
//        client.onPublishTrack = {
//            client.saveData()
//            didTrackAction.fulfill()
//        }
//        
//        kit.launch(delegate: client)
//        kit.track(actionID: "track1")
//        
//        waitForExpectations(timeout: 3)
//        
//        
//        let client2 = MockBoundlessKitClient(properties: nil)
//        client2.loadData()
//        XCTAssert(client2.trackedActions.count == client.trackedActions.count)
//        
//    }
//    
//    
//    
//}

