//
//  MockBKDatabase.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/13/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBKuserDefaults : BKUserDefaults {
    
    var data = [String: Any]()
    
    override func archive<T>(_ value: T?, forKey key: String) where T : NSCoding {
        data[key] = value
    }
    
    override func unarchive<T>(_ key: String) -> T? where T : NSCoding {
        return data[key] as? T
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        data[defaultName] = value
    }
    
    override func object(forKey defaultName: String) -> Any? {
        return data[defaultName]
    }
}
