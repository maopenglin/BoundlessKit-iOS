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
    }
    
    override func tearDown() {
        
//        clearSQLTables()
//        clearNSDefaults()
        
        super.tearDown()
    }
    
    func clearSQLTables() {
        SQLiteDataStore.sharedInstance.dropTables()
    }
    
    func clearNSDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let keys = ["DopamineTrackSyncer", "DopamineReportSyncer", "DopamineCartridgeSyncer", "DopaminePrimaryIdentity"]
        for key in keys {
            defaults.removeObjectForKey(key)
        }
    }
    
////////////////////////////////////////
//*-*
//*-*  DopamineKit.track() Tests
//*-*
////////////////////////////////////////
    
    /// Test DopamineKit.track() with just actionID and completion handler
    ///
    func testTrackingRequestSimple() {
        let asyncExpectation = expectationWithDescription("Tracking request simpole")
        DopamineKit.track("tracktestsimple")
        sleep(4)
        asyncExpectation.fulfill()
        waitForExpectationsWithTimeout(5, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test DopamineKit.track() with actionID, metaData, secondaryIdentity, and completion handler
    ///
    func testTrackingRequestFull() {
        let asyncExpectation = expectationWithDescription("Tracking request with metadata")
        let metaData:[String:AnyObject] = ["key":"value", "number":2.2]
        DopamineKit.track("tracktestwithmetadata", metaData: metaData)
        sleep(4)
        asyncExpectation.fulfill()
        waitForExpectationsWithTimeout(5, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test multiple (3) DopamineKit.track() called back to back
    ///
    func testTrackingMultiple() {
        let asyncExpectation = expectationWithDescription("Multiple racking request")
        DopamineKit.track("tracktestwithmetadata13")
        DopamineKit.track("tracktestwithmetadata2")
        DopamineKit.track("tracktestwithmetadata13")
        sleep(4)
        asyncExpectation.fulfill()
        waitForExpectationsWithTimeout(5, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
    
    /// Test numRequests calls in a row
    /// uses testTrackingRequestSimple()
    ///
    func testPerformanceExample() {
        self.measureBlock {
            
            let numRequests = 100
            for _ in 1...numRequests{
                self.testTrackingRequestSimple()
            }
            
        }
    }

    
////////////////////////////////////////
//*-*
//*-*  DopamineKit.reinforce() Tests
//*-*
////////////////////////////////////////
    
    
    /// Test DopamineKit.reinforce() with just actionID and completion handler
    ///
    func testReinforceRequestSimple() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision simple")
        DopamineKit.reinforce("action1", completion: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            
            
        })
        DopamineKit.reinforce("action1", completion: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            sleep(5)
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(5, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.reinforce() with actionID and metaData
    ///
    func testReinforceRequestFull() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision with metadata")
        
        let actionID = "action1"
        let metaData:[String:AnyObject] = ["key":"value", "number":-1.4]
        DopamineKit.reinforce(actionID, metaData: metaData, completion: {
            response in
            NSLog("DopamineKitTest \(actionID) reinforce resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
