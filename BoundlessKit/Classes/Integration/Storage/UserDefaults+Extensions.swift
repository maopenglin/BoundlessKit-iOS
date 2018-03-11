//
//  UserDefaults+Extensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal extension UserDefaults {
    
    func archive(_ value: Any, forKey key: String) {
        self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
    }
    
    func unarchive<T>(_ key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else {
            return nil
        }
    }

}




