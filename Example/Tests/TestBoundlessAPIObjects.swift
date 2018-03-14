//
//  TestBoundlessAPIObjects.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestBoundlessAPIObjects: XCTestCase {
    
    override func setUp() {
        super.setUp()
        BKUserDefaults.standard.removePersistentDomain()
        BKUserDefaults.standardTest.removePersistentDomain()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackEncodeAndDecode() {
        let database = BKUserDefaults.standardTest
        
        let encodedBatch = BKTrackBatch(values: [BKAction.init("track1")])
        database.archive(encodedBatch, forKey: "testTrackEncodeAndDecode")
        let decodedBatch: BKTrackBatch = database.unarchive("testTrackEncodeAndDecode")!
        
        XCTAssert(decodedBatch.count == encodedBatch.count)
        XCTAssert(decodedBatch.count == 1)
        XCTAssert(decodedBatch.desiredMaxTimeUntilSync == encodedBatch.desiredMaxTimeUntilSync)
        XCTAssert(decodedBatch.desiredMaxCountUntilSync == encodedBatch.desiredMaxCountUntilSync)
    }
    
    func testTrackStore() {
        let batch = BKTrackBatch()
        let numConcurrentTrack = 5
        DispatchQueue.concurrentPerform(iterations: numConcurrentTrack) {count in
            batch.store(BKAction.init("track:\(count)"))
        }
        XCTAssert(batch.count == numConcurrentTrack)
    }
    
    func testTrackNeedsSync() {
        var batch = BKTrackBatch()
        XCTAssert(!batch.needsSync)
        
        batch = BKTrackBatch(values: [BKAction.init("track1"),
                                      BKAction.init("track1")])
        XCTAssert(!batch.needsSync)
        
        batch.desiredMaxCountUntilSync = 2
        XCTAssert(batch.needsSync)
        
        batch = BKTrackBatch(values: [BKAction.init("track1", [:], Int64(Date().timeIntervalSince1970*1000) - batch.desiredMaxTimeUntilSync, 0)])
        XCTAssert(batch.needsSync)
    }
    
    func testTrackSync() {
        let batch = BKTrackBatch(values: [BKAction.init("track1")])
        let apiClient = MockBoundlessAPIClient()
        
        let promise = expectation(description: "Did empty on sync")
        XCTAssert(batch.count == 1)
        batch.synchronize(with: apiClient) { _ in
            if batch.count == 0 {
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    
    
    func testReportEncodeAndDecode() {
        let database = BKUserDefaults.standardTest
        
        let encodedBatch = BKReportBatch.init(dict: ["action1" : [BKReinforcement.init("reinforcement1", "action1")]])
        database.archive(encodedBatch, forKey: "testReportEncodeAndDecode")
        let decodedBatch: BKReportBatch = database.unarchive("testReportEncodeAndDecode")!
        
        XCTAssert(decodedBatch.count == encodedBatch.count)
        XCTAssert(decodedBatch.count == 1)
        XCTAssert(decodedBatch.desiredMaxTimeUntilSync == encodedBatch.desiredMaxTimeUntilSync)
        XCTAssert(decodedBatch.desiredMaxCountUntilSync == encodedBatch.desiredMaxCountUntilSync)
    }
    
    func testReportStore() {
        let batch = BKReportBatch()
        let numConcurrentReports = 5
        let numConcurrentReinforcementsPerAction = 3
        DispatchQueue.concurrentPerform(iterations: numConcurrentReports) { actionCount in
            DispatchQueue.concurrentPerform(iterations: numConcurrentReinforcementsPerAction) { reinforcementCount in
                batch.store(BKReinforcement.init("reinforcement\(reinforcementCount)", "action\(actionCount)"))
            }
        }
        XCTAssert(batch.count == numConcurrentReports * numConcurrentReinforcementsPerAction)
    }
    
    func testReportNeedsSync() {
        var batch = BKReportBatch()
        XCTAssert(!batch.needsSync)
        
        batch = BKReportBatch.init(dict: ["action1": [ BKReinforcement.init("reinforcement1", "action1"),
                                                        BKReinforcement.init("reinforcement1", "action1") ]
            ])
        
        XCTAssert(!batch.needsSync)
        
        batch.desiredMaxCountUntilSync = 2
        XCTAssert(batch.needsSync)
        
        batch = BKReportBatch.init(dict: ["action1": [ BKReinforcement.init("reinforcement1", "action1") ],
                                          "action2": [ BKReinforcement.init("reinforcement1", "action2", [:], Int64(Date().timeIntervalSince1970*1000) - batch.desiredMaxTimeUntilSync, 0) ]
            ])
        XCTAssert(batch.needsSync)
    }

    func testReportSync() {
        let batch = BKReportBatch.init(dict: ["action1": [ BKReinforcement.init("reinforcement1", "action1"),
                                                           BKReinforcement.init("reinforcement1", "action1") ]
            ])
        let apiClient = MockBoundlessAPIClient()
        
        let promise = expectation(description: "Did empty on sync")
        XCTAssert(batch.count == 2)
        batch.synchronize(with: apiClient) { _ in
            if batch.count == 0 {
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testSync() {
        let kit = BoundlessKit()
        
        let numConcurrentReports = 5
        let numConcurrentReinforcementsPerAction = 3
        DispatchQueue.concurrentPerform(iterations: numConcurrentReports) { actionCount in
            DispatchQueue.concurrentPerform(iterations: numConcurrentReinforcementsPerAction) { reinforcementCount in
                kit.track(actionID: "track")
                switch reinforcementCount {
                case 1:
                    kit.reinforce(actionID: "customSelector-DopamineKit_Example.RewardsViewController-viewDidAppear:", completion: { (result) in
                        
                    })
                case 2:
                    kit.reinforce(actionID: "customSelector-DopamineKit_Example.ViewController-viewDidAppear:", completion: { (result) in
                        
                    })
                default:
                    kit.reinforce(actionID: "customSelector-DopamineKit_Example.ViewController-action1PerformedWithButton:", completion: { (result) in
                        
                    })
                }
            }
        }
        
        sleep(1)
        
        let promise = expectation(description: "Synced")
        var startTime = Date()
        kit.apiClient?.synchronize() { success in
            promise.fulfill()
            print("\(Date().timeIntervalSince(startTime))")
        }
        DispatchQueue.concurrentPerform(iterations: numConcurrentReports) { actionCount in
            kit.apiClient?.synchronize() { success in
                print("Success count:\(success)")
            }
        }
        
        waitForExpectations(timeout: 12)
    }
    
    
//    func testRefreshAndReinforceReal() {
//        let kit = BoundlessKit()
//        let promise = expectation(description: "Different reinforcements")
//
//        var reinforcement1: String?
//        var reinforcement2: String?
//        kit.refreshReinforcements(forActionID: "a1") {
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
    
}

