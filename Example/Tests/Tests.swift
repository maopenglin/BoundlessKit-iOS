import UIKit
import XCTest
import DopamineKit

class Tests: XCTestCase {
    
    /// Note: The NSBundle.mainBundle() must have DopamineProperites.plist in its path
    override func setUp() {
        super.setUp()
        // read the note
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Test DopamineKit.reinforce(actionID,callback)
    func testReinforceRequest() {
        let asyncExpectation = expectationWithDescription("Reinforcement decision")
        DopamineKit.reinforce("action1", callback: {response in
            NSLog("DopamineKitTest reinforce resulted in:\(response)")
            asyncExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: reinforce request timed out")
        })
    }
    
    /// Test DopamineKit.track(actionID)
    func testTrackingRequest() {
        DopamineKit.track("test")
    }
    
}
