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
    override init(apiClient: BoundlessAPIClient = MockBoundlessAPIClient(), database: BKDatabase = MockBKDatabase()) {
        super.init(apiClient: apiClient, database: database)
    }
}

extension BoundlessProperties {
    static var fromTestFile: BoundlessProperties? {
        if let propertiesFile = Bundle(for: MockBoundlessKit.self).path(forResource: "BoundlessTestProperties", ofType: "plist"),
            let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as? [String: Any] {
            return BoundlessProperties.convert(from: propertiesDictionary)
        } else {
            return nil
        }
    }
}
