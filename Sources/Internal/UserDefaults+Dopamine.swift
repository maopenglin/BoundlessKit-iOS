//
//  UserDefaults+Dopamine.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/29/17.
//

import Foundation

open class UserDefaultsSingleton : NSObject, NSCoding {
    override init() { super.init() }
    open func encode(with aCoder: NSCoder) {}
    public required init?(coder aDecoder: NSCoder) {}
    
    static var defaultsKey: String {
        return NSStringFromClass(self)
    }
}

internal extension UserDefaults {
    
    static var initialBootDate: Date? {
        get {
            let defaultsKey = "initialBootDate"
            let date = UserDefaults.dopamine.object(forKey: defaultsKey) as? Date
            defer { if date == nil { UserDefaults.dopamine.set(Date(), forKey: defaultsKey) } }
            return date
        }
    }
    
    static var dopamine: UserDefaults {
        get {
            return UserDefaults(suiteName: "com.usedopamine.dopaminekit") ?? UserDefaults.standard
        }
    }
    
    func archive(_ value: NSCoding?, forKey key: String) {
        if let value = value {
            self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
        } else {
            self.set(value, forKey: key)
        }
    }
    
    func archive<T:UserDefaultsSingleton>(_ value: T?) {
        archive(value, forKey: T.defaultsKey)
    }
    
    func unarchive<T>(key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else { return nil }
    }
    
    func unarchive<T:UserDefaultsSingleton>() -> T? {
        return unarchive(key: T.defaultsKey)
    }
    
}
