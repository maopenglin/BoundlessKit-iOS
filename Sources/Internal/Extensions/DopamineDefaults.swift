//
//  DopamineDefaults.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/6/18.
//

import Foundation

open class DopamineDefaultsSingleton : NSObject, NSCoding {
    override init() { super.init() }
    open func encode(with aCoder: NSCoder) {}
    public required init?(coder aDecoder: NSCoder) {}
    
    static var defaultsKey: String {
        return NSStringFromClass(self)
    }
}

open class DopamineDefaults : UserDefaults {
    
    fileprivate static let suiteName = "com.usedopamine.dopaminekit"
    fileprivate static var codelessIntegrationSavedStateKey = "codelessIntegrationSavedState"
    fileprivate static var initialBootDateKey = "initialBootDate"
    
    internal static var current: DopamineDefaults = DopamineDefaults.standard {
        didSet {
            DopeLog.print("Set new defaults")
        }
    }
    override open class var standard: DopamineDefaults {
        get {
            return DopamineDefaults(suiteName: DopamineDefaults.suiteName) ?? DopamineDefaults()
        }
    }
    
    open var codelessIntegrationSavedState: String? {
        get {
            return string(forKey: DopamineDefaults.codelessIntegrationSavedStateKey)
        }
        set {
            set(newValue, forKey: DopamineDefaults.codelessIntegrationSavedStateKey)
        }
    }

    open var initialBootDate: Date? {
        get {
            let date = object(forKey: DopamineDefaults.initialBootDateKey) as? Date
            defer { if date == nil { set(Date(), forKey: DopamineDefaults.initialBootDateKey) } }
            return date
        }
    }
    
    open func archive<T:DopamineDefaultsSingleton>(_ value: T?) {
        archive(value, forKey: T.defaultsKey)
    }
    
    open func archive(_ value: NSCoding?, forKey key: String) {
        if let value = value {
            self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
        } else {
            self.set(value, forKey: key)
        }
    }
    
    open func unarchive<T:DopamineDefaultsSingleton>() -> T? {
        return unarchive(key: T.defaultsKey)
    }
    
    open func unarchive<T>(key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else { return nil }
    }
    
    
    open func clear() {
        DopeLog.print("In clear")
        removePersistentDomain(forName: DopamineDefaults.suiteName)
        synchronize()
        DopeLog.print("Value for somethong:\(initialBootDate)")
    }

}

