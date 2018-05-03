//
//  MockBKRefreshCartridgeContainer.swift
//  BoundlessKit_Example
//
//  Created by Akash Desai on 5/2/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBKRefreshCartridgeContainer : BKRefreshCartridgeContainer {
    
    override init(_ dict: [String : BKRefreshCartridge]) {
        super.init(dict)
        self[MockBKRefreshCartridge.actionID] = MockBKRefreshCartridge.allRewards
    }
}

