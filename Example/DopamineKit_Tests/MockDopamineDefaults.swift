//
//  MockDopamineDefaults.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import DopamineKit

class MockDopamineDefaults : DopamineDefaults {
    
    override open class var standard: MockDopamineDefaults {
        get {
            return MockDopamineDefaults(suiteName: "MockDopamineDefaults") ?? MockDopamineDefaults()
        }
    }
    
    override var wakeOnLoad: Bool {
        get {
            return false
        }
        set { }
    }
}
