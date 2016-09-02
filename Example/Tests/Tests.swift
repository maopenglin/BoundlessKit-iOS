import UIKit
import XCTest
import DopamineKit
import Pods_DopamineKit_Tests

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the appID, versionID, production and development secrets, and the inProduction flag
        let path = NSBundle(forClass: self.dynamicType).pathForResource("DopamineDemoProperties", ofType: "plist")
        DopamineAPI.testCredentialPath = path as String!
        Tests.log("Modified dopamine credentials path to:'\(path)'")
    }
    
    override func tearDown() {
        let dopamineKit = DopamineKit.sharedInstance
        dopamineKit.syncCoordinator.resetSyncers()          // removes the sync triggers from NSUserDefaults
        dopamineKit.dataStore.clearTables()                 // clears the stored actions and reinforcement decisions from SQLite

        super.tearDown()
    }
    
    ////////////////////////////////////////
    //*-*
    //*-*  Test variables
    //*-*
    ////////////////////////////////////////
    
    let sleepTimeForTrack: UInt32 = 10
    let sleepTimeForReinforce: UInt32 = 10
    let standardExpectationTimeout: NSTimeInterval = 20
    
    let metaData: [String:AnyObject] = ["string":"str", "boolsArray":[true, false], "numbersArray" : ["int":Int(1), "double":Double(2.2), "float":Float(3.3)] ]
    
    
    internal static func log(message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        var functionSignature:String = function
        if let parameterNames = functionSignature.rangeOfString("\\((.*?)\\)", options: .RegularExpressionSearch){
            functionSignature.replaceRange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent.componentsSeparatedByString(".")[0]
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
        let asyncExpectation = expectationWithDescription("Tracking request simple")
        
        DopamineKit.track("track_test_simple")
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test DopamineKit.track() with actionID and metaData
    ///
    func testTrackWithMetaData() {
        let asyncExpectation = expectationWithDescription("Tracking request with metadata")
        
        DopamineKit.track("track_test_with_metadata", metaData: metaData)
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test multiple (4) DopamineKit.track() called back to back
    ///
    func testTrackMultiple() {
        let asyncExpectation = expectationWithDescription("Multiple tracking request")
        
        let numRequests = 4
        for i in 1...numRequests {
            DopamineKit.track("test_track_multiple_\(i)/\(numRequests)")
        }
        sleep(sleepTimeForTrack)
        asyncExpectation.fulfill()
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: testTrackMultiple timed out")
        })
    }
    
    /// Test performance for track() averaged over 10 calls
    ///
    func testTrackPerformanceExample() {
        self.measureBlock {
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
        let asyncExpectation = expectationWithDescription("Reinforcement decision simple")
        
        DopamineKit.reinforce(actionID, completion: { response in
            Tests.log("DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.reinforce() with actionID, metaData, and completion handler
    ///
    func testReinforceWithMetaData() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision with metadata")
        
        DopamineKit.reinforce(actionID, metaData: metaData, completion: { response in
            Tests.log("DopamineKitTest actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
            sleep(self.sleepTimeForReinforce)
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test multiple (4) DopamineKit.reinforce() called back to back
    ///
    func testReinforceMultiple() {
        let asyncExpectation = expectationWithDescription("Multiple reinforce requests")
        
        let numRequests = 4
        for i in 1...numRequests {
            DopamineKit.reinforce(actionID, completion: { response in
                Tests.log("Reinforce() call \(i)/\(numRequests) with  actionID:'\(self.actionID)' resulted in reinforcement:'\(response)'")
                if i==numRequests {
                    sleep(self.sleepTimeForReinforce)
                    asyncExpectation.fulfill()
                }
            })
        }
        
        waitForExpectationsWithTimeout(standardExpectationTimeout, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: testReinforceMultiple timed out")
        })
    }
    
    /// Test performance for reinforce() averaged over 10 calls
    ///
    func testReinforcePerformanceExample() {
        self.measureBlock {
            DopamineKit.reinforce(self.actionID, completion: { _ in })
        }
    }
}
