//
//  DopamineKit_ExampleUITests.swift
//  DopamineKit_ExampleUITests
//
//  Created by Akash Desai on 2/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest

@testable import DopamineKit
@testable import Pods_DopamineKit_Example

class DopamineKit_ExampleUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 0).buttons["Reinforce a user action"].tap()
        
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
        
//        let v = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
//        app.launch()
        
        let changesDelegate = ChangesDelegate(promise: promise)
        DopamineChanges.shared.delegate = changesDelegate
        DopamineVersion.current.update(visualizer: ["viewControllerDidAppear-DopamineKit_Example.ViewController-viewDidAppear:" : ["reward" : ["reward1":"somereward"]]])
//        DopamineChanges.shared.setSwizzling(true)
        
        app.buttons["Reinforce a user action"].tap()
//        XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 0).buttons["Reinforce a user action"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
        
        
        
    }
    
}
