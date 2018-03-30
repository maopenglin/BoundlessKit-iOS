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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    
    func testReceivingAllNotifications() {
        let notificationReceiver = NotificationReceiver()
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: nil, object: nil)
        
        InstanceSelectorNotificationCenter.default.post(name: NSNotification.Name.init("aNotification"), object: nil)
        XCTAssert(notificationReceiver.didReceiveNotification)
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver)
    }
    
//    func testPostNotification() {
//        let notificationReceiver = NotificationReceiver()
//        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: nil, object: nil)
//
//        InstanceSelectorNotificationCenter.post(instance: self, selector: #selector(testPostNotification), parameter: nil)
//        XCTAssert(notificationReceiver.didReceiveNotification)
//    }
    
//    func testPostNotificationFail() {
//        let notificationReceiver = NotificationReceiver()
//        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: nil, object: nil)
//
//        InstanceSelectorNotificationCenter.post(instance: self, selector: #selector(UIViewController.viewDidAppear(_:)), parameter: nil)
//        XCTAssert(!notificationReceiver.didReceiveNotification)
//    }
    
    func testNotificationForSelectorWithNoParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        
        XCTAssert(notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithBoolParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.viewDidAppear(_:))))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.viewDidAppear(true)
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.viewDidAppear(true)
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithObjectParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printA(string:))))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printA(string: "string")
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.printA(string: "string")
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testFailNotificationForSelectorWithMultipleParams() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printA(string:and:))))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printA(string: "string", and: "string2")
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
    }
    
    
    
    func testNotificationAddAndRemove() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationAddTwiceAndRemoveAndAdd() {
        let notificationReceiver = NotificationReceiver()
        let notificationReceiver2 = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        notificationReceiver2.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver2.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
    }
    
    func testNotificationAddMultipleAndRemoveExtra() {
        let notificationReceiver = NotificationReceiver()
        let notificationReceiver2 = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        notificationReceiver2.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver2.didReceiveNotification = false
        
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver2, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(!notificationReceiver2.didReceiveNotification)
        
        InstanceSelectorNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        InstanceSelectorNotificationCenter.default.removeObserver(notificationReceiver2, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(!notificationReceiver2.didReceiveNotification)
    }
    
}

