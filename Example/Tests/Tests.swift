import XCTest
@testable import BoundlessKit

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so BoundlessKit can read the appID, versionID, production and development secrets, and the inProduction flag
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "BoundlessDemoProperties", ofType: "plist")!) as! [String:Any]
        BoundlessKit.testCredentials = testCredentials
        Tests.log(message: "Set boundless credentials to:'\(testCredentials)'")
    }
    
    override func tearDown() {
        BoundlessKit.syncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
        
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
    
    
    internal static func log(message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        var functionSignature:String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent.components(separatedBy: ",")[0]
        NSLog("[\(fileName):\(line):\(functionSignature)] - \(message)")
    }
    
    
    ////////////////////////////////////////
    //*-*
    //*-*  BoundlessKit.track() Tests
    //*-*
    ////////////////////////////////////////
    
    
    /// Test BoundlessKit.track() with only actionID
    ///
    func testTrack() {
        let asyncExpectation = expectation(description: "Tracking request simple")
        
        BoundlessKit.track("track_test_simple")
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "track request timed out")
        })
    }
    
    /// Test BoundlessKit.track() with actionID and metaData
    ///
    func testTrackWithMetaData() {
        let asyncExpectation = expectation(description: "Tracking request with metadata")
        
        BoundlessKit.track("track_test_with_metadata", metaData: metaData)
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "track request timed out")
        })
    }
    
    /// Test multiple (4) BoundlessKit.track() called back to back
    ///
    func testTrackMultiple() {
        let asyncExpectation = expectation(description: "Multiple tracking request")
        
        let numRequests = 4
        for i in 1...numRequests {
            BoundlessKit.track("test_track_multiple_\(i)/\(numRequests)")
        }
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "testTrackMultiple timed out")
        })
    }
    
    /// Test performance for track() averaged over 10 calls
    ///
    func testTrackPerformanceExample() {
        self.measure {
            BoundlessKit.track("test_track_performance")
        }
    }
    
    
    ////////////////////////////////////////
    //*-*
    //*-*  BoundlessKit.reinforce() Tests
    //*-*
    ////////////////////////////////////////
    let actionID = "action1"
    
    
    /// Test BoundlessKit.reinforce() with only actionID and completion handler
    ///
    func testReinforce() {
        let asyncExpectation = expectation(description: "Reinforcement decision simple")
        
        BoundlessKit.reinforce(actionID, completion: { response in
            Tests.log(message: "BoundlessKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "BoundlessKitTest error: reinforce request timed out")
        })
    }
    
    /// Test BoundlessKit.reinforce() with actionID, metaData, and completion handler
    ///
    func testReinforceWithMetaData() {
        let asyncExpectation = expectation(description: "Reinforcement decision with metadata")
        
        BoundlessKit.reinforce(actionID, metaData: metaData, completion: { response in
            Tests.log(message: "BoundlessKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "reinforce request timed out")
        })
    }
    
    /// Test multiple (4) BoundlessKit.reinforce() called back to back
    ///
    func testReinforceMultiple() {
        let asyncExpectation = expectation(description: "Multiple reinforce requests")
        
        let numRequests = 4
        for i in 1...numRequests {
            BoundlessKit.reinforce(actionID, completion: { response in
                Tests.log(message: "Reinforce() call \(i)/\(numRequests) with  actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
                if i==numRequests {
                    sleep(self.sleepTimeForReinforce)
                    asyncExpectation.fulfill()
                }
            })
        }
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "testReinforceMultiple timed out")
        })
    }
    
    /// Test performance for reinforce() averaged over 10 calls
    ///
    func testReinforcePerformanceExample() {
        self.measure {
            BoundlessKit.reinforce(self.actionID, completion: { _ in })
        }
    }
}
