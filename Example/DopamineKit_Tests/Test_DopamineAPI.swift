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
    
    let mockURLSession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        DopeLog.print("Set dopamine credentials to:'\(testCredentials)'")
        
        DopamineAPI.shared.httpClient = HTTPClient(session: mockURLSession)
        CodelessAPI.shared.httpClient = HTTPClient(session: mockURLSession)
        
        SyncCoordinator.timeDelayAfterTrack = 1
        SyncCoordinator.timeDelayAfterReport = 1
        SyncCoordinator.timeDelayAfterRefresh = 1
        SyncCoordinator.flush()
        
        _ = DopamineKit.shared
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
        DopamineKit.track("track_test_simple")
        
        let promise = expectation(description: "Correct number of tracks")
        let queue = TestOperationQueue()
        queue.when(successCondition: {return SyncCoordinator.current.trackedActions.count == 1}) {
            promise.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testTrackSyncSuccess() {
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
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testTrackSyncFail() {
        mockURLSession.setMockResponse(for: .track, ["status": 500])
        
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
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    /// Test DopamineKit.reinforce() with only actionID and completion handler
    ///
    func testReinforceFirstCall() {
        let asyncExpectation = expectation(description: "First reinforcement for new action is the default decision")
        
        DopamineKit.reinforce(Cartridge.mockGoodActionID, completion: { response in
            DopeLog.print("DopamineKitTest actionID:'\(Cartridge.mockGoodActionID)' resulted in reinforcement:'\(response)'")
            if response == Cartridge.defaultReinforcementDecision {
                asyncExpectation.fulfill()
            }
        })
        
        waitForExpectations(timeout: 1, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    func testReinforceCartridgeSyncSuccess() {
        mockURLSession.setMockResponse(for: .refresh, Cartridge.mockGoodCartridgeResponse)
        
        let queue = TestOperationQueue()
        var reinforcementDecision = Cartridge.defaultReinforcementDecision
        let asyncExpectation = expectation(description: "Got non-neutral reinforcement decision")
        
        queue.repeatWhile( repeatCondition: {
            return reinforcementDecision == Cartridge.defaultReinforcementDecision
        }, doBlock: {
            DopamineKit.reinforce(Cartridge.mockGoodActionID, metaData: self.metaData) { reinforcement in
                reinforcementDecision = reinforcement
                DopeLog.debug("Got reinforcement:\(reinforcement)")
            }
            sleep(1)
        }, finishedBlock: {
            if reinforcementDecision == Cartridge.mockGoodReinforcementID { asyncExpectation.fulfill() }
        })
        
        waitForExpectations(timeout: 7, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: cartridge refresh failed")
        })
    }
    
    func testReinforceCartridgeSyncFail() {
        mockURLSession.setMockResponse(for: .refresh, Cartridge.mockBadCartridgeResponse)
        
        let failedSyncErasedReport = expectation(description: "Failed sync clears report")
        let queue = TestOperationQueue()
        
        DopamineKit.reinforce(Cartridge.mockBadActionID) { reinforcement in
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
