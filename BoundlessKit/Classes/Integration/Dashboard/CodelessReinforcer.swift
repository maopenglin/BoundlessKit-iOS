//
//  CodelessReinforcer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessReinforcer : NSObject {
    
    let actionID: String
    var reinforcements = [String: CodelessReinforcement]()
    
    init(forActionID actionID: String) {
        self.actionID = actionID
    }
    
//    @objc
//    func show(sender: AnyObject?, target: NSObject, selector: Selector) {
//
//    }
    @objc
    func receive(notification: Notification) {
        print("Got notification:\(notification.debugDescription)")
    }
    
}

struct CodelessReinforcement {
    let primitive: String
    let parameters: [String: Any]
    
    init?(from dict: [String: Any]) {
        if let primitive = dict["primitive"] as? String {
            self.primitive = primitive
            self.parameters = dict
        } else {
            return nil
        }
    }
    
    func show(senderInstance: AnyObject?, targetInstance: NSObject, completion: @escaping ()->Void = {}) {
        
    }
}

