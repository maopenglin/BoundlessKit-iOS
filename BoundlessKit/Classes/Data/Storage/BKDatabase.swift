//
//  BKDatabase.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

protocol BKData : NSCoding {}
protocol BKDatabase {
    func archive<T: BKData>(_ value: T?, forKey key: String)
    func unarchive<T: BKData>(_ key: String) -> T?
}

class BKUserDefaults : UserDefaults, BKDatabase {
    
    override class var standard: BKUserDefaults {
        get {
            return BKUserDefaults.init(suiteName: "boundless.kit")!
        }
    }
    
    func removePersistentDomain() {
        removePersistentDomain(forName: "boundless.kit")
    }
    
    override init?(suiteName suitename: String?) {
        BKTrackBatch.registerWithNSKeyed
        BKReportBatch.registerWithNSKeyed
        BKRefreshCartridge.registerWithNSKeyed
        BKRefreshCartridgeContainer.registerWithNSKeyed
        super.init(suiteName: suitename)
    }
    
    func archive<T: BKData>(_ value: T?, forKey key: String) {
        if let value = value {
            self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
        } else {
            self.set(nil, forKey: key)
        }
    }
    
    func unarchive<T: BKData>(_ key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else {
            return nil
        }
    }
    
    open var initialBootDate: Date? {
        get {
            let date = object(forKey: "initialBootDate") as? Date
            if date == nil {
                set(Date(), forKey: "initialBootDate")
            }
            return date
        }
    }
    
}




