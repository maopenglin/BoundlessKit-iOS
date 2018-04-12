//
//  MockBoundlessKit.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/13/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBoundlessKit : BoundlessKit {
    override init(apiClient: BoundlessAPIClient = MockBoundlessAPIClient()) {
        super.init(apiClient: apiClient)
    }
}
