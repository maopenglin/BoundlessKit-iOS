//
//  ContextGenerator.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation


class ContextGenerator : NSObject {
    
    static let queue = OperationQueue()
    
    static func getContext(completion:@escaping([String:Any]) -> Void) {
        queue.addOperation {
            completion([:])
        }
    }
    
    static func surroundingBluetooth(completion:@escaping([String:Any]) -> Void) {
        queue.addOperation {
            completion([:])
        }
    }
    
}
