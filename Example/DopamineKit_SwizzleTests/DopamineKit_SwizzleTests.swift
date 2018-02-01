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
    
    var controllerUnderTest: ViewController!
    
    override func setUp() {
        super.setUp()
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController!
    }
    
    override func tearDown() {
        controllerUnderTest = nil
        super.tearDown()
    }
    
    func testSimpleMethodSwizzle() {
        
        //given
        XCTAssert(DopamineConfiguration.current.integrationMethod == "codeless")
        
        
        // when
        SelectorReinforcement.registerSimpleMethod(classType: ViewController.self, selector: #selector(ViewController.action1Performed(button:)), reinforcement: ["test": ["Hello!"]])
        
        // then
//        controllerUnderTest.action1Performed(button: UIButton())
        XCTAssert(SelectorReinforcement.isRegistered(classType: ViewController.self, selector: #selector(ViewController.action1Performed(button:))), "Selector was not registered")
        
    }
    
}


