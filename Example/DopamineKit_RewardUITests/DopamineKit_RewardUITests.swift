//
//  DopamineKit_RewardUITests.swift
//  DopamineKit_RewardUITests
//
//  Created by Akash Desai on 1/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example

class DopamineKit_RewardUITests: XCTestCase {
    
    var app: XCUIApplication!
    var controllerUnderTesting: ViewController!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
//        let dopaminekitExampleIcon = XCUIApplication()/*@START_MENU_TOKEN@*/.otherElements["Home screen icons"].scrollViews/*[[".otherElements[\"Home screen icons\"]",".otherElements[\"SBFolderScalingView\"].scrollViews",".scrollViews"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[2,0]]@END_MENU_TOKEN@*/.otherElements.icons["DopamineKit_Example"]
        
        app.buttons["Reinforce a user action"].tap()
        
    }
    
    func testViewControllerDidAppearReward() {
        // given
        let promise = expectation(description: "Reinforcement attempted")
        class ChangesDelegate : NSObject, DopamineChangesDelegate {
            var reinforcementAttemptPromise: XCTestExpectation

            init(promise: XCTestExpectation) {
                reinforcementAttemptPromise = promise
                super.init()
            }
            func attemptingReinforcement() {
                print("In attemptingReinforcement")
                reinforcementAttemptPromise.fulfill()
            }

            func showingReward() {
                print("In showingReward")
            }
        }

        let v = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        let changesDelegate = ChangesDelegate(promise: promise)
        DopamineChanges.shared.delegate = changesDelegate
        DopamineVersion.current.update(visualizer: ["viewControllerDidAppear-DopamineKit_Example.ViewController-viewDidAppear:" : "somereward"])
        DopamineChanges.shared.enhanceMethods(true)

        XCUIApplication().buttons["Reinforce a user action"].tap()

        waitForExpectations(timeout: 3, handler: nil)
        
        
        
    }
    
}
