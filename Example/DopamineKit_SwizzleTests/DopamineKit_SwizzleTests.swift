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
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
        DopamineVersion.current.update(visualizer: nil)
    }
    
    override func tearDown() {
        controllerUnderTest = nil
        super.tearDown()
    }
    
    func testSimpleMethodSwizzle() {
        
        //given
        XCTAssert(DopamineConfiguration.current.integrationMethod == "codeless")
        controllerUnderTest.testFunc()
        let beforeTestFuncStackSize = DopamineKit_SwizzleTests.counter
        controllerUnderTest.testFunc2()
        let beforeTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        
        // when
        SelectorReinforcement.registerSimpleMethod(classType: ViewController.self, selector: #selector(ViewController.testFunc), reinforcement: ["test": ["Hello!"]])
        SelectorReinforcement.registerSimpleMethod(classType: ViewController.self, selector: #selector(ViewController.testFunc2), reinforcement: ["test": ["Hello!"]])
        XCTAssert(SelectorReinforcement.isRegistered(classType: ViewController.self, selector: #selector(ViewController.testFunc)), "Selector was not registered")
        XCTAssert(SelectorReinforcement.isRegistered(classType: ViewController.self, selector: #selector(ViewController.testFunc2)), "Selector was not registered")
        
        // then
        controllerUnderTest.testFunc()
        let afterTestFuncStackSize = DopamineKit_SwizzleTests.counter
        controllerUnderTest.testFunc2()
        let afterTestFunc2StackSize = DopamineKit_SwizzleTests.counter
        
        XCTAssert(beforeTestFuncStackSize == afterTestFuncStackSize - 1, "Swizzle did not happen")
        XCTAssert(beforeTestFunc2StackSize == afterTestFunc2StackSize - 1, "Swizzle did not happen")
    }
    
}


