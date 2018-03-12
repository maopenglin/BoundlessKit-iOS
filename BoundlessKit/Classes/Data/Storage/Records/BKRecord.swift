//
//  BKRecord.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

typealias BKRecordData = Data
internal struct BKRecord {
    
    let recordType: String
    let recordID: String
    var recordValues: [String: Any]
    
    init(type: String, id: String, values: [String: Any] = [:]) {
        self.recordType = recordType
        self.recordID = recordID
        self.recordValues = recordValues
    }
    
    subscript(key: String) -> Any? {
        get {
            return recordValues[key]
        }
        set {
            recordValues[key] = newValue
        }
    }
}

extension BKRecord {
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(recordType, forKey: "recordType")
        archiver.encode(recordID, forKey: "recordID")
        archiver.encode(recordValues, forKey: "recordValues")
        archiver.finishEncoding()
        return data as Data
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let recordType = unarchiver.decodeObject(forKey: "recordType") as? String else { return nil }
        guard let recordID = unarchiver.decodeObject(forKey: "recordID") as? String else { return nil }
        guard let recordValues = unarchiver.decodeObject(forKey: "recordValues") as? [String: Any] else { return nil }
        self.init(recordType: recordType, recordID: recordID)
        self.recordValues = recordValues
    }
}
