//
//  DopamineKit_ReleaseTests.swift
//  DopamineKit_ReleaseTests
//
//  Created by Akash Desai on 2/7/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example

class DopamineKit_ReleaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        print("Set dopamine credentials to:'\(testCredentials)'")
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
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
        let selectorReinforcement = SelectorReinforcement(targetClass: ViewController.self, selector: #selector(ViewController.viewDidAppear(_:)))
        DopamineVersion.current.update(visualizer: [selectorReinforcement.actionID : ["reward" : ["reward1":"somereward"]]])
        XCUIApplication().buttons["Reinforce a user action"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
