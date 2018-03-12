//
//  BKTrackBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKTrackBatch : SynchronizedArray<BKRecord> {
    
    var desiredTimeUntilSync: Int64 = 86400000
    var desiredSizeUntilSync: Int32 = 10
    
    var needsSync: Bool {
        if count >= desiredSizeUntilSync {
            return true
        }
        
        guard let firstTrackTimeInfo = self.first?.recordValues["time"] as? [String: Any],
            let timeTypes = firstTrackTimeInfo["timeType"] as? [[String: Any]]
            else {
                return false
        }
        for timeType in timeTypes {
            if timeType["timeType"] as? String == "utc",
                let utc = timeType["value"] as? Int64
            {
                return Int64(1000*NSDate().timeIntervalSince1970) >= (utc + desiredTimeUntilSync)
            }
        }
        return false
    }
    
    func addAction(actionInfo: [String: Any]) {
        var record = BKRecord.init(recordType: "trackedActions", recordID: "")
        record.recordValues = actionInfo
        self.append(record)
    }
}
