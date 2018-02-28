//
//  Test_CodelessIntegration.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example

class TestCodelessIntegration : XCTestCase {

    var window: UIWindow!
    var controllerUnderTest: ViewController!
    
    let mockURLSession = MockURLSession()

    override func setUp() {
        continueAfterFailure = false
        
        DopamineAPI.shared.httpClient = HTTPClient(session: mockURLSession)
        CodelessAPI.shared.httpClient = HTTPClient(session: mockURLSession)
        
        SyncCoordinator.timeDelayAfterTrack = 1
        SyncCoordinator.timeDelayAfterReport = 1
        SyncCoordinator.timeDelayAfterRefresh = 1
        
    }


    override func tearDown() {
        
//        CodelessIntegrationController.shared
//        SyncCoordinator.flush()

        super.tearDown()
    }

    func test() {
        mockURLSession.setCodelessPairingReconnected()
        _ = DopamineKit.shared
        
//        let delegate = AppDelegate.init()
//        delegate.applicationDidBecomeActive(UIApplication.shared)
//        
//        controllerUnderTest = ViewController.instance()
//        
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window.rootViewController = controllerUnderTest
//        window.makeKeyAndVisible()
        
        sleep(4)
    }
}

