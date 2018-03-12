//
//  BKReportBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKReportBatch : SynchronizedDictionary<String, SynchronizedArray<BKRecord>> {
    
    var desiredMaxTimeUntilSync: Int64 = 86400000
    var desiredMaxSizeUntilSync: Int32 = 10
    
    var needsSync: Bool {
        if count >= desiredMaxSizeUntilSync {
            return true
        }
        
        let timeNow = Int64(1000*NSDate().timeIntervalSince1970)
        for reports in values {
            guard let firstReportTimeInfo = reports.first?.recordValues["time"] as? [String: Any],
                let timeTypes = firstReportTimeInfo["timeType"] as? [[String: Any]]
                else {
                    return false
            }
            for timeType in timeTypes {
                if timeType["timeType"] as? String == "utc",
                    let utc = timeType["value"] as? Int64
                {
                    return timeNow >= (utc + desiredMaxTimeUntilSync)
                }
            }
        }
        
        return false
    }
    
    func addReport(actionID: String, reportInfo: [String: Any]) {
        var record = BKRecord.init(recordType: "reportedActions", recordID: "")
        record.recordValues = reportInfo
        if self[actionID] == nil {
            self[actionID] = SynchronizedArray()
        }
        self[actionID]?.append(record)
    }
    
}


