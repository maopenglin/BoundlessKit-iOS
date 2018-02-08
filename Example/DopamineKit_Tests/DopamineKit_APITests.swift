import UIKit
import XCTest
import DopamineKit
//import Pods_DopamineKit_ReleaseTests

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the appID, versionID, production and development secrets, and the inProduction flag
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        Tests.log(message: "Set dopamine credentials to:'\(testCredentials)'")
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
    //*-*  DopamineKit.track() Tests
    //*-*
    ////////////////////////////////////////
    
    
    /// Test DopamineKit.track() with only actionID
    ///
    func testTrack() {
        let asyncExpectation = expectation(description: "Tracking request simple")
        
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
        let asyncExpectation = expectation(description: "Multiple tracking request")
        
        let numRequests = 4
        for i in 1...numRequests {
            DopamineKit.track("test_track_multiple_\(i)/\(numRequests)")
        }
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectations(timeout: standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: testTrackMultiple timed out")
        })
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
            Tests.log(message: "DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
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
            Tests.log(message: "DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
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
                Tests.log(message: "Reinforce() call \(i)/\(numRequests) with  actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
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
