//
//  MockUserDefaults.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

class MockUserDefaults : UserDefaults {
    
    typealias MockDefaults = Dictionary<String, Any?>
    var data : MockDefaults
    
    override init?(suiteName suitename: String?) {
        data = MockDefaults()
        super.init(suiteName: "UnitTest")
    }
    
    // NOP
    
    override func synchronize() -> Bool {
        return true
    }
    
    // Accessors
    
    override func object(forKey defaultName: String) -> Any? {
        return data[defaultName] ?? nil
    }
    
    override func value(forKey key: String) -> Any? {
        return data[key] ?? nil
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return data[defaultName] as? Bool ?? false
    }
    
    // Mutators
    
    override func set(_ value: Any?, forKey defaultName: String) {
        data[defaultName] = value
    }
    
    override func set(_ value: Bool, forKey defaultName: String) {
        data[defaultName] = value as Bool
    }
}

extension UserDefaults {
    
    @objc class func transientDefaults() -> MockUserDefaults {
        return MockUserDefaults(suiteName: "UnitTest")!
    }
    
}
