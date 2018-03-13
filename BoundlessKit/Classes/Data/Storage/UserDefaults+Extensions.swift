//
//  UserDefaults+Extensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

protocol BKDatabase {
    func archive<T: NSCoding>(_ value: T?, forKey key: String)
    func unarchive<T: NSCoding>(_ key: String) -> T?
}

extension UserDefaults : BKDatabase {
    func archive<T: NSCoding>(_ value: T?, forKey key: String) {
        if let value = value {
            self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
        } else {
            self.set(nil, forKey: key)
        }
    }
    
    func unarchive<T: NSCoding>(_ key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else {
            return nil
        }
    }
}




