//
//  BoundlessAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BoundlessAction : NSObject {
    let name: String
    init(_ name: String) {
        self.name = name
    }
    
    static func addContext(to action: BoundlessAction) {
        let _ = {[weak action] in
            
        }()
    }
}
