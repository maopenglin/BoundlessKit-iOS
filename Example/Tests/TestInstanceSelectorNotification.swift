//
//  TestInstanceSelectorNotification.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BoundlessKit

class TestInstanceSelectorNotification: XCTestCase {
    
    var didReceiveNotification = false
    @objc func receiveNotification(notification: Notification) {
        didReceiveNotification = true
        print("Received notification <\(notification.name)>")
    }
    
    var didReceiveNotification2 = false
    @objc func receiveNotification(notification2: Notification) {
        didReceiveNotification2 = true
        print("Received notification2 <\(notification2.name)>")
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        didReceiveNotification = false
        didReceiveNotification2 = false
        super.tearDown()
    }
    
    
    func testReceivingAllNotifications() {
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: nil, object: nil)
        
        InstanceSelectorNotificationCenter.default.post(name: NSNotification.Name.init("aNotification"), object: nil)
        XCTAssert(self.didReceiveNotification)
    }
    
    func testPostNotification() {
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: nil, object: nil)
        
        InstanceSelectorNotificationCenter.post(instance: self, selector: #selector(testPostNotification), parameter: nil)
        XCTAssert(self.didReceiveNotification)
    }
    
    func testPostNotificationFail() {
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: nil, object: nil)
        
        InstanceSelectorNotificationCenter.post(instance: self, selector: #selector(UIViewController.viewDidAppear(_:)), parameter: nil)
        XCTAssert(!self.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithNoParam() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printSomething))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(self.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithBoolParam() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.viewDidAppear(_:)))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.viewDidAppear(true)
        
        XCTAssert(self.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithObjectParam() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printA(string:)))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printA(string: "string")
        
        XCTAssert(self.didReceiveNotification)
    }
    
    func testFailNotificationForSelectorWithMultipleParams() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printA(string:and:)))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printA(string: "string", and: "string2")
        
        XCTAssert(!self.didReceiveNotification)
    }
    
    
    
    func testNotificationAddAndRemove() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printSomething))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(self.didReceiveNotification)
        self.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(self, name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(!self.didReceiveNotification)
    }
    
    func testNotificationAddAndRemoveAndAdd() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printSomething))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(self.didReceiveNotification)
        self.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(self, name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(!self.didReceiveNotification)
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(self.didReceiveNotification)
    }
    
    func testNotificationForMultipleObservers() {
        let selectorInstance = InstanceSelector(MockViewController.self, #selector(MockViewController.printSomething))!
        let sut = MockViewController()
        
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification:)), name: selectorInstance.notification, object: nil)
        InstanceSelectorNotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notification2:)), name: selectorInstance.notification, object: nil)
        sut.printSomething()
        
        XCTAssert(self.didReceiveNotification)
        XCTAssert(self.didReceiveNotification2)
    }
    
}
