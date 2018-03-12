//
//  BKRefreshCartridge.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridge : SynchronizedDictionary<String, SynchronizedArray<BoundlessDecision>> {
    
//    var desiredMinSizeUntilSync: Int32 = 2
    
    func removeDecision(for actionID: String, completion: ((BoundlessDecision?)->Void)?) {
        if self[actionID] == nil {
            self[actionID] = SynchronizedArray()
        }
        self[actionID]?.removeFirst(completion: completion)
    }
    
//    var needsSync: [String] {
//
//        var
//        for cartridge in values {
//
//        }
//        if count >= desiredSizeUntilSync {
//            return true
//        }
//
//        let timeNow = Int64(1000*NSDate().timeIntervalSince1970)
//        for reports in values {
//            guard let firstReportTimeInfo = reports.first?.recordValues["time"] as? [String: Any],
//                let timeTypes = firstReportTimeInfo["timeType"] as? [[String: Any]]
//                else {
//                    return false
//            }
//            for timeType in timeTypes {
//                if timeType["timeType"] as? String == "utc",
//                    let utc = timeType["value"] as? Int64
//                {
//                    return timeNow >= (utc + desiredTimeUntilSync)
//                }
//            }
//        }
//
//        return false
//    }
    
}



