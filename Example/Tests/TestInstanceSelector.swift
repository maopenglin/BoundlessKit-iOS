//
//  TestInstanceSelector.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestInstanceSelector: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInstanceSelectorInit() {
        XCTAssert(nil != InstanceSelector.init(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))))
        XCTAssert(nil == InstanceSelector.init(UIResponder.self, #selector(UIViewController.viewDidAppear(_:))))
        
        XCTAssert(nil != InstanceSelector.init("UIViewController-viewDidAppear:"))
        XCTAssert(nil == InstanceSelector.init("UIViewController,viewDidAppear:"))
    }
    
}
