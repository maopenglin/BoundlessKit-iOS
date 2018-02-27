//
//  DopamineDefaults.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/6/18.
//

import Foundation


//protocol DopamineDefaultsProtocol {
//    var wakeOnLoad: Bool {get set}
//    var initialBootDate: Date? {get}
//    func set(_ value: Any?, forKey defaultName: String)
//    func archive<T:DopamineDefaultsSingleton>(_ value: T?)
//    func object(forKey defaultName: String) -> Any?
//    func unarchive<T:DopamineDefaultsSingleton>() -> T?
//    func clear()
//}

open class DopamineDefaultsSingleton : NSObject, NSCoding {
    override init() { super.init() }
    open func encode(with aCoder: NSCoder) {}
    public required init?(coder aDecoder: NSCoder) {}
    
    static var defaultsKey: String {
        return NSStringFromClass(self)
    }
}

open class DopamineDefaults : UserDefaults/*, DopamineDefaultsProtocol*/ {
    
    fileprivate static let suiteName = "com.usedopamine.dopaminekit"
    fileprivate static var wakeOnLoadDisabled = "wakeOnLoadDisabled"
    
    internal static var current: DopamineDefaults/*DopamineDefaultsProtocol*/ = DopamineDefaults.standard
    override open class var standard: DopamineDefaults {
        get {
            return DopamineDefaults(suiteName: DopamineDefaults.suiteName) ?? DopamineDefaults()
        }
    }

    @objc
    open var wakeOnLoad: Bool {
        get {
            return !bool(forKey: DopamineDefaults.wakeOnLoadDisabled)
        }
        set {
            set(!newValue, forKey: DopamineDefaults.wakeOnLoadDisabled)
        }
    }

    open var initialBootDate: Date? {
        get {
            let defaultsKey = "initialBootDate"
            let date = object(forKey: defaultsKey) as? Date
            defer { if date == nil { set(Date(), forKey: defaultsKey) } }
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
        removePersistentDomain(forName: DopamineDefaults.suiteName)
        synchronize()
    }

}

