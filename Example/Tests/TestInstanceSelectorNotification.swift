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
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: nil, object: nil)
        
        BoundlessNotificationCenter.default.post(name: NSNotification.Name.init("aNotification"), object: nil)
        XCTAssert(notificationReceiver.didReceiveNotification)
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver)
    }
    
    func testGenericNotificationPass() {
        let notification = Notification.Name("testNotification")
        let notificationReceiver = NotificationReceiver()
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: notification, object: nil)

        BoundlessNotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
        XCTAssert(notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithNoParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        
        XCTAssert(notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithBoolParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.viewDidAppear(_:))))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.viewDidAppear(true)
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.viewDidAppear(true)
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithObjectParam() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printA(string:))))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printA(string: "string")
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.printA(string: "string")
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationForSelectorWithMultipleParams() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printA(string:and:))))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printA(string: "string", and: "string2")
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
    }
    
    
    
    func testNotificationAddAndRemove() {
        let notificationReceiver = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: nil, object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
    }
    
    func testNotificationAddTwiceAndRemoveAndAdd() {
        let notificationReceiver = NotificationReceiver()
        let notificationReceiver2 = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        notificationReceiver2.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver2.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
    }
    
    func testNotificationAddMultipleAndRemoveExtra() {
        let notificationReceiver = NotificationReceiver()
        let notificationReceiver2 = NotificationReceiver()
        let sut = MockViewController()
        let selectorInstanceActionID = "\(NSStringFromClass(MockViewController.self))-\(NSStringFromSelector(#selector(MockViewController.printSomething)))"
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        BoundlessNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        BoundlessNotificationCenter.default.addObserver(notificationReceiver2, selector: #selector(notificationReceiver2.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver.didReceiveNotification = false
        notificationReceiver2.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(notificationReceiver2.didReceiveNotification)
        notificationReceiver2.didReceiveNotification = false
        
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver2, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(!notificationReceiver.didReceiveNotification)
        XCTAssert(!notificationReceiver2.didReceiveNotification)
        
        BoundlessNotificationCenter.default.addObserver(notificationReceiver, selector: #selector(notificationReceiver.receiveNotification(notification:)), name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        BoundlessNotificationCenter.default.removeObserver(notificationReceiver2, name: Notification.Name(rawValue: selectorInstanceActionID), object: nil)
        sut.printSomething()
        
        XCTAssert(notificationReceiver.didReceiveNotification)
        XCTAssert(!notificationReceiver2.didReceiveNotification)
    }
    
}

