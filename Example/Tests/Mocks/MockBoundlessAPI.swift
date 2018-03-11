//
//  MockBoundlessAPI.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBoundlessAPI : BoundlessAPI {
    
    override func send(call type: HTTPClient.CallType, with payload: [String : Any], timeout: TimeInterval, completion: @escaping ([String : Any]) -> Void) {
        print("Sending call type <\(type.path)> with payload <\(payload)>")
        completion([:])
    }
}
