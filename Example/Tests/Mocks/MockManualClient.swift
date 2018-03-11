//
//  MockBoundlessKitClient.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBoundlessKitClient : BoundlessKitClient {
    var onPublishTrack: (() -> Void)?
    
    override func kitPublish(actionInfo: [String : Any]) {
        super.kitPublish(actionInfo: actionInfo)
        print("Published actions in mock:<\(trackedActions.count)>")
        onPublishTrack?()
    }
}

