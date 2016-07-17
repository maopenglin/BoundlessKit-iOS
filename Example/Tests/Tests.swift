import UIKit
import XCTest
import DopamineKit
import Pods_DopamineKit_Tests

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the appID, versionID, production and development secrets, and the inProduction flag
//        let path = NSBundle(forClass: self.dynamicType).pathForResource("DopamineDemoProperties", ofType: "plist")
//        DopamineKit.instance.propertyListPath = path as String!
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Test DopamineKit.reinforce() with just actionID and completion handler
    ///
    func testReinforceRequestSimple() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision")
        DopamineKit.reinforce("action1", completion: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.reinforce() with actionID, metaData, secondaryIdentity, timeout, and completion handler
    ///
    func testReinforceRequestFull() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision")
        DopamineKit.reinforce("action1", metaData: ["key":"value", "number":-1.4], completion: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.track() with just actionID and completion handler
    ///
    func testTrackingRequestSimple() {
//        let asyncExpectation = expectationWithDescription("Tracking request")
        
        DopamineKit.track("tracktest1")
        
//        waitForExpectationsWithTimeout(10, handler: {error in
//            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
//        })
    }
    
    /// Test DopamineKit.track() with actionID, metaData, secondaryIdentity, and completion handler
    ///
    func testTrackingRequestFull() {
//        let asyncExpectation = expectationWithDescription("Tracking request")
        
        DopamineKit.track("tracktest2", metaData: ["key":"value", "number":2.2])
        
//        waitForExpectationsWithTimeout(10, handler: {error in
//            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
//        })
    }
    
    /// Test 10 calls in a row
    /// uses testTrackingRequestSimple()
    ///
    func testPerformanceExample() {
        self.measureBlock {
            
            let numRequests = 10
            for _ in 1...numRequests{
                self.testTrackingRequestSimple()
            }
            
        }
    }
    
    
    /// Test CandyBar init()
    ///
    func testCandyBar(){
        let color = CandyBar.hexStringToUIColor("#F0F0F0")
        let candybar = CandyBar(title: "Title", subtitle: "subtitle", icon: CandyIcon.Certificate, backgroundColor: color)
        print("CandyBar title: ", candybar.titleLabel.text)
    }
    
    
    
    
    
    
    
    
    
    
    
    func testRefresh(){
        print("starting test")
        let resultCartridge = DopeAPIPortal.refresh("action1")
//        while var event = resultCartridge.pop(){
//            print(event.reinforcement)
//        }
        
        print("test ended")
        
        
        
        let asyncExpectation = expectationWithDescription("Waiting to hear back")
        sleep(3)
        asyncExpectation.fulfill()

        waitForExpectationsWithTimeout(3, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })

        
    }
    
    func testNewTrack(){
        DopamineKit.track("taction")
        
        let asyncExpectation = expectationWithDescription("Waiting to hear back")
        sleep(3)
        asyncExpectation.fulfill()
        
        waitForExpectationsWithTimeout(3, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
