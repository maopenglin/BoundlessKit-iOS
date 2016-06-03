import UIKit
import XCTest
import DopamineKit

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the AppID, API keys, ...
        let path = NSBundle(forClass: self.dynamicType).pathForResource("DopamineProperties", ofType: "plist")
        DopamineKit.instance.plistPath = path as String!
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Test DopamineKit.reinforce()
    func testReinforceRequest() {
        NSLog("alk;sdjfal;skdfj")
        let asyncExpectation = expectationWithDescription("Reinforcement decision")
        DopamineKit.reinforce("action1", callback: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    // Test DopamineKit.track()
    func testTrackingRequest() {
        NSLog("alk;sdjfal;skdfj")
//        DopamineKit.tra
        let asyncExpectation = expectationWithDescription("Tracking request")
        DopamineKit.track(actionID: "test", callback: {response in
            NSLog("DopamineKitTest tracking resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
        
    }
    
}
