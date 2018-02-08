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
    static var counterAndClear: Int {
        get {
            defer { counter = 0 }
            return counter
        }
    }
    
    var controllerUnderTest: ViewController!
    override func setUp() {
        super.setUp()
        DopamineVersion.current.update(visualizer: nil)
        
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
//    func testSwizzleForViewControllerDidAppear() {
//        var controllerUnderTest: ViewController!
//        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
//
//        doubleSwizzle(
//            sut: controllerUnderTest,
//            selector1: #selector(ViewController.funcReturnVoidParams0),
//            args1: [],
//            selector2: #selector(ViewController.func2ReturnVoidParams0),
//            args2: [],
//            argsCount: 0
//        )
//    }
    
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
        let beforeTestFuncStackSize = DopamineKit_SwizzleTests.counterAndClear
        sut.performVariableSelector(sel: selector2, argsCount: argsCount, args: args2)
        let beforeTestFunc2StackSize = DopamineKit_SwizzleTests.counterAndClear
        
        // when
        let swizzle1 = DopamineChanges.shared.registerSimpleMethod(classType: type(of: sut), selector: selector1, reinforcement: ["reward": ["rewardForFirst": ["Hello!"]]])
        let swizzle2 = DopamineChanges.shared.registerSimpleMethod(classType: type(of: sut), selector: selector2, reinforcement: ["reward": ["rewardForSecond": ["Hello!"]]])
        XCTAssert(swizzle1, "Selector was not registered")
        XCTAssert(swizzle2, "Selector was not registered")
        
        
        // then
        sut.performVariableSelector(sel: selector1, argsCount: argsCount, args: args1)
        let afterTestFuncStackSize = DopamineKit_SwizzleTests.counterAndClear
        sut.performVariableSelector(sel: selector2, argsCount: argsCount, args: args2)
        let afterTestFunc2StackSize = DopamineKit_SwizzleTests.counterAndClear
        
        XCTAssert(afterTestFuncStackSize == beforeTestFuncStackSize + 1, "Swizzle did not happen")
        XCTAssert(afterTestFunc2StackSize == beforeTestFunc2StackSize + 1, "Swizzle did not happen")
    }
    
    func testViewControllerDidAppearReward() {
        // given
        let testCredentials = NSDictionary(contentsOfFile:Bundle(for: type(of: self)).path(forResource: "DopamineDemoProperties", ofType: "plist")!) as! [String:Any]
        DopamineKit.testCredentials = testCredentials
        class ChangesDelegate : NSObject, DopamineChangesDelegate {
            var didAttemptBlock: ((_ senderInstance: AnyObject?, _ targetInstance: AnyObject?, _ actionSelector: String, _ reinforcements: [String : Any]?) -> Void)? = nil
            var didRewardBlock: (() -> Void)? = nil
            
            func attemptedReinforcement(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String, reinforcements: [String : Any]?) {
                print("In attemptingReinforcement")
                didAttemptBlock?(senderInstance, targetInstance, actionSelector, reinforcements)
            }
            
            func reinforcing(actionID: String, with reinforcementDecision: String) {
                print("In showingReward")
                didRewardBlock?()
            }
        }
        
        let changesDelegate = ChangesDelegate()
        DopamineChanges.shared.delegate = changesDelegate
        let selector = #selector(ViewController.viewDidAppear(_:))
        let selectorReinforcement = SelectorReinforcement(targetClass: ViewController.self, selector: selector)
        let reinforcementsDict: [String : Any] = ["reward" : ["reward2":"somereward"]]
        DopamineVersion.current.update(visualizer: [selectorReinforcement.actionID : reinforcementsDict])
        let controllerUnderTest: ViewController! = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        
        
        
        // when
        let promise = expectation(description: "Reinforcement attempted")
        changesDelegate.didAttemptBlock = {(senderInstance: AnyObject?, targetInstance: AnyObject?, actionSelector: String, reinforcements: [String : Any]?) in
            guard targetInstance === controllerUnderTest,
                let reinforcements = reinforcements,
                NSDictionary(dictionary: reinforcementsDict).isEqual(to: reinforcements),
                actionSelector == NSStringFromSelector(selector) else {
                return
            }
            promise.fulfill()
        }
        controllerUnderTest.viewDidAppear(true)
        
        // then
        waitForExpectations(timeout: 5, handler: nil)
    }
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
