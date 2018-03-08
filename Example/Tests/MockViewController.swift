//
//  MockViewController.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/7/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

@objc
class MockViewController : ViewController {
    
    internal(set) var counter = 0
    
    func counterIncrement() -> Int {
        counter += 1
        return counter
    }
    
    internal(set) var didReceiveNotification = false
    
    @objc
    func received(notification: Notification) {
        print("Received notification <\(notification.name)>")
        didReceiveNotification = true
    }
    
    @objc dynamic
    func printSomething() {
        print("Something")
    }
}
