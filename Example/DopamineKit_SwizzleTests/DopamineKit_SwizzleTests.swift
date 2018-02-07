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

class DopamineKit_SwizzleTests: XCTestCase {
    
    static var counter = 0
    
    var controllerUnderTest: ViewController!
    override func setUp() {
        super.setUp()
        DopamineVersion.current.update(visualizer: nil)
        
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSwizzleForViewControllerDidAppear() {
        var controllerUnderTest: ViewController!
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
        doubleSwizzle(
            sut: controllerUnderTest,
            selector1: #selector(ViewController.funcReturnVoidParams0),
            args1: [],
            selector2: #selector(ViewController.func2ReturnVoidParams0),
            args2: [],
            argsCount: 0
        )
    }
    
    func testSwizzleForMethodReturnsVoidParam0() {
        var controllerUnderTest: ViewController!
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
        doubleSwizzle(
            sut: controllerUnderTest,
            selector1: #selector(ViewController.funcReturnVoidParams0),
            args1: [],
            selector2: #selector(ViewController.func2ReturnVoidParams0),
            args2: [],
            argsCount: 0
        )
    }
    
    func testSwizzleForMethodReturnsVoidParam1obj() {
        var controllerUnderTest: ViewController!
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
        doubleSwizzle(
            sut: controllerUnderTest,
            selector1: #selector(ViewController.funcReturnsVoidParam1obj(param1:)),
            args1: ["blue"],
            selector2: #selector(ViewController.func2ReturnsVoidParam1obj(param1:)),
            args2: ["red"],
            argsCount: 1
        )
    }
    
    func testSwizzleForMethodReturnsVoidParam1int() {
        var controllerUnderTest: ViewController!
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
        doubleSwizzle(
            sut: controllerUnderTest,
            selector1: #selector(ViewController.funcReturnsVoidParam1int(param1:)),
            args1: [10],
            selector2: #selector(ViewController.func2ReturnsVoidParam1int(param1:)),
            args2: [20],
            argsCount: 1
        )
    }
    
    func doubleSwizzle(sut: NSObject, selector1: Selector, args1: [Any], selector2: Selector, args2: [Any], argsCount: Int) {
        
        // given
        XCTAssert(DopamineConfiguration.current.integrationMethod == "codeless")
        sut.performVariableSelector(sel: selector1, argsCount: argsCount, args: args1)
        let beforeTestFuncStackSize = DopamineKit_SwizzleTests.counter
        sut.performVariableSelector(sel: selector2, argsCount: argsCount, args: args2)
        let beforeTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        // when
        SelectorReinforcement.registerSimpleMethod(classType: type(of: sut), selector: selector1, reinforcement: ["reward": ["rewardForFirst": ["Hello!"]]])
        SelectorReinforcement.registerSimpleMethod(classType: type(of: sut), selector: selector2, reinforcement: ["reward": ["rewardForSecond": ["Hello!"]]])
        XCTAssert(SelectorReinforcement.isRegistered(classType: type(of: sut), selector: selector1), "Selector was not registered")
        XCTAssert(SelectorReinforcement.isRegistered(classType: type(of: sut), selector: selector2), "Selector was not registered")
        
        
        // then
        sut.performVariableSelector(sel: selector1, argsCount: argsCount, args: args1)
        let afterTestFuncStackSize = DopamineKit_SwizzleTests.counter
        sut.performVariableSelector(sel: selector2, argsCount: argsCount, args: args2)
        let afterTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        XCTAssert(afterTestFuncStackSize == beforeTestFuncStackSize + 1, "Swizzle did not happen")
        XCTAssert(afterTestFunc2StackSize == beforeTestFunc2StackSize + 1, "Swizzle did not happen")
    }
    
    
//    func testViewControllerDidAppearReward() {
//        // given
//        let promise = expectation(description: "Reinforcement attempted")
//        class ChangesDelegate : NSObject, DopamineChangesDelegate {
//            var reinforcementAttemptPromise: XCTestExpectation
//            
//            init(promise: XCTestExpectation) {
//                reinforcementAttemptPromise = promise
//                super.init()
//            }
//            func attemptingReinforcement() {
//                print("In attemptingReinforcement")
//                reinforcementAttemptPromise.fulfill()
//            }
//            
//            func showingReward() {
//                print("In showingReward")
//            }
//        }
//        
//        let changesDelegate = ChangesDelegate(promise: promise)
//        DopamineChanges.shared.delegate = changesDelegate
//        DopamineVersion.current.update(visualizer: ["viewControllerDidAppear-DopamineKit_Example.ViewController-viewDidAppear:" : "somereward"])
//        DopamineChanges.shared.setSwizzling(true)
//        
//        controllerUnderTest.presentAnother()
//        
//        waitForExpectations(timeout: 3, handler: nil)
//        
//        
//    }
    
    
}

extension NSObject {
    func performVariableSelector(sel: Selector, argsCount: Int, args: [Any]) {
        if (argsCount == 0) {
            self.perform(sel)
        } else if (argsCount == 1) {
            self.perform(sel, with: args[0])
        } else {
            XCTAssert(false, "Too many args")
        }
    }
}
