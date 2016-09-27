//
//  SyncOverview.swift
//  Pods
//
//  Created by Akash Desai on 9/12/16.
//
//

import Foundation

class SyncOverview {
    
    var utc: Int64
    var timezoneOffset: Int64
    var totalSyncTime: Int64
    var cause: String
    var track: [String: AnyObject]
    var report: [String: AnyObject]
    var cartridges: [String: [String: AnyObject]]
    
    static let syncResponseKey = "syncResponse"
    /// Added to a SyncOverview sync object
    struct SyncResponse {
        let utc: Int64
        let roundTripTime: Int64
        let status: Int
        let error: String?
        
        private static let utcKey = "utc"
        private static let roundTripTimeKey = "roundTripTime"
        private static let statusKey = "status"
        private static let errorKey = "error"
        
        init(startTime:Int64, endTime:Int64 = Int64(1000*NSDate().timeIntervalSince1970), status: Int, error: String?) {
            self.utc = startTime
            self.roundTripTime = endTime - startTime
            self.status = status
            self.error = error
        }
        
        /// Returns a JSON compatible object
        ///
        func toJSONType() -> [String: AnyObject] {
            var jsonObject:[String: AnyObject] = [:]
            jsonObject[SyncResponse.utcKey] = NSNumber(longLong:roundTripTime)
            jsonObject[SyncResponse.roundTripTimeKey] = NSNumber(longLong:roundTripTime)
            jsonObject[SyncResponse.statusKey] = status
            jsonObject[SyncResponse.errorKey] = error
            
            return jsonObject
        }
    }
    
    init(utc: Int64=Int64(1000*NSDate().timeIntervalSince1970),
         timezoneOffset: Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT),
         totalSyncTime: Int64 = -1,
         cause: String,
         trackTriggers: [String: AnyObject] = [:],
         reportTriggers: [String: AnyObject] = [:],
         cartridgeTriggers: [String: [String: AnyObject]] = [:]
        ) {
        self.utc = utc
        self.timezoneOffset = timezoneOffset
        self.totalSyncTime = totalSyncTime
        self.cause = cause
        self.track = trackTriggers
        self.report = reportTriggers
        self.cartridges = cartridgeTriggers
    }
    
    /// Stores the sync overview into the local database
    ///
    func store() {
        let recordedSync = SQLSyncOverview(
            index:0,
            utc: utc,
            timezoneOffset: timezoneOffset,
            totalSyncTime: totalSyncTime,
            cause: cause,
            track: track,
            report: report,
            cartridges: Array(cartridges.values)
        )
        guard let _ = SQLSyncOverviewDataHelper.insert(recordedSync) else {
            DopamineKit.DebugLog("SQLiteDataStore error, couldnt store sync overview.")
            return
        }
    }
    
}
