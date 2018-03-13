//
//  MockBKDatabase.swift
//  BoundlessKit_Tests
//
//  Created by Akash Desai on 3/13/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import BoundlessKit

class MockBKDatabase : BKDatabase {
    
    var data = [String: Any]()
    
    func archive<T>(_ value: T?, forKey key: String) where T : NSCoding {
        data[key] = value
    }
    
    func unarchive<T>(_ key: String) -> T? where T : NSCoding {
        return data[key] as? T
    }
    
}
