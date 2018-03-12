//
//  BKDatabase.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKDatabase : NSObject {
    
    typealias RecordsStorage = [String: [BKRecordData]]
    
    let name: String
    let storage: UserDefaults
    
    init(_ name: String) {
        self.name = name
        self.storage = UserDefaults(suiteName: name) ?? UserDefaults.standard
    }
    
    func save(_ record: BKRecord) {
        var records = RecordsStorage()
        if let savedRecords: RecordsStorage = storage.unarchive(record.recordType) {
            records = savedRecords
        }
        if records[record.recordID] == nil { records[record.recordID] = [] }
        
        records[record.recordID]?.append(record.encode())
        storage.archive(records, forKey: record.recordType)
    }
    
    func fetch(recordType: String, recordID: String?, handler: @escaping ([BKRecord])->Void) {
        guard let savedRecords: RecordsStorage = storage.unarchive(recordType) else {
            handler([])
            return
        }
        guard let recordID = recordID else {
            handler(savedRecords.values.flatMap{$0}.flatMap({ data -> BKRecord? in
                return BKRecord.init(data: data)
            }))
            return
        }
        handler(savedRecords[recordID]?.flatMap({ data -> BKRecord? in
            return BKRecord.init(data: data)
        }) ?? [])
    }
    
}
