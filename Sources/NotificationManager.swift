////
////  NotificationManager.swift
////
////  Created by Akash Desai on 4/28/17.
////  Copyright © 2017 UseDopamine. All rights reserved.
////
//import Foundation
//import UIKit
//import UserNotifications
//
//@objc
//@available(iOS 10.0, *)
//public class NotificationManager: NSObject {
//    
//    private static var Instance = NotificationManager()
//    
//    public static var shared: NotificationManager {
//        get {
//            return Instance
//        }
//    }
//    
//    fileprivate var authorizationOptions: UNAuthorizationOptions = [.sound, .alert, .badge]
//    public var token: String? {
//        get {
//            return UserDefaults.standard.string(forKey: #keyPath(token))
//        }
//        set {
//            if let newValue = newValue {
//                // TO-DO: send token to server
////                DopamineTriggersAPI.registerUser(newValue, pushEnabled: didGrantPermission) {_ in}
//                DopamineKit.debugLog("token: \(newValue) didGrantPermission:\(didGrantPermission)")
//            }
//            UserDefaults.standard.set(newValue, forKey: #keyPath(token))
//        }
//    }
//    public func setTokenNSData(data: NSData) {
//        token = (data as Data).hexEncodedString()
//    }
//    @objc fileprivate var cachedPermissionGranted: Bool {
//        get {
//            return UserDefaults.standard.bool(forKey: #keyPath(cachedPermissionGranted))
//        }
//        set {
//            if cachedPermissionGranted != newValue,
//                let token = token {
//                // TO-DO: update push status
////                DopamineTriggersAPI.updateUser(token, pushEnabled: newValue, completion: {_ in})
//                DopamineKit.debugLog("token: \(token) pushEnabled:\(newValue)")
//            }
//            UserDefaults.standard.set(newValue, forKey: #keyPath(cachedPermissionGranted))
//        }
//    }
//    public var didGrantPermission: Bool {
//        get {
//            let permissionGranted = UIApplication.shared.currentUserNotificationSettings!.types != []
//            cachedPermissionGranted = permissionGranted
//            return permissionGranted
//        }
//    }
//    @objc fileprivate var needsToOpenSettingsApp: Bool {
//        get {
//            return UserDefaults.standard.bool(forKey: #keyPath(needsToOpenSettingsApp))
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: #keyPath(needsToOpenSettingsApp))
//        }
//    }
//    
//    fileprivate override init() {
//        super.init()
//        UNUserNotificationCenter.current().delegate = self
//    }
//    
//    public func requestAuthorization(from viewController: UIViewController) {
//        guard !didGrantPermission else {
//            DopamineKit.debugLog("Notifications permission already granted using token:\(String(describing: token)).")
//            return
//        }
//        DopamineKit.debugLog("Asking for notifications permission...")
//        
//        let alert = UIAlertController(title: "Receive Notifications?", message: "Notifications will only be sent for important alerts", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: {_ in}))
//        alert.addAction(UIAlertAction(title: "Grant Access", style: .default, handler: {_ in
//            self.presentAuthorizationToggle()
//        }))
//        viewController.present(alert, animated: true)
//        
//    }
//    
//    fileprivate func presentAuthorizationToggle() {
//        if needsToOpenSettingsApp,
//            let settingsURL = URL(string:UIApplicationOpenSettingsURLString) {
//            UIApplication.shared.open(settingsURL)
//        } else {
//            presentSystemAuthorization()
//        }
//    }
//    
//    fileprivate func presentSystemAuthorization() {
//        UNUserNotificationCenter.current().requestAuthorization(options: self.authorizationOptions) { (granted, error) in
//            UIApplication.shared.registerForRemoteNotifications()
//            // Enable or disable features based on authorization.
//            DopamineKit.debugLog("Notification Permission granted:\(granted) error:\(String(describing: error))")
//            if granted {
//                DopamineKit.debugLog(" ✅ user granted notification permission")
//            } else {
//                DopamineKit.debugLog(" ❎ user denied notification permission")
//            }
//            self.needsToOpenSettingsApp = true
//        }
//    }
//}
//
//@available(iOS 10.0, *)
//extension NotificationManager : UNUserNotificationCenterDelegate {
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        DopamineKit.debugLog(String(describing: notification))
//        print("User Info = ",notification.request.content.userInfo)
//        completionHandler([.alert, .badge, .sound])
//    }
//    
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        DopamineKit.debugLog(String(describing: response))
//        print("User Info = ",response.notification.request.content.userInfo)
//        completionHandler()
//    }
//}
//
//extension Data {
//    func hexEncodedString() -> String {
//        return map { String(format: "%02hhx", $0) }.joined()
//    }
//}
//
