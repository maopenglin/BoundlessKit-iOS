//
//  BoundlessAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BoundlessAction : NSObject {
    let name: String
    var metadata: [String: Any]
    
    init(_ name: String, _ metadata: [String:Any] = [:]) {
        self.name = name
        self.metadata = metadata
    }
    
    static func addContext(to action: BoundlessAction) {
        ContextGenerator.surroundingBluetooth { (bluetoothInfo) in
            action.metadata["bluetooth"] = bluetoothInfo
        }
    }
}
