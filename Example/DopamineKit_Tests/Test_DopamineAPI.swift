import UIKit
import XCTest
@testable import DopamineKit
//import Pods_DopamineKit_ReleaseTests

class TestDopamineAPI: XCTestCase {
    
    let mockDopamineAPISession = MockURLSession()
    let mockCodelessAPISession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the appID, versionID, production and development secrets, and the inProduction flag
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        DopeLog.print("Set dopamine credentials to:'\(testCredentials)'")
        
        mockDopamineAPISession.mockResponse = ["Status": 204]
        mockCodelessAPISession.mockResponse = ["Status": 204]
        
        DopamineAPI.shared.httpClient = HTTPClient(session: mockDopamineAPISession)
        CodelessAPI.shared.httpClient = HTTPClient(session: mockCodelessAPISession)
        DopamineChanges.shared.wake()
    }
    
    override func tearDown() {
        DopamineKit.syncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
        
        super.tearDown()
    }
    
    ////////////////////////////////////////
    //*-*
    //*-*  Test variables
    //*-*
    ////////////////////////////////////////
    
    let sleepTimeForTrack: UInt32 = 10
    let sleepTimeForReinforce: UInt32 = 10
    let standardExpectationTimeout: TimeInterval = 20
    
    lazy var metaData: [String:AnyObject] = ["string":"str" as AnyObject, "boolsArray":[true, false] as AnyObject, "numbersArray" : ["int":Int(1), "double":Double(2.2), "float":Float(3.3)] as AnyObject ]
    
    
    ////////////////////////////////////////
    //*-*
    //*-*  DopamineKit.track() Tests
    //*-*
    ////////////////////////////////////////
    
    /// Test DopamineKit.track() with only actionID
    ///
    func testTrack() {
        let asyncExpectation = expectation(description: "Tracking request simple")
        
        sleep(5)
        DopamineKit.track("track_test_simple")
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test DopamineKit.track() with actionID and metaData
    ///
    func testTrackWithMetaData() {
        let asyncExpectation = expectation(description: "Tracking request with metadata")
        
        DopamineKit.track("track_test_with_metadata", metaData: metaData)
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test multiple (4) DopamineKit.track() called back to back
    ///
    func testTrackMultiple() {
        
        // given
        SyncCoordinator.shared.flush()
        
        sleep(4)
        // when
        let numRequests = 25
//        for i in 1...numRequests {
//            DopamineKit.track("test_track_multiple_\(i)/\(numRequests)")
//        }
        DispatchQueue.concurrentPerform(iterations: numRequests) { count in
            DopamineKit.track("testingTrackConcurrency", metaData: ["time": NSNumber(value: Date().timeIntervalSince1970*1000)])
        }

        
        // then
        sleep(6)
        print("Track count:\(SyncCoordinator.shared.trackedActions.count) expected:\(numRequests)")
        XCTAssert(SyncCoordinator.shared.trackedActions.count == numRequests)
    }
    
    /// Test performance for track() averaged over 10 calls
    ///
    func testTrackPerformanceExample() {
        self.measure {
            DopamineKit.track("test_track_performance")
        }
    }

    
    ////////////////////////////////////////
    //*-*
    //*-*  DopamineKit.reinforce() Tests
    //*-*
    ////////////////////////////////////////
    let actionID = "action1"
    
    
    /// Test DopamineKit.reinforce() with only actionID and completion handler
    ///
    func testReinforce() {
        let asyncExpectation = expectation(description: "Reinforcement decision simple")
        
        DopamineKit.reinforce(actionID, completion: { response in
            DopeLog.print("DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.reinforce() with actionID, metaData, and completion handler
    ///
    func testReinforceWithMetaData() {
        let asyncExpectation = expectation(description: "Reinforcement decision with metadata")
        
        DopamineKit.reinforce(actionID, metaData: metaData, completion: { response in
            DopeLog.print("DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test multiple (4) DopamineKit.reinforce() called back to back
    ///
    func testReinforceMultiple() {
        let asyncExpectation = expectation(description: "Multiple reinforce requests")
        
        let numRequests = 4
        for i in 1...numRequests {
            DopamineKit.reinforce(actionID, completion: { response in
                DopeLog.print("Reinforce() call \(i)/\(numRequests) with  actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
                if i==numRequests {
                    sleep(self.sleepTimeForReinforce)
                    asyncExpectation.fulfill()
                }
            })
        }
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: testReinforceMultiple timed out")
        })
    }
    
    /// Test performance for reinforce() averaged over 10 calls
    ///
    func testReinforcePerformanceExample() {
        self.measure {
            DopamineKit.reinforce(self.actionID, completion: { _ in })
        }
    }
}
