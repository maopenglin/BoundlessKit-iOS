//
//  CodelessReinforcement.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessReinforcement : NSObject {
    
    let primitive: String
    
    init(_ primitive: String) {
        self.primitive = primitive
    }
    
//    @objc
//    func show(sender: AnyObject?, target: NSObject, selector: Selector) {
//
//    }
    @objc
    func receive(notification: Notification) {
        
    }
    
    static func convert(from dict: [String: Any]) -> CodelessReinforcement? {
        if let primitive = dict["primitive"] as? String {
            return CodelessReinforcement(primitive)
        } else {
            return nil
        }
    }
}

