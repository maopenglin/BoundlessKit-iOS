//
//  SyncOverview.swift
//  Pods
//
//  Created by Akash Desai on 9/19/16.
//
//

import Foundation
internal class SyncOverview : NSObject, NSCoding {
    
    static let utcKey = "utc"
    static let timezoneOffsetKey = "timezoneOffset"
    static let totalSyncTimeKey = "totalSyncTime"
    static let causeKey = "cause"
    static let trackKey = "track"
    static let reportKey = "report"
    static let cartridgesKey = "cartridges"
    static let syncResponseKey = "syncResponse"
    static let roundTripTimeKey = "roundTripTime"
    static let statusKey = "status"
    static let errorKey = "error"
    
    var utc: Int64
    var timezoneOffset: Int64
    var totalSyncTime: Int64
    var cause: String
    var trackTriggers: [String: Any]
    var reportTriggers: [String: Any]
    var cartridgesTriggers: [String: [String: Any]]
    
    /// Use this object to record the performance of a synchronization
    ///
    /// - parameters:
    ///     - cause: The reason a sync is being performed
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    init(cause: String, trackTriggers: [String: Any], reportTriggers: [String: Any], cartridgeTriggers: [String: [String: Any]]) {
        self.utc = Int64( 1000*Date().timeIntervalSince1970 )
        self.timezoneOffset = Int64( 1000*NSTimeZone.default.secondsFromGMT() )
        self.totalSyncTime = -1
        self.cause = cause
        self.trackTriggers = trackTriggers
        self.reportTriggers = reportTriggers
        self.cartridgesTriggers = cartridgeTriggers
    }
    
    /// Decodes a saved overview from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.utc = aDecoder.decodeInt64(forKey: SyncOverview.utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: SyncOverview.timezoneOffsetKey)
        self.totalSyncTime = aDecoder.decodeInt64(forKey: SyncOverview.totalSyncTimeKey)
        self.cause = aDecoder.decodeObject(forKey: SyncOverview.causeKey) as! String
        self.trackTriggers = aDecoder.decodeObject(forKey: SyncOverview.trackKey) as! [String: Any]
        self.reportTriggers = aDecoder.decodeObject(forKey: SyncOverview.reportKey) as! [String: Any]
        self.cartridgesTriggers = aDecoder.decodeObject(forKey: SyncOverview.cartridgesKey) as! [String: [String: Any]]
    }
    
    /// Encodes an overview and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(utc, forKey: SyncOverview.utcKey)
        aCoder.encode(timezoneOffset, forKey: SyncOverview.timezoneOffsetKey)
        aCoder.encode(totalSyncTime, forKey: SyncOverview.totalSyncTimeKey)
        aCoder.encode(cause, forKey: SyncOverview.causeKey)
        aCoder.encode(trackTriggers, forKey: SyncOverview.trackKey)
        aCoder.encode(reportTriggers, forKey: SyncOverview.reportKey)
        aCoder.encode(cartridgesTriggers, forKey: SyncOverview.cartridgesKey)
    }
    
    /// This function converts a BoundlessAction to a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject[SyncOverview.utcKey] = NSNumber(value: utc)
        jsonObject[SyncOverview.timezoneOffsetKey] = NSNumber(value: timezoneOffset)
        jsonObject[SyncOverview.totalSyncTimeKey] = NSNumber(value: totalSyncTime)
        jsonObject[SyncOverview.causeKey] = cause
        jsonObject[SyncOverview.trackKey] = trackTriggers
        jsonObject[SyncOverview.reportKey] = reportTriggers
        var cartridges: [[String: Any]] = []
        for (_, value) in cartridgesTriggers {
            cartridges.append(value)
        }
        jsonObject[SyncOverview.cartridgesKey] = cartridges
        return jsonObject
    }
    
}
