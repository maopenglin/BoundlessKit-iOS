//
//  DopamineKit_ReleaseUITests.swift
//  DopamineKit_ReleaseUITests
//
//  Created by Akash Desai on 2/7/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example

class DopamineKit_ReleaseUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        print("Set dopamine credentials to:'\(testCredentials)'")
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
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
            
            func attemptingReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String) {
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
//        ViewController.setTemporaryReward()
        let selectorReinforcement = SelectorReinforcement(targetClass: ViewController.self, selector: #selector(ViewController.viewDidAppear(_:)))
        DopamineVersion.current.update(visualizer: [selectorReinforcement.actionID : ["reward" : ["reward1":"somereward"]]])
        
        XCUIApplication().buttons["Reinforce a user action"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
