//
//  NotificationReceiver.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

class NotificationReceiver : NSObject {
    
    var didReceiveNotification = false
    @objc func receiveNotification(notification: Notification) {
        didReceiveNotification = true
        print("Received notification <\(notification.name)>")
    }
    
}
