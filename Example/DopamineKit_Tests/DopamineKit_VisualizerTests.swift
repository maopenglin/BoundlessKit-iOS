//
//  DopamineKit_VisualizerTests.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import DopamineKit

class VisualizerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Set the plist so DopamineKit can read the appID, versionID, production and development secrets, and the inProduction flag
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        Tests.log(message: "Set dopamine credentials to:'\(testCredentials)'")
    }
    
    override func tearDown() {
        DopamineKit.syncCoordinator.flush()          // clears the sync state, recorded actions, and cartridges
        
        super.tearDown()
    }
    
    func testBoot() {
        let asyncExpectation = expectation(description: "Sent boot call")
        
        CodelessAPI.boot {
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: {error in
            XCTAssertNil(error, "DopamineKitTest error: track request timed out")
        })
    }
}
