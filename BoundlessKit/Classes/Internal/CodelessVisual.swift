//
//  CodelessVisual.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessVisual : NSObject {
    
    let primitive: String
    
    init(_ primitive: String) {
        self.primitive = primitive
    }
    
    func register(for notification: Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.show(notification:)), name: notification, object: nil)
        print("Registered for:\(notification.rawValue)")
    }
    
    @objc
    func show(notification: NSNotification) {
        print("Got reinforcement notification: \(notification.name.rawValue)")
    }
    
    static func convert(from dict: [String: Any]) -> CodelessVisual? {
        if let primitive = dict["primitive"] as? String {
            return CodelessVisual(primitive)
        } else {
            return nil
        }
    }
}

