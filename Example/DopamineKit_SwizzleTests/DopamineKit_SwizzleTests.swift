//
//  DopamineKit_SwizzleTests.swift
//  DopamineKit_SwizzleTests
//
//  Created by Akash Desai on 1/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import DopamineKit
@testable import DopamineKit_Example


extension ViewController {
    @objc func testFunc() {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In testFunc count:\(count)")
//        print("\n\(Thread.callStackSymbols as AnyObject)")
//        return UInt32(count)
    }
    
    @objc func testFunc2() {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In testFunc2 count:\(count)")
//        print("\n\(Thread.callStackSymbols as AnyObject)")
//        return UInt32(count)
    }
}

class DopamineKit_SwizzleTests: XCTestCase {
    
    static var counter = 0
    
    var controllerUnderTest: ViewController!
    override func setUp() {
        super.setUp()
        DopamineVersion.current.update(visualizer: nil)
        
        
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
    }
    
    override func tearDown() {
//        controllerUnderTest = nil
        super.tearDown()
    }
    
    func testSimpleMethodSwizzle() {
        
        //given
        var controllerUnderTest: ViewController!
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        XCTAssert(DopamineConfiguration.current.integrationMethod == "codeless")
        controllerUnderTest.testFunc()
        let beforeTestFuncStackSize = DopamineKit_SwizzleTests.counter
        controllerUnderTest.testFunc2()
        let beforeTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        
        // when
        SelectorReinforcement.registerSimpleMethod(classType: ViewController.self, selector: #selector(ViewController.testFunc), reinforcement: ["test": ["Hello!"]])
        SelectorReinforcement.registerSimpleMethod(classType: ViewController.self, selector: #selector(ViewController.testFunc2), reinforcement: ["test": ["Hello!"]])
        
        
        // then
        XCTAssert(SelectorReinforcement.isRegistered(classType: ViewController.self, selector: #selector(ViewController.testFunc)), "Selector was not registered")
        XCTAssert(SelectorReinforcement.isRegistered(classType: ViewController.self, selector: #selector(ViewController.testFunc2)), "Selector was not registered")
        
        controllerUnderTest.testFunc()
        let afterTestFuncStackSize = DopamineKit_SwizzleTests.counter
        controllerUnderTest.testFunc2()
        let afterTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        XCTAssert(afterTestFuncStackSize == beforeTestFuncStackSize + 1, "Swizzle did not happen")
        XCTAssert(afterTestFunc2StackSize == beforeTestFunc2StackSize + 1, "Swizzle did not happen")
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
        
        let changesDelegate = ChangesDelegate(promise: promise)
        DopamineChanges.shared.delegate = changesDelegate
        DopamineVersion.current.update(visualizer: ["viewControllerDidAppear-DopamineKit_Example.ViewController-viewDidAppear:" : "somereward"])
        DopamineChanges.shared.setSwizzling(true)
        
        controllerUnderTest.presentAnother()
        
        waitForExpectations(timeout: 3, handler: nil)
        
        
    }
    
    
}


