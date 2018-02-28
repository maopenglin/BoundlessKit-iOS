import UIKit
import XCTest
@testable import DopamineKit
//import Pods_DopamineKit_ReleaseTests

class TestDopamineAPI: XCTestCase {
    
    
    ////////////////////////////////////////
    //*-*
    //*-*  Set Up, Tear Down, & Test variables
    //*-*
    ////////////////////////////////////////
    
    let mockDopamineAPISession = MockURLSession()
    let mockCodelessAPISession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        
//        DopamineDefaults.current = MockDopamineDefaults.standard
        DopamineAPI.shared.httpClient = HTTPClient(session: mockDopamineAPISession)
        CodelessAPI.shared.httpClient = HTTPClient(session: mockCodelessAPISession)
        
        SyncCoordinator.timeDelayAfterTrack = 1
        SyncCoordinator.timeDelayAfterReport = 1
        SyncCoordinator.timeDelayAfterRefresh = 1
        
        DopamineDefaults.current.clear()
        
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        DopeLog.print("Set dopamine credentials to:'\(testCredentials)'")
        
        CodelessIntegrationController.shared.state = .integrated
    }
    
    override func tearDown() {
        SyncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
        super.tearDown()
    }
    
    ////////////////////////////////////////
    //*-*
    //*-*  DopamineKit.track() Tests
    //*-*
    ////////////////////////////////////////
    
    lazy var metaData: [String:AnyObject] = ["string":"str" as AnyObject, "boolsArray":[true, false] as AnyObject, "numbersArray" : ["int":Int(1), "double":Double(2.2), "float":Float(3.3)] as AnyObject ]
    
    /// Test DopamineKit.track() with only actionID
    ///
    func testTrack() {
        
        SyncCoordinator.flush()
        DopamineKit.track("track_test_simple")
        
        let promise = expectation(description: "Correct number of tracks")
        let queue = TestOperationQueue()
        queue.when(successCondition: {return SyncCoordinator.current.trackedActions.count == 1}) {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testTrackSyncSuccess() {
        mockDopamineAPISession.mockResponse = ["status": 200]
        
        SyncCoordinator.flush()
        let numRequests = DopamineConfiguration.current.trackBatchSize - 1
        DispatchQueue.concurrentPerform(iterations: numRequests) { count in
            DopamineKit.track(
                "testingTrackConcurrency",
                metaData: ["time": NSNumber(value: Date().timeIntervalSince1970*1000),
                           "index": count,
                           "concurrentTrackSize": numRequests]
            )
        }
        
        let promise = expectation(description: "Tracks Accounted")
        let promise2 = expectation(description: "Tracks Synchronized")
        let queue = TestOperationQueue()
        queue.when( successCondition: {
            sleep(1)
            return SyncCoordinator.current.trackedActions.count == numRequests
        }, doBlock: {
            promise.fulfill()
            DopeLog.debug("Promise \(promise.expectationDescription) fulfilled")
            DopamineKit.track("trackShouldInvokeSuccessfulSync")
            queue.when( successCondition: {
                sleep(1)
                return SyncCoordinator.current.trackedActions.count == 0
            }, doBlock: {
                promise2.fulfill()
            })
        })
        
        
        // then
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testTrackSyncFail() {
        mockDopamineAPISession.mockResponse = ["status": 500]
        
        SyncCoordinator.flush()
        let numRequests = DopamineConfiguration.current.trackBatchSize - 1
        DispatchQueue.concurrentPerform(iterations: numRequests) { index in
            DopamineKit.track(
                "testingTrackConcurrency",
                metaData: ["time": NSNumber(value: Date().timeIntervalSince1970*1000),
                           "count": index + 1,
                           "concurrentTrackSize": numRequests]
            )
        }
        
        let promise = expectation(description: "Tracks Accounted")
        let promise2 = expectation(description: "Tracks Synchronize Failed")
        let queue = TestOperationQueue()
        queue.when( successCondition: {
            sleep(1)
            return SyncCoordinator.current.trackedActions.count == numRequests
        }, doBlock:  {
            promise.fulfill()
            DopamineKit.track("trackShouldInvokeFailedSync")
            queue.when( successCondition: {
                sleep(1)
                return SyncCoordinator.current.trackedActions.count == numRequests + 1
            }, doBlock: {
                promise2.fulfill()
            })
        })
        
        
        // then
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    
    ////////////////////////////////////////
    //*-*
    //*-*  DopamineKit.reinforce() Tests
    //*-*
    ////////////////////////////////////////
    let actionID = "action1"
    let nonNeutralReinforcementDecision = "Confetti"
    var actionCartridgeResponse: [String : Any] {
        return [
            "status": 200,
            "expiresIn": 86400000,
            "reinforcementCartridge": [
                nonNeutralReinforcementDecision,
                Cartridge.defaultReinforcementDecision,
                nonNeutralReinforcementDecision,
                Cartridge.defaultReinforcementDecision,
                nonNeutralReinforcementDecision,
                Cartridge.defaultReinforcementDecision,
                nonNeutralReinforcementDecision,
                Cartridge.defaultReinforcementDecision,
                nonNeutralReinforcementDecision,
                Cartridge.defaultReinforcementDecision
            ]
        ]
    }
    let unknownActionID = "someUnpublishedAction"
    var unknownActionCartridgeResponse: [String : Any] {
        return [
            "status": 400
        ]
    }
    
    /// Test DopamineKit.reinforce() with only actionID and completion handler
    ///
    func testReinforceFirstCall() {
        SyncCoordinator.flush()
        let asyncExpectation = expectation(description: "Reinforcement decision simple")
        
        DopamineKit.reinforce(actionID, completion: { response in
            DopeLog.print("DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 1, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    func testReinforceCartridgeSyncSuccess() {
        mockDopamineAPISession.mockResponse = actionCartridgeResponse
        SyncCoordinator.flush()
        
        
        let queue = TestOperationQueue()
        var reinforcementDecision = Cartridge.defaultReinforcementDecision
        let asyncExpectation = expectation(description: "Got non-neutral reinforcement decision")
        
        queue.repeatWhile( repeatCondition: {
            return reinforcementDecision == Cartridge.defaultReinforcementDecision
        }, doBlock: {
            DopamineKit.reinforce(self.actionID, metaData: self.metaData) { reinforcement in
                reinforcementDecision = reinforcement
                DopeLog.debug("Got reinforcement:\(reinforcement)")
            }
            sleep(1)
        }, finishedBlock: {
            if reinforcementDecision == self.nonNeutralReinforcementDecision { asyncExpectation.fulfill() }
        })
        
        waitForExpectations(timeout: 7, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: cartridge refresh failed")
        })
    }
    
    func testReinforceCartridgeSyncFail() {
        SyncCoordinator.flush()
        mockDopamineAPISession.mockResponse = unknownActionCartridgeResponse
        
        let failedSyncErasedReport = expectation(description: "Failed sync clears report")
        let queue = TestOperationQueue()
        
        DopamineKit.reinforce(unknownActionID) { reinforcement in
            XCTAssert(SyncCoordinator.current.reportedActions.count == 1)
            queue.when( successCondition: {return SyncCoordinator.current.reportedActions.count == 0}) {
                failedSyncErasedReport.fulfill()
            }
        }
        
        waitForExpectations(timeout: 7, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: testReinforceMultiple timed out")
        })
    }
}
